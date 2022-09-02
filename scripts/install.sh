#!/bin/bash

set -eo pipefail

function check_requirements() {
  throw_if_program_not_present "apt-get"
  throw_if_program_not_present "usermod"
  throw_if_program_not_present "curl"

  throw_if_env_var_not_present "DOCKER_USER" "$DOCKER_USER"
}

function main() {
  check_requirements

  sudo apt-get update && sudo apt-get upgrade

  sudo adduser "$DOCKER_USER"

  sudo ./scripts/install-docker.sh
  sudo usermod -aG docker "$DOCKER_USER"

  sudo ./scripts/setup-argon1-fan.sh

  sudo reboot
}

main
