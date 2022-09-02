#!/bin/bash

set -eo pipefail

RUN_TYPE=$1

function main() {
  source ./scripts/common.sh

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
      throw_if_program_not_present "vagrant"
      vagrant up
      ;;
    *)
      echo "Unable to run runner script with parameter 1 '$RUN_TYPE'."
      exit 1
      ;;
  esac

  echo "Done!"
}

main
