#!/bin/bash

set -eo pipefail

function main() {
  source ./scripts/common.sh

  throw_if_program_not_present "rsync"

  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"
  throw_if_env_var_not_present "NAS_BACKUP_DIRECTORY" "$NAS_BACKUP_DIRECTORY"
  throw_if_env_var_not_present "BACKUP_BASE_DIRECTORY" "$BACKUP_BASE_DIRECTORY"
  throw_if_env_var_not_present "NAS_MOUNT_PASSWORD" "$NAS_MOUNT_PASSWORD"
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"

  BACKUP_LOGS_DIRECTORY=${DOCKER_BASE_DIRECTORY}/logs
  ensure_directory_exists "$BACKUP_LOGS_DIRECTORY"

  ensure_directory_exists "$BACKUP_BASE_DIRECTORY"

  setup_nas_mount "$NAS_BACKUP_DIRECTORY" "$BACKUP_BASE_DIRECTORY"

  TODAY=$(date +"%Y%m%d")

  rsync -avuz --delete \
    --log-file=$BACKUP_LOGS_DIRECTORY/$TODAY-backup.log \
    --exclude cache/ \
    "$DOCKER_BASE_DIRECTORY" \
    "$BACKUP_BASE_DIRECTORY"
}

main