#!/bin/bash

set -e

BRIDGE_IP_ADDRESS=${1:-192.168.1.210}
STARTING_IP_ADDRESS=${2:-192.168.1.201}
IS_CRON_JOB=$3

function main() {
  if ! ip link show | grep "ovs_eth0"; then
    echo "Please create a virtual network for 'ovs_eth0' before running this script"
    exit 1
  fi

  if [[ -n "$IS_CRON_JOB" ]]; then
    sleep 60
  fi

  if ! ip link show | grep "macvlan0"; then
    ip link add macvlan0 link ovs_eth0 type macvlan mode bridge
    ip addr add $BRIDGE_IP_ADDRESS/28 dev macvlan0
    ip link set macvlan0 up
    ip route add $STARTING_IP_ADDRESS dev macvlan0
  fi
}

main
