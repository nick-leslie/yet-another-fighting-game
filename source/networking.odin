package game
import "core:net"
import "core:sync"
import "core:bytes"
import "core:time/datetime"
import "core:thread"
import "core:log"
import gk "game_kernel"
import "core:encoding/cbor"  // Compact binary JSON-like format
NetworkMessage :: struct {
    packet_version:u8,
    frame:int,
    message_type:MessageType
    // game_check_sum:u32, // todo check me
}

MessageType :: union #no_nil {
    ConnectToOther,
    SendInput

}
ConnectToOther :: struct {
    character:u8
}

SendInput :: struct {
    input:gk.Input
}
MAX_NETWORK_WINDOW :: MAX_ROLLBACK_WINDOW * 2 // we should figure this out
NetworkMannager :: struct {
    address:net.Address,
    port:int,
    socket:  net.UDP_Socket,
   	thread: ^thread.Thread,
    message_queue:[MAX_NETWORK_WINDOW]NetworkMessage,
    reader_pos:int,
    writer_pos:int
}

make_lobby :: proc() {
    addr,ok := net.parse_ip4_address("")
    if ok == false  {
    	log.error("invalida address")
        return
    }
    udp_socket,udp_err := net.make_bound_udp_socket(addr,1233)
    if udp_err != nil {
    	log.error("failed to bind to socket")
    	return
    }
    log.debug(udp_socket)
    // tcp_socket,tcp_err := net.dial_tcp_from_address_and_port(addr,1234)
}

recv_input_network :: proc(mannager:^NetworkMannager) {
    // make this not fixed

    buffer := [size_of(NetworkMessage)]u8{}
    net.recv_udp(mannager.socket,buffer[:])
    msg,err := decode_message(buffer[:])
    mannager.message_queue[mannager.writer_pos] = msg
    //we dont need this to be attomic because its one producer
    mannager.writer_pos = mannager.writer_pos %% len(mannager.message_queue)
}

poll_remote_input :: proc(mannager:^NetworkMannager) -> Maybe(NetworkMessage) {
    if mannager.reader_pos+1 > mannager.writer_pos {
        return {} // todo reutrn an error here
    }
    value := mannager.message_queue[mannager.reader_pos]
    mannager.reader_pos += 1
    return value
}


EncodeErr :: union {
    cbor.Marshal_Error
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
