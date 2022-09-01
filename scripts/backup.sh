#!/bin/bash

set -eo pipefail

function main() {
  source ./scripts/common.sh

  throw_if_program_not_present "rsync"

  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NAS_IP" "$NAS_IP"
  throw_if_env_var_not_present "NAS_USER" "$NAS_USER"
  throw_if_env_var_not_present "NAS_BACKUP_DIRECTORY" "$NAS_BACKUP_DIRECTORY"

  WEEK_DIR=$(date +%Y-%m)
  WEEK_DIR="$WEEK_DIR-$((($(date +%-d)-1)/7+1))"

  rsync -av -e ssh "${DOCKER_BASE_DIRECTORY}/" "${NAS_USER}@${NAS_IP}::${NAS_BACKUP_DIRECTORY}/$WEEK_DIR"
}

main