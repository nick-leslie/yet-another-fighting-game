package game
import "core:net"
import "core:log"

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
