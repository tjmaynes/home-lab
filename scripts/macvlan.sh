

#!/usr/bin/env bash

set -e

function main() {
  if ! ip link show eth0; then
    echo "Please create a virtual network for 'eth0' before running this script"
    exit 1
  fi

  if ! ip link show macvlan0; then
    ip link add macvlan0 link eth0 type macvlan mode bridge
    ip addr add 192.168.4.210/32 dev macvlan0
    ip link set macvlan0 up
    ip route add 192.168.4.201/32 dev macvlan0
  fi
}

main