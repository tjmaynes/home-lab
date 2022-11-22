#!/usr/bin/env bash

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
    --log-file="$BACKUP_LOGS_DIRECTORY/$TODAY-backup.log" \
    --exclude "/docker/plex-server/config/Library/Application Support/" \
    --exclude "/docker/plex-server/config/cache/" \
    --exclude "/docker/pigallery-web/tmp/" \
    --exclude "/docker/nginx-proxy/data/logs/" \
    --exclude "/docker/pihole-server/pihole/macvendor.db" \
    --exclude "/docker/nodered-web/data/node_modules/" \
    --exclude "/docker/code-server/config/.asdf/" \
    --exclude "/docker/code-server/config/.vim/" \
    --exclude "/docker/code-server/config/.npm-packages/" \
    --exclude "/docker/code-server/config/.zprezto/" \
    --exclude "/docker/code-server/config/.gnupg/" \
    --exclude "/docker/code-server/config/.cache/" \
    --exclude "/docker/code-server/config/.cache/CachedExtensions/" \
    --exclude "/docker/code-server/config/.cache/CachedExtensionVSIXs/" \
    --exclude "/docker/code-server/config/.cache/CachedExtensions/" \
    --exclude "/docker/code-server/config/.alacritty.yml" \
    --exclude "/docker/code-server/config/.bash-fns.sh" \
    --exclude "/docker/code-server/config/.emacs" \
    --exclude "/docker/code-server/config/.npmrc" \
    --exclude "/docker/code-server/config/.offlineimap.py" \
    --exclude "/docker/code-server/config/.offlineimaprc" \
    --exclude "/docker/code-server/config/.signature" \
    --exclude "/docker/code-server/config/.tmux.conf" \
    --exclude "/docker/code-server/config/.tool-versions" \
    --exclude "/docker/code-server/config/.vimrc" \
    --exclude "/docker/code-server/config/.zpreztorc" \
    --exclude "/docker/code-server/config/.zshrc" \
    "$DOCKER_BASE_DIRECTORY" \
    "$BACKUP_BASE_DIRECTORY"

  cp .envrc.production "$BACKUP_BASE_DIRECTORY/docker"
}

main
