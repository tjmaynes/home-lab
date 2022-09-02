#!/bin/bash

set -eo pipefail

RUN_TYPE=$1

function run_dev_command() {
  source ./scripts/common.sh

  throw_if_program_not_present "vagrant"

  (vagrant destroy --force || true) && vagrant up
}

function main() {
  case "$RUN_TYPE" in
    "start")
      ./scripts/start.sh
      ;;
    "stop")
      ./scripts/stop.sh
      ;;
    "install")
      sudo ./scripts/install.sh
      ;;
    "backup")
      ./scripts/backup.sh
      ;;
    "dev")
      run_dev_command
      ;;
    *)
      echo "Unable to run runner script with parameter 1 '$RUN_TYPE'."
      exit 1
      ;;
  esac

  echo "Done!"
}

main
