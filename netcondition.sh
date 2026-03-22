#!/bin/bash
# usage: ./netcondition.sh [bad|worse|terrible|off] [port]
# example: ./netcondition.sh bad 7777

IFACE=lo
PORT=${2:-3636}
setup_base() {
  # Tear down first to avoid conflicts
  sudo tc qdisc del dev $IFACE root 2>/dev/null

  # Root prio qdisc
  sudo tc qdisc add dev $IFACE root handle 1: prio

  # Filters for both directions on the port
  sudo tc filter add dev $IFACE protocol ip parent 1:0 prio 1 \
    u32 match ip dport $PORT 0xffff flowid 1:1
  sudo tc filter add dev $IFACE protocol ip parent 1:0 prio 1 \
    u32 match ip sport $PORT 0xffff flowid 1:1
}

case $1 in
  bad-no-loss)
    setup_base
    sudo tc qdisc add dev $IFACE parent 1:1 handle 10: netem delay 80ms 10ms
    echo "Bad connection on port $PORT";;
  bad)
    setup_base
    sudo tc qdisc add dev $IFACE parent 1:1 handle 10: netem delay 80ms 10ms loss 1%
    echo "Bad connection on port $PORT";;
  worse)
    setup_base
    sudo tc qdisc add dev $IFACE parent 1:1 handle 10: netem delay 150ms 30ms loss 5% duplicate 1%
    echo "Worse connection on port $PORT";;
  terrible)
    setup_base
    sudo tc qdisc add dev $IFACE parent 1:1 handle 10: netem delay 300ms 50ms loss 15% reorder 10% 50%
    echo "Terrible connection on port $PORT";;
  off)
    sudo tc qdisc del dev $IFACE root 2>/dev/null
    echo "Conditions cleared";;
  *)
    echo "Usage: $0 [bad|worse|terrible|off] [port]"
    echo "Example: $0 bad 7777";;
esac
