package game
import "core:net"
import "base:runtime"
// import "core:sync"
import "core:thread"
import "core:log"
import gk "game_kernel"
import "core:encoding/cbor"
import "core:container/queue"

MESSAGE_VERSION :: 0
NetworkMessage :: struct {
    packet_version:u8,
    frame:int,
    message_type:MessageType,
    // game_check_sum:u32, // todo check me
}

MessageType :: union #no_nil {
    ConnectToOther,
    SendInput,
    AckInput,
    EndSession,
}
ConnectToOther :: struct {
    character:u8,
}

SendInput :: struct {
    input:gk.Input,
}
AckInput :: struct {} // todo see what we need to send with the acc

EndSession :: struct {}

MAX_NETWORK_WINDOW :: MAX_ROLLBACK_WINDOW * 2 // we should figure this out
NetworkMannager :: struct {
    address:net.Address,
    port:int,
    socket:  net.UDP_Socket,
   	thread: ^thread.Thread,
    //todo remove me we want to decouple this
    // this is LIKELY A MEMORY LEAK
    message_queue:queue.Queue(InputWithFrame),
    endpoint:net.Endpoint,
    other_player_connected:bool,
    should_run:bool,
}

LobbyCreateError :: enum {
	InvalidBindAddr,
	InvalidAddress,
	SocketBindErr,
}

make_network_mannager :: proc(port:int,other_ip:string,other_port:int,allocator:runtime.Allocator) -> (Maybe(NetworkMannager),LobbyCreateError) {
    addr,ok := net.parse_ip4_address("0.0.0.0")
    if ok == false  {
    	log.error("invalida bind address")
        return nil,LobbyCreateError.InvalidBindAddr
    }
    other_addr, other_addr_ok := net.parse_ip4_address(other_ip)
    if other_addr_ok == false {
       	log.error("invalida address")
        return nil,LobbyCreateError.InvalidAddress
    }
    udp_socket,udp_err := net.make_bound_udp_socket(addr,port)
    net.set_blocking(udp_socket,true)
    if udp_err != nil {
    	log.error("failed to bind to socket")
    	return nil,LobbyCreateError.SocketBindErr
    }
    log.debug(udp_socket)
    message_queue: queue.Queue(InputWithFrame) = {}
    queue.init(&message_queue,allocator=allocator)
    mannager := NetworkMannager {
    	socket = udp_socket,
    	address = addr,
     	port = port,
     	message_queue = message_queue,
        endpoint=net.Endpoint {
            address = other_addr,
            port = other_port,
        },
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
		send_messsage(&g.network_mannager,NetworkMessage {
            packet_version = 0,
            frame = g.frame,
            message_type = EndSession{},
        })
	    mannager.should_run = false
	    thread.terminate(mannager.thread,0)
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
	    buffer := [150]u8{}
	    net.recv_udp(mannager.socket,buffer[:])

		// remove me we want to make our own queue
	    msg:NetworkMessage = {}
		err := cbor.unmarshal_from_bytes(buffer[:],&msg)
		switch state in msg.message_type {
		case ConnectToOther:
            log.debug("connecting")
		case SendInput:
            queue.push_back(&mannager.message_queue,InputWithFrame {
                frame=msg.frame,
                input=state.input,
            })
		case AckInput:
		    log.debug("got input")
		case EndSession:
		    log.debug("end session")
        }
	    if err != nil {
	   		continue // love the continue here
	    }

		free_all(context.temp_allocator)
    }
}

SendMesageErr :: union {
    cbor.Marshal_Error,
    net.UDP_Send_Error,
}


send_messsage :: proc(mannager:^NetworkMannager,msg:NetworkMessage) -> (bytes_written: int, err: SendMesageErr) {
    buffer,encode_err := encode_message(msg)
    if encode_err != nil {
        log.debug(encode_err)
        return 0,encode_err// todo return err
    }
    test_msg:NetworkMessage = {}
    cbor.unmarshal_from_bytes(buffer,&test_msg)
    bytes,net_err := net.send_udp(mannager.socket,buffer,mannager.endpoint)
    if net_err == net.UDP_Send_Error.None {
        return bytes,nil
    }
    return bytes,net_err

}


//we wrap here so we can add a custom impl if cbor is slow
encode_message :: proc(msg:NetworkMessage) -> ([]byte,cbor.Marshal_Error) {
    data,err := cbor.marshal_into_bytes(msg, cbor.ENCODE_FULLY_DETERMINISTIC,context.temp_allocator)
    if err != nil {
        log.debug(err)
        return data,err
    }
    return data,nil
}



decode_message :: proc(data:[]byte) -> (NetworkMessage,cbor.Unmarshal_Error) {
    msg:NetworkMessage = {}
    err := cbor.unmarshal_from_bytes(data,&msg)
    return msg,err
}
