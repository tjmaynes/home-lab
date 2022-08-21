#!/bin/bash

set -e

export BASE_DIRECTORY=$1
export SERVICE_DOMAIN=$2
export PIHOLE_PASSWORD=$3
export PLEX_CLAIM_TOKEN=$4

function check_requirements() {
  if [[ -z "$(command -v docker)" ]]; then
    echo "Please install 'docker' before running this script"
    exit 1
  fi
}

function main() {
  check_requirements

  source ./scripts/common.sh

  set_environment_variables

  sudo -E docker-compose down
}

main