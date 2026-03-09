package game
import "core:net"
// import "core:sync"
import "core:thread"
import "core:log"
import gk "game_kernel"
import "core:encoding/cbor"  // Compact binary JSON-like format
NetworkMessage :: struct {
    packet_version:u8,
    frame:int,
    message_type:MessageType,
    // game_check_sum:u32, // todo check me
}

MessageType :: union #no_nil {
    ConnectToOther,
    SendInput,

}
ConnectToOther :: struct {
    character:u8,
}

SendInput :: struct {
    input:gk.Input,
}
MAX_NETWORK_WINDOW :: MAX_ROLLBACK_WINDOW * 2 // we should figure this out
NetworkMannager :: struct {
    address:net.Address,
    port:int,
    socket:  net.UDP_Socket,
   	thread: ^thread.Thread,
    message_queue:[MAX_NETWORK_WINDOW]NetworkMessage,
    p1_input_mannager:InputMannager,
    p2_input_mannager:InputMannager,
    reader_pos:int,
    writer_pos:int,
    other_player_connected:bool,
    should_run:bool,
}

LobbyCreateError :: enum {
	AddressErr,
	SocketBindErr,
}

make_network_mannager :: proc(port:int) -> (Maybe(NetworkMannager),LobbyCreateError) {
    addr,ok := net.parse_ip4_address("127.0.0.1")
    if ok == false  {
    	log.error("invalida address")
        return nil,LobbyCreateError.AddressErr
    }
    udp_socket,udp_err := net.make_bound_udp_socket(addr,port)
    net.set_blocking(udp_socket,true)
    if udp_err != nil {
    	log.error("failed to bind to socket")
    	return nil,LobbyCreateError.SocketBindErr
    }
    log.debug(udp_socket)
    mannager := NetworkMannager {
    	socket = udp_socket,
    	address = addr,
     	port = port,
     	message_queue = {},
      	reader_pos = 0,
      	writer_pos = 0,
        other_player_connected = false,
        thread = nil,
    }
    //todo add logger to context

    return mannager,nil
    // tcp_socket,tcp_err := net.dial_tcp_from_address_and_port(addr,1234)
}
network_mannager_start_listening :: proc(mannager:^NetworkMannager) {
    mannager.should_run=true
 	thread := thread.create_and_start_with_poly_data(mannager,recv_input_network)
    mannager.thread = thread
}

destory_lobby :: proc(mannager:^NetworkMannager) {
    log.debug("cleaning")
	// we are using termincate here bcause we have an infinite loop
	if mannager.thread != nil {
	    local_endpoint,ok := net.parse_endpoint("127.0.0.1")
		if ok == false {
		    thread.terminate(mannager.thread,0)
			return
		}
		buffer := [256]u8{}
	    net.send_udp(mannager.socket,buffer[:],local_endpoint)
	    mannager.should_run = false
    	thread.join(mannager.thread)
    	thread.destroy(mannager.thread)
	}
}

recv_input_network :: proc(mannager:^NetworkMannager) {
	context.logger = g_context.logger
	// make this not fixed
    log.debug("started listening for messages")
    net.set_blocking(mannager.socket,true)
    for mannager.should_run {
	    buffer := [size_of(NetworkMessage)]u8{}
	    net.recv_udp(mannager.socket,buffer[:])
		// log.debug(buffer)
	    msg,err := decode_message(buffer[:])
	    if err != nil {
	   		continue // love the continue here
	    }
	    mannager.message_queue[mannager.writer_pos] = msg
	    //we dont need this to be attomic because its one producer
		proposed_pos := mannager.writer_pos+1 %% len(mannager.message_queue)
		if proposed_pos == mannager.reader_pos {
			assert(false,"we arnt consuming messages fast enough")
		}
	    mannager.writer_pos = proposed_pos
		free_all(context.temp_allocator)
    }
}

poll_remote_input :: proc(mannager:^NetworkMannager) -> Maybe(NetworkMessage) {
    if mannager.reader_pos+1 > mannager.writer_pos {
        return nil // todo reutrn an error here
    }
    value := mannager.message_queue[mannager.reader_pos]
    mannager.reader_pos += 1
    return value
}


EncodeErr :: union {
    cbor.Marshal_Error,
}

//we wrap here so we can add a custom impl if cbor is slow
encode_message :: proc(msg:NetworkMessage) -> ([]byte,EncodeErr) {
    data,err := cbor.marshal_into_bytes(msg, cbor.ENCODE_FULLY_DETERMINISTIC)
    return data,err
}



decode_message :: proc(data:[]byte) -> (NetworkMessage,cbor.Unmarshal_Error) {
    msg:NetworkMessage = {}
    err := cbor.unmarshal_from_bytes(data,&msg)
    return msg,err
}
