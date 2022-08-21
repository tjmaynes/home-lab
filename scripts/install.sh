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
  elif [[ -z "$(command -v tailscale)" ]]; then
    echo "Please install 'tailscale' before running this script"
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

  source ./scripts/common.sh
  
  set_environment_variables

  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/pihole"
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/dnsmasq.d"
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/data"
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/letsencrypt"
  ensure_directory_exists "$TAILSCALE_BASE_DIRECTORY/var/lib"

  ensure_directory_exists "$PLEX_BASE_DIRECTORY/config"
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/transcode"
  ensure_directory_exists "$CALIBRE_WEB_BASE_DIRECTORY/config"
  ensure_directory_exists "$GOGS_BASE_DIRECTORY/data"
  ensure_directory_exists "$GOGS_DB_BASE_DIRECTORY"
  ensure_directory_exists "$HOME_ASSISTANT_BASE_DIRECTORY/config"

  ensure_directory_exists "$HOMER_LOCAL_WEB_BASE_DIRECTORY/www/assets"
  ensure_directory_exists "$HOMER_REMOTE_WEB_BASE_DIRECTORY/www/assets"
  
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/config"
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/metadata"
  ensure_directory_exists "$PODGRAB_BASE_DIRECTORY/config"
  ensure_directory_exists "$PHOTOVIEW_BASE_DIRECTORY/cache"
  ensure_directory_exists "$PHOTOVIEW_DB_BASE_DIRECTORY"
  ensure_directory_exists "$BITWARDEN_BASE_DIRECTORY/data"
  ensure_directory_exists "$PHOTOUPLOADER_BASE_DIRECTORY/config"

  ensure_directory_exists "$PHOTOUPLOADER_BASE_DIRECTORY/database"
  touch "$PHOTOUPLOADER_BASE_DIRECTORY/database/filebrowser.db"

  ensure_directory_exists "$NODE_RED_BASE_DIRECTORY/data"
  sudo chmod 777 "$NODE_RED_BASE_DIRECTORY/data"

  sed \
    -e "s/%protocol-type%/https/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    data/homer.template.yml > "$HOMER_REMOTE_WEB_BASE_DIRECTORY/www/assets/config.yml"

  sed \
    -e "s/%protocol-type%/http/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    data/homer.template.yml > "$HOMER_LOCAL_WEB_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/homer-logo.png "$HOMER_LOCAL_WEB_BASE_DIRECTORY/www/assets/logo.png"
  cp -f static/homer-logo.png "$HOMER_REMOTE_WEB_BASE_DIRECTORY/www/assets/logo.png"
  
  cp -f data/photo-uploader.json "$PHOTOUPLOADER_BASE_DIRECTORY/config/settings.json"

  if ! cat /etc/sysctl.conf | grep 'net.ipv4.ip_forward=1'; then
    echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
  fi

  if ! cat /etc/sysctl.conf | grep 'net.ipv6.conf.all.forwarding=1'; then
    echo 'net.ipv6.conf.all.forwarding=1' | sudo tee -a /etc/sysctl.conf
  fi

  sudo sysctl -p /etc/sysctl.conf

  sudo -E docker-compose up -d --remove-orphans

  sudo -E tailscale up \
    --accept-dns=false \
    --advertise-exit-node \
    --advertise-routes=192.168.4.0/22 \
    --reset

  echo "Done!"
}

main
