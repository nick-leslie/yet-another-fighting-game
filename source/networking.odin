package game
import "core:net"
import "core:time"
import "base:runtime"
// import "core:sync"
import "core:thread"
import "core:log"
import gk "game_kernel"
import "core:encoding/cbor"
import "./utils"

MESSAGE_VERSION :: 0
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

AckedInput :: struct {
    acked:bool,
    using inner:InputWithFrame,
}

MAX_NETWORK_WINDOW :: MAX_ROLLBACK_WINDOW * 2 // we should figure this out
NetworkMannager :: struct {
    address:net.Address,
    port:int,
    socket:  net.UDP_Socket,
   	thread: ^thread.Thread,
    //todo remove me we want to decouple this
    // could these be linked lists
    rcvd_inputs:utils.RingBuffer(MAX_NETWORK_WINDOW,InputWithFrame),
    sent_inputs:utils.FrameTrackedBuffer(MAX_NETWORK_WINDOW,AckedInput),
    endpoint:net.Endpoint,
    other_player_connected:bool,
    should_run:bool,
    game_start_sent_at:time.Time,
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
    mannager := NetworkMannager {
    	socket = udp_socket,
    	address = addr,
     	port = port,
     	rcvd_inputs = utils.RingBuffer(MAX_NETWORK_WINDOW,InputWithFrame) {},
     	sent_inputs = utils.FrameTrackedBuffer(MAX_NETWORK_WINDOW,AckedInput) {},
        endpoint=net.Endpoint {
            address = other_addr,
            port = other_port,
        },
        other_player_connected = false,
        thread = nil,
    }
    for i:=0;i<len(mannager.sent_inputs.buffer);i+=1 {
        // set all the default tickts to true that way we arnt sending
        // fake inputs from init
        mannager.sent_inputs.buffer[i] = AckedInput {
            acked = true,
            frame = 0,
            input = gk.Input {
                dir=.Neutral,
            },
        }
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

            send_messsage(mannager,send_msg)
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
            send_messsage(mannager,send_msg)
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
            send_messsage(mannager,NetworkMessage {
           		packet_version =0,
           		frame=msg.frame,
            	message_type=AckInput{
                  input=state.input,
                },
            })
		case AckInput:
		    // if
		    log.debug("got acc")
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

SendMesageErr :: union {
    cbor.Marshal_Error,
    net.UDP_Send_Error,
}


send_messsage :: proc(mannager:^NetworkMannager,msg:NetworkMessage) -> (bytes_written: int, err: SendMesageErr) {
    // options := time.Benchmark_Options {

    // }
    // time.benchmark(&options)
    buffer,encode_err := encode_message(msg)
    if encode_err != nil {
        log.debug(encode_err)
        return 0,encode_err// todo return err
    }
    bytes,net_err := net.send_udp(mannager.socket,buffer,mannager.endpoint)
    if net_err == net.UDP_Send_Error.None {
        return bytes,nil
    }
    return bytes,net_err

}

send_input :: proc(mannager:^NetworkMannager, input:gk.Input, frame: int,delay:int) -> (bytes_written: int, err: SendMesageErr) {
    msg := NetworkMessage {
        packet_version=MESSAGE_VERSION,
        frame=frame+delay,
        message_type=SendInput {
            input,
        },
    }
    utils.insert_at_frame(&mannager.sent_inputs,AckedInput{
        acked=false,
        frame=frame+delay, // add delay frames
        input=input,
    },frame+delay)
    return send_messsage(mannager, msg)
}

resend_packets :: proc(mannager:^NetworkMannager, frame: int) -> (bytes_written: int, err: SendMesageErr) {
    total_bytes_written := 0
    for i := 0; i < len(mannager.sent_inputs.buffer); i+=1 {
        input := mannager.sent_inputs.buffer[i]
        // if we havent been acked and its 2 frames old
        if input.acked == false && input.frame+2 >= frame {
            msg := NetworkMessage {
                packet_version=MESSAGE_VERSION,
                frame=input.frame,
                message_type=SendInput {
                    input=input.input,
                },
            }
            net_bytes_written,net_err := send_messsage(mannager, msg)
            if net_err != nil {
                return net_bytes_written,net_err
            }
            total_bytes_written+= net_bytes_written
        }
    }
    return total_bytes_written, nil
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
