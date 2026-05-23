package netcode

import "core:log"
import "core:net"
import "../utils"

//adds an acked feild for resending
AckWrapper ::struct($T:typeid) {
    acked:bool,
    tick:int,
    packet:T,
}

UdpCreateError :: enum {
    FailedToParseAddress,
    SocketBindErr,
}

ACK_WINDOW::20
ReliableUdpMannager :: struct($T:typeid) {
    bind_endpoint:             net.Endpoint,
    send_endpoint:             net.Endpoint,
    max_before_resend:         int,
    socket:                    net.UDP_Socket,
    sent_packets:              utils.FrameTrackedBuffer(ACK_WINDOW,AckWrapper(T)),
    serlize_packet:            proc(T) -> []byte,
    deserlize_packet:          proc([]byte) -> (T,bool), // I dont love this
}


make_reliable_mannager :: proc(
    $T:typeid,
    bind_port:int,
    target_ip:string,
    target_port:int,
    max_before_resend:int,
    serlize_packet:proc(T) -> []byte,
    deserlize_packet:proc([]byte) -> (T,bool),
) -> (ReliableUdpMannager(T),UdpCreateError) {
    bind_addr,ok := net.parse_ip4_address("0.0.0.0")
    assert(ok,"we failed to parse 0.0.0.0 this souldnt happen")

    target_addr, other_addr_ok := net.parse_ip4_address(target_ip)
    if other_addr_ok == false {
       	log.error("invalid address")
        return ReliableUdpMannager(T){},UdpCreateError.FailedToParseAddress
    }

    udp_socket,udp_err := net.make_bound_udp_socket(target_addr,target_port)
    net.set_blocking(udp_socket,true)
    if udp_err != nil {
    	log.error("failed to bind to socket")
    	return ReliableUdpMannager(T){},UdpCreateError.SocketBindErr
    }
    udp := ReliableUdpMannager(T) {
        bind_endpoint={
            address=bind_addr,
            port=bind_port,
        },
        send_endpoint={
            address=target_addr,
            port=target_port,
        },
        socket=udp_socket,
        sent_packets={},
        max_before_resend=max_before_resend,
        serlize_packet=serlize_packet,
        deserlize_packet=deserlize_packet,
    }
    for &packets in udp.sent_packets.inner.buffer {
        packets.acked=true
    }
    return udp,nil
}


send_message :: proc(mannager:^ReliableUdpMannager($T), packet:T,tick:int) -> (int,net.UDP_Send_Error) {
    raw_packet := mannager.serlize_packet(packet)
    if len(raw_packet) < 0{
        //todo return error
        log.error("we didnt serlize correctly")
        return 0,nil
    }
    bytes,net_err := net.send_udp(mannager.socket,raw_packet,mannager.send_endpoint)
    if net_err != net.UDP_Send_Error.None {
        return bytes,net_err
    }
    old_packet:=utils.insert_at_frame(&mannager.sent_packets,AckWrapper(T) {
        packet=packet,
        tick=tick,
        acked=false,
    },tick)
    assert((old_packet.acked==true || old_packet.tick==tick),"we failed to ack a packet before removing it this is bad")
    return bytes,net_err
}

recv_packet :: proc(mannager:ReliableUdpMannager($T),packet_write:^T) -> (int,net.UDP_Recv_Error) {
    buffer := [300]u8{}
    bytes_rcved,_,net_err := net.recv_udp(mannager.socket,buffer[:])
    if net_err != net.UDP_Recv_Error.None && bytes_rcved > 0 {
        return bytes_rcved,net_err
    }
    if bytes_rcved == 0 {
        return bytes_rcved,net.UDP_Recv_Error.None
    }
    packet,err := mannager.deserlize_packet(buffer[:])
    if err {
        return bytes_rcved,net.UDP_Recv_Error.Unknown
    }
    packet_write^ = packet
    return bytes_rcved,net_err
}

ack_msg :: proc(mannager:^ReliableUdpMannager($T),tick:int) {
    packet := utils.get_at_frame_prt(&mannager.sent_packets,tick)
    packet.acked = true
}

resend_messages :: proc(mannager:^ReliableUdpMannager($T),tick:int) -> (int) {
    total_bytes_written :=0
    for i := 0; i < len(mannager.sent_packets.buffer); i+=1 {
        packet := mannager.sent_packets.buffer[i]
        if !packet.acked && tick - packet.tick > mannager.max_before_resend {

            net_bytes_written,net_err := send_message(mannager, packet.packet,packet.tick)
            if net_err != nil {
                log.warn(net_err)
                when ODIN_DEBUG {
                    panic("we had a netcode err in resend") // temp
                }
                continue
                // return net_bytes_written,net_err
            }
            total_bytes_written+= net_bytes_written
        }
    }
    return total_bytes_written
}
