#!/usr/bin/env bash

set -eo pipefail

function check_requirements() {
  throw_if_program_not_present "docker"
}

function teardown_macvlan() {
  throw_if_program_not_present "ip"

  if ip link show | grep "macvlan0"; then
    ip link set macvlan0 down
    ip link delete macvlan0
  fi
}

function main() {
  source ./scripts/common.sh

  check_requirements

  docker-compose down

  teardown_macvlan
}

main
