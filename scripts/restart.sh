#!/usr/bin/env bash

set -e

function check_requirements() {
  throw_if_program_not_present "docker"

  throw_if_env_var_not_present "TIMEZONE" "$TIMEZONE"
  throw_if_env_var_not_present "PUID" "$PUID"
  throw_if_env_var_not_present "PGID" "$PGID"
}

function main() {
  source ./scripts/common.sh

  check_requirements

  docker compose restart
}

main
