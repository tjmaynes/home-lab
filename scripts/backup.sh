#!/usr/bin/env bash

set -eo pipefail

function main() {
  source ./scripts/common.sh

  throw_if_program_not_present "rsync"

  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"

  setup_backup_mount
  setup_media_mount

  TODAY=$(date +"%Y%m%d")

  echo "Backing up docker directory..."
  rsync -avuz --delete --no-perms \
    --log-file="$BACKUP_LOGS_DIRECTORY/$TODAY-backup.log" \
    --exclude "/docker/plex-server/config/Library/Application Support/" \
    --exclude "/docker/plex-server/config/cache/" \
    --exclude "/docker/pigallery-web/tmp/" \
    --exclude "/docker/nginx-proxy/data/logs/" \
    --exclude "/docker/pihole-server/pihole/macvendor.db" \
    --exclude "/docker/nodered-web/data/node_modules/" \
    --exclude "/docker/loki-server/data/loki/chunks/" \
    "$DOCKER_BASE_DIRECTORY" \
    "$BACKUP_BASE_DIRECTORY"

  echo "Backing up media directory..."
  rsync -avuz --delete --no-perms \
    --log-file="$BACKUP_LOGS_DIRECTORY/$TODAY-backup.log" \
    "$MEDIA_BASE_DIRECTORY" \
    "$BACKUP_BASE_DIRECTORY"

  echo "Backing up geck project..."
  rsync -avuz --delete --no-perms \
    --log-file="$BACKUP_LOGS_DIRECTORY/$TODAY-backup.log" \
    --exclude "/geck/.git/" \
    "../geck" \
    "$BACKUP_BASE_DIRECTORY"
}

main
