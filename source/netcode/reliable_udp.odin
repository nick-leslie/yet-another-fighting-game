package netcode

import "core:net"
import "../utils"

//adds an acked feild for resending
AckWrapper ::struct($T:typeid) {
    acked:bool,
    tick:int,
    packet:T,
}


ACK_WINDOW::20
ReliableUdpMannager :: struct($T:typeid) {
    address:              net.Address,
    port:                 int,
    max_before_resend:    int,
    socket:               net.UDP_Socket,
    sent_packets:         utils.FrameTrackedBuffer(ACK_WINDOW,AckWrapper(T)),
    serlize_packet:       proc(T) -> []byte,
    deserlize_packet:     proc([]byte) -> T,
}



send_message :: proc(mannager:ReliableUdpMannager($T), packet:T,tick:int) {
    raw_packet := mannager.serlize_packet(packet)
    if len(raw_packet) < 0{
        //todo return error
        return
    }
    bytes,net_err := net.send_udp(mannager.socket,raw_packet,mannager.endpoint)
    if net_err == net.UDP_Send_Error.None {
        return bytes,nil
    }
    old_packet:=utils.insert_at_frame(mannager.sent_packets,AckWrapper {
        packet=packet,
        tick=tick,
        acked=false,
    },tick)
    assert((old_packet.acked==true || old_packet.tick==tick),"we failed to ack a packet before removing it this is bad")
    return bytes,net_err
}

recv_packet :: proc(mannager:ReliableUdpMannager($T),tick:int) -> (T,net_err) {
    raw_packet,net_err := net.recv_udp(mannager.socket)
    if net_err != net.UDP_Send_Error.None {
        return nil,net_err
    }
    packet := mannager.deserlize_packet(raw_packet)
    return packet,net_err
}

resend_messages :: proc(mannager:ReliableUdpMannager($T),tick:int) {
    for i := 0; i < len(mannager.sent_packets.buffer); i+=1 {
        packet := &mannager.sent_packets.buffer[i]
        if !packet.acked && tick - packet.tick > mannager.max_before_resend {

            net_bytes_written,net_err := send_messsage(mannager, packet.packet,packet.tick)
            if net_err != nil {
                return net_bytes_written,net_err
            }
            total_bytes_written+= net_bytes_written
        }
    }
}
