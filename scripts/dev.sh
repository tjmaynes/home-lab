#!/usr/bin/env bash

set -eo pipefail

function install_vagrant_plugin() {
  if ! vagrant plugin list | grep -q "$1"; then
    vagrant plugin install $1
  fi
}

function main() {
  source ./scripts/common.sh

  throw_if_program_not_present "vagrant"

  install_vagrant_plugin "vagrant-tun"

  # (vagrant destroy --force || true) && \
    vagrant up
}

main