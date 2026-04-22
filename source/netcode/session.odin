package netcode

import "core:net"
import "core:log"
import "core:time"
import gk "../game_kernel"
import "../utils"
import "core:thread"
import "base:runtime"
import "core:encoding/cbor"

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
	FailedToMakeReliableUdp
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
    bind_port:int,
    target_ip:string,
    target_port:int,
    allocator:runtime.Allocator
) -> (Maybe(SessionMannager),LobbyCreateError) {
    udp_mannager,err := make_reliable_mannager(
        NetworkMessage,
        bind_port,
        target_ip,
        target_port,
        10, // max before resend
        encode_message,
        decode_message
    )
    if err != nil {
        return nil,LobbyCreateError.FailedToMakeReliableUdp
    }
    mannager := SessionMannager {
        udp=udp_mannager.(ReliableUdpMannager(NetworkMessage)),
        rcvd_inputs=utils.RingBuffer(MAX_NETWORK_WINDOW, InputWithFrame) {},
        other_player_connected=false,
        should_run=false,
        game_start_sent_at=time.now(),
        thread=nil,
    }
    return mannager, nil
}

encode_message :: proc(msg:NetworkMessage) -> []byte {
    data,err := cbor.marshal_into_bytes(msg, cbor.ENCODE_FULLY_DETERMINISTIC,context.temp_allocator)
    if err != nil {
        log.error(err)
        return {}
    }
    return data
}


decode_message :: proc(data:[]byte) -> Maybe(NetworkMessage) {
    msg:NetworkMessage = {}
    err := cbor.unmarshal_from_bytes(data,&msg)
    if err != nil {
        return nil
    }
    return msg
}
