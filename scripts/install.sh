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

function ensure_directory_exists() {
  TARGET_DIRECTORY=$1

  if [[ ! -d "$TARGET_DIRECTORY" ]]; then
    echo "Creating $TARGET_DIRECTORY directory..."
    mkdir -p "$TARGET_DIRECTORY"
  fi
}

function set_environment_variables() {
  if [[ -z "$BASE_DIRECTORY" ]]; then
    echo "Please an environment variable for 'BASE_DIRECTORY' before running this script"
    exit 1
  elif [[ -z "$SERVICE_DOMAIN" ]]; then
    echo "Please an environment variable for 'SERVICE_DOMAIN' before running this script"
    exit 1
  elif [[ -z "$PIHOLE_PASSWORD" ]]; then
    echo "Please an environment variable for 'PIHOLE_PASSWORD' before running this script"
    exit 1
  elif [[ -z "$PLEX_CLAIM_TOKEN" ]]; then
    echo "Please an environment variable for 'PLEX_CLAIM_TOKEN' before running this script"
    exit 1
  fi

  export ENVIRONMENT=development
  export TIMEZONE=America/Chicago
  export PUID=$(sudo id -u)
  export PGID=$(sudo id -g)

  export MEDIA_DIRECTORY=${BASE_DIRECTORY}/media

  export PHOTOS_DIRECTORY=${MEDIA_DIRECTORY}/Photos
  export BOOKS_DIRECTORY=${MEDIA_DIRECTORY}/Books
  export AUDIOBOOKS_DIRECTORY=${MEDIA_DIRECTORY}/Audiobooks
  export PODCASTS_DIRECTORY=${MEDIA_DIRECTORY}/Podcasts

  export TAILSCALE_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/tailscale-agent

  export PIHOLE_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/pihole-server
  export NGNIX_PROXY_MANAGER_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/nginx-proxy-manager-server
  export TAILSCALE_SOCKET="/volume1/@appdata/Tailscale/tailscaled.sock"

  export PLEX_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/plex-server
  export PLEX_PORT=32400

  export CALIBRE_WEB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/calibre-web
  export CALIBRE_WEB_PORT=8083

  export GOGS_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/gogs-web
  export GOGS_PORT=3000
  export GOGS_SSH_PORT=2222

  export GOGS_DB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/gogs-db
  export GOGS_USER=gogs
  export GOGS_DB=gogs
  export GOGS_DB_PASSWORD=gogs
  export GOGS_DB_PORT=5433

  export HOME_ASSISTANT_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/home-assistant-web
  export HOME_ASSISTANT_PORT=8123

  export HOMER_WEB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/homer-web
  export HOMER_WEB_PORT=8080

  export AUDIOBOOKSHELF_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/audiobookshelf-web
  export AUDIOBOOKSHELF_PORT=13378

  export PODGRAB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/podgrab-web
  export PODGRAB_PORT=9087

  export NODE_RED_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/node-red
  export NODE_RED_PORT=1880

  export PHOTOVIEW_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/photoview-server
  export PHOTOVIEW_PORT=9080

  export PHOTOVIEW_DB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/photoview-db
  export PHOTOVIEW_DB_PORT=9081
  export PHOTOVIEW_DB_NAME=photoview
  export PHOTOVIEW_DB_USER=photoview
  export PHOTOVIEW_DB_PASSWORD=password

  export DRAWIO_PORT=9092
  export DRAWIO_HTTPS_PORT=9093

  export BITWARDEN_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/bitwarden-server
  export BITWARDEN_PORT=8084
  export BITWARDEN_HTTPS_PORT=8085

  export PHOTOUPLOADER_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/photouploader-server
  export PHOTOUPLOADER_PORT=9003
}

function main() {
  check_requirements
  
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
  ensure_directory_exists "$HOMER_WEB_BASE_DIRECTORY/www/assets"
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

  sed -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    data/homer.yml > "$HOMER_WEB_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/homer-logo.png "$HOMER_WEB_BASE_DIRECTORY/www/assets/logo.png"
  cp -f data/photo-uploader.json "$PHOTOUPLOADER_BASE_DIRECTORY/config/settings.json"

  pushd scripts/pihole-install
  sudo ./syno_pihole.sh --ip 192.168.0.250
  popd

  sudo -E docker-compose up -d --remove-orphans

  sudo -E docker exec tailscale-agent tailscale up --accept-dns=false
}

main
