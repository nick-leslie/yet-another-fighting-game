package netcode

import "core:log"
import "core:testing"
import "core:net"
import "core:encoding/endian"
import "core:math/rand"



get_stun_server_address :: proc(hostname:string) ->(result:net.DNS_Record,err:net.DNS_Error) {
    os_records := net.get_dns_records_from_os(hostname,.DNS_TYPE_A) or_return
    log.info(os_records)
    if len(os_records) != 0 {
        return os_records[0],net.DNS_Error.None // we may want something smarter but for now this works
    }
    defer net.destroy_dns_records(os_records)
    nameservers:[]net.Endpoint = {
        net.Endpoint {
            address=net.IP4_Address{8,8,8,8},
            port=53,
        }
    }
    name_server_records := net.get_dns_records_from_nameservers(
        hostname,
        .DNS_TYPE_A,
        nameservers,
        os_records
    ) or_return
    defer net.destroy_dns_records(name_server_records)
    log.info(name_server_records)
    if len(name_server_records) != 0 {
        return name_server_records[0],net.DNS_Error.None // we may want something smarter but for now this works
    }
    return net.DNS_Record{},net.DNS_Error.Server_Error // we want something better
}



create_stun_init :: proc () -> [2048]u8 {
    buffer:[2048]u8 // check this
    endian.put_u16(buffer[:],.Big,0x0001)
    endian.put_u16(buffer[2:],.Big,0) // len
    endian.put_u32(buffer[4:],.Big,0x2112A442) // cookie
    n:=rand.read(buffer[8:8+12])
    //todo push data
    // todo get 96 random bytes
    // 0x0001 // class size
    return buffer
}

@test
create_stun_init_test :: proc(t: ^testing.T) {
    // Seed the RNG so the transaction ID is deterministic.
    // Replace this with however create_stun_init sources randomness.
    SEED :: u64(1)

    expected: [20]u8 = {
        0x00, 0x01, 0x00, 0x00, // Type: Binding Request, Length: 0
        0x21, 0x12, 0xa4, 0x42, // Magic Cookie
        0, 0, 0, 0,             // Transaction ID (filled below)
        0, 0, 0, 0,
        0, 0, 0, 0,
    }

    rand.reset(SEED)
    _ = rand.read(expected[8:8+12])                       // Transaction ID

    rand.reset(SEED)
    buffer := create_stun_init()
    // testing.expect(t, len(buffer) == 20, "STUN Binding Request must be 20 bytes")

    // Header checks — these don't depend on RNG, so they catch bugs
    // even if the transaction ID changes.
    testing.expect_value(t, buffer[0], u8(0x00))
    testing.expect_value(t, buffer[1], u8(0x01))
    testing.expect_value(t, buffer[2], u8(0x00))
    testing.expect_value(t, buffer[3], u8(0x00))
    testing.expect_value(t, buffer[4], u8(0x21))
    testing.expect_value(t, buffer[5], u8(0x12))
    testing.expect_value(t, buffer[6], u8(0xa4))
    testing.expect_value(t, buffer[7], u8(0x42))

    // Full-buffer check against the seeded expected bytes.
    for i := 0 ; i<len(expected)-1;i+=1 {
        testing.expect_value(t, buffer[i],expected[i])
    }
}

@test
send_stun_request :: proc(t:^testing.T) {

}

@test
get_stun_server_address_test :: proc (t:^testing.T) {
    result,err := get_stun_server_address("stun.l.google.com")
    testing.expect_value(t,err,net.DNS_Error.None)
    // a little bit of a flakey test because google could change the address or go down at any time
    testing.expect_value(t,result,net.DNS_Record_IP4{
        base = net.DNS_Record_Base{
            record_name = "stun.l.google.com",
            ttl_seconds = 226,
        }, address = {74, 125, 250, 129}
    })
}
