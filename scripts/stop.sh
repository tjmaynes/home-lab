#!/usr/bin/env bash

set -e

function main() {
  source ./scripts/common.sh

  throw_if_program_not_present "docker"

  docker compose down
}

main
