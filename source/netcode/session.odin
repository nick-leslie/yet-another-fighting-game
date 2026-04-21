package netcode

import "core:net"
import "core:log"
import "core:time"
import gk "../game_kernel"
import "../utils"
import "core:thread"
import "base:runtime"

NetworkMessage :: struct {
    packet_version:u8,
    frame:int,
    message_type:MessageType,
    // game_check_sum:u32, // todo check me
}

MessageType :: union #no_nil {
    RequestGameStart,
    AcceptGameStart,
    SetStartTime,
    SendInput,
    AckInput,
    EndSession,
}
RequestGameStart :: struct {
    character:u8,
    now:time.Time,
}

AcceptGameStart :: struct {
	character:u8,
	now:time.Time,
}

SetStartTime :: struct {
	start_time:time.Time,
}

SendInput :: struct {
    input:gk.Input,
}

AckInput :: struct {
    input:gk.Input,
} // todo see what we need to send with the acc

EndSession :: struct {}

InputWithFrame :: struct {
    frame:int,
    input:gk.Input,
}

LobbyCreateError :: enum {
	InvalidBindAddr,
	InvalidAddress,
	SocketBindErr,
}

MAX_ROLLBACK_WINDOW :: 15
MAX_NETWORK_WINDOW :: MAX_ROLLBACK_WINDOW * 2 // we should figure this out
SessionMannager :: struct {
    udp:ReliableUdpMannager(NetworkMessage),
    rcvd_inputs:utils.RingBuffer(MAX_NETWORK_WINDOW,InputWithFrame),
    other_player_connected:bool,
    should_run:bool,
    game_start_sent_at:time.Time,
   	thread: ^thread.Thread,
}


make_session_mannager :: proc(
    port:int,
    other_ip:string,
    other_port:int,
    allocator:runtime.Allocator
) -> (Maybe(SessionMannager),LobbyCreateError) {
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
    mannager := SessionMannager {}
    return mannager, nil
}
