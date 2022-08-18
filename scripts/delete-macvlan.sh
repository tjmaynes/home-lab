#!/bin/bash

set -e

function main() {
  if ip link show | grep "macvlan0"; then
    ip link set macvlan0 down
    ip link delete macvlan0
  fi
}

main
