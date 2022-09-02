#!/bin/bash

set -eo pipefail

function check_requirements() {
  throw_if_program_not_present "apt-get"
  throw_if_program_not_present "usermod"
  throw_if_program_not_present "curl"

  throw_if_env_var_not_present "NONROOT_USERNAME" "$NONROOT_USERNAME"
}

function main() {
  check_requirements

  sudo apt-get update && sudo apt-get upgrade

  sudo adduser "$NONROOT_USERNAME"

  sudo ./scripts/install-docker.sh
  sudo usermod -aG docker "$NONROOT_USERNAME"

  sudo ./scripts/setup-argon1-fan.sh

  sudo reboot
}

main
