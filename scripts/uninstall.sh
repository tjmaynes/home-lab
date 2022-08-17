#!/bin/bash

set -e

export BASE_DIRECTORY=$1

function check_requirements() {
  if [[ -z "$(command -v docker)" ]]; then
    echo "Please install 'docker' before running this script"
    exit 1
  fi
}

function ensure_directory_exists() {
  TARGET_DIRECTORY=$1

  if [[ ! -d "$TARGET_DIRECTORY" ]]; then
    echo "Creating $TARGET_DIRECTORY directory..."
    mkdir -p "$TARGET_DIRECTORY"
  fi
}

function main() {
  check_requirements

  export GOGS_DB_PORT=5433
  export PHOTOVIEW_DB_PORT=5434

  sudo -E docker-compose down
}

main