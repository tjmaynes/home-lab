#!/usr/bin/env bash

set -e

function check_requirements() {
  throw_if_program_not_present "docker"
}

function main() {
  source ./scripts/common.sh

  check_requirements

  docker compose down

  umount "$MEDIA_BASE_DIRECTORY" || true
}

main
