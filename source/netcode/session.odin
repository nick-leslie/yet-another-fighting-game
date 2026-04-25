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
    // move below into the input section
    // rcvd_inputs:utils.RingBuffer(MAX_NETWORK_WINDOW,InputWithFrame),
    other_player_connected:bool,
    //ptr because we dont want to  store this in the network mannager
    remote_input_queue:^utils.RingBuffer(MAX_NETWORK_WINDOW,InputWithFrame),
    should_run:bool,
    game_start_sent_at:time.Time,
   	thread: ^thread.Thread,
}


make_session_mannager :: proc(
    bind_port:int,
    target_ip:string,
    target_port:int,
    remote_input_queue:^utils.RingBuffer(MAX_NETWORK_WINDOW,InputWithFrame)
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
        remote_input_queue=remote_input_queue,
        other_player_connected=false,
        should_run=false,
        game_start_sent_at=time.now(),
        thread=nil,
    }
    return mannager, nil
}

//this should be in another thread
recv_network_loop :: proc(mannager:^SessionMannager) {
	context.logger = g_context.logger
	// make this not fixed
    log.debug("started listening for messages")
    for mannager.should_run {
	    buffer := [150]u8{}
	    net.recv_udp(mannager.socket,buffer[:])

		// remove me we want to make our own queue
	    msg:NetworkMessage = {}
		err := cbor.unmarshal_from_bytes(buffer[:],&msg)
		switch state in msg.message_type {
		//TODO game start not working of we packet loss
		case RequestGameStart:
            log.debug("connecting")
            now := time.now()
            send_msg := NetworkMessage {
                packet_version=MESSAGE_VERSION,
				frame=-1,
	            message_type=AcceptGameStart {
					character=0,
					now=now,
				},
            }
            log.debug(send_msg)

            send_message(mannager.udp,send_msg)
		case AcceptGameStart:
			// rtt := time.diff(
			// 	state.now(),
			// 	mannager.game_start_sent_at,
			// )
			g.game_run = true
			remote_now := state.now
   			now := time.now()
      		start_time := time.time_add(now,time.Second * 3)
            send_msg := NetworkMessage {
			   	packet_version=MESSAGE_VERSION,
			    frame=-1,
			    message_type=SetStartTime {
					start_time=start_time,
				},
			}
			log.debug(remote_now)
            log.debug(send_msg)
            g.start_time = start_time
            send_message(mannager.udp,send_msg)
		case SetStartTime:
			g.game_run = true
			g.start_time = state.start_time
			log.debug(state.start_time)
			// g.game_run = true
		case SendInput:
			input:=InputWithFrame {
                frame=msg.frame,
                input=state.input,
            }
            utils.push(&mannager.rcvd_inputs.inner,input)
            //sent acc
            send_message(mannager.udp,NetworkMessage {
           		packet_version =0,
           		frame=msg.frame,
            	message_type=AckInput{
                  input=state.input,
                },
            })
		case AckInput:
		    // if
		input_ack := utils.get_at_frame_prt(&mannager.sent_inputs, msg.frame)
			if state.input == input_ack.input {
			    input_ack.acked = true
			}
				//conform input
		case EndSession:
		    log.debug("end session")
        }
	    if err != nil {
	   		continue // love the continue here
	    }

		free_all(context.temp_allocator)
    }
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
