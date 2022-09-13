#!/bin/bash

set -eo pipefail

function main() {
  source ./scripts/common.sh

  throw_if_program_not_present "rsync"

  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NAS_IP" "$NAS_IP"
  throw_if_env_var_not_present "NAS_USER" "$NAS_USER"
  throw_if_env_var_not_present "NAS_BACKUP_DIRECTORY" "$NAS_BACKUP_DIRECTORY"

  TODAY=$(date +"%Y%m%d")

  BACKUP_LOGS_DIRECTORY=${DOCKER_BASE_DIRECTORY}/backup-logs
  ensure_directory_exists "$BACKUP_LOGS_DIRECTORY"

  sudo -u "$NONROOT_USER" rsync -avuz --delete \
    --exclude cache/ \
    --log-file=$BACKUP_LOGS_DIRECTORY/$TODAY-backup.log \
    -e ssh "${DOCKER_BASE_DIRECTORY}" \
    "${NAS_USER}@${NAS_IP}:${NAS_BACKUP_DIRECTORY}"
}

main