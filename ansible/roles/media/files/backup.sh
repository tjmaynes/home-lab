#!/usr/bin/env bash

set -eo pipefail

function main() {
  TODAY=$(date +"%Y%m%d")

  echo "Backing up /opt/programs directory..."
  rsync -avuz --delete --no-perms \
    --log-file="/opt/backups/backup/logs/$TODAY-backup.log" \
    --exclude "/opt/programs/plex-server/config/Library/Application Support/" \
    --exclude "/opt/programs/plex-server/config/cache/" \
    --exclude "/opt/programs/pigallery-web/tmp/" \
    --exclude "/opt/programs/nginx-proxy/data/logs/" \
    --exclude "/opt/programs/pihole-server/pihole/macvendor.db" \
    --exclude "/opt/programs/nodered-web/data/node_modules/" \
    --exclude "/opt/programs/loki-server/data/loki/chunks/" \
    "/opt/programs" \
    "/opt/backups/backup"

  echo "Backing up /opt/media directory..."
  rsync -avuz --delete --no-perms \
    --log-file="/opt/backups/backup/logs/$TODAY-backup.log" \
    "/opt/media" \
    "/opt/backups/backup"
}

main