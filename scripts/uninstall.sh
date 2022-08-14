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

function set_environment_variables() {
  if [[ -z "$BASE_DIRECTORY" ]]; then
    echo "Please an environment variable for 'BASE_DIRECTORY' before running this script"
    exit 1
  fi

  export ENVIRONMENT=development
  export TIMEZONE=America/Chicago
  export PUID=$UID
  export PGID=$(sudo id -g)

  export SERVER_HOST="$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
  export ADMIN_PORTAL_PORT=5000

  export MEDIA_DIRECTORY=${BASE_DIRECTORY}/media
  export BOOKS_DIRECTORY=${MEDIA_DIRECTORY}/Books
  export AUDIOBOOKS_DIRECTORY=${MEDIA_DIRECTORY}/Audiobooks
  export PODCASTS_DIRECTORY=${MEDIA_DIRECTORY}/Podcasts

  export PLEX_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/plex-server
  export PLEX_PORT=32400

  export CALIBRE_WEB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/calibre-web
  export CALIBRE_WEB_PORT=8083

  export GOGS_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/gogs-web
  export GOGS_PORT=3000
  export GOGS_SSH_PORT=222
  export GOGS_USER=gogs
  export GOGS_DATABASE=gogs
  export GOGS_DATABASE_PASSWORD=gogs
  export GOGS_DATABASE_PORT=5433
  export GOGS_DATABASE_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/gogs-db

  export HOME_ASSISTANT_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/home-assistant-web
  export HOME_ASSISTANT_PORT=8123

  export HOMER_WEB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/homer-web
  export HOMER_WEB_PORT=8080

  export TAILSCALE_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/tailscale-agent

  export AUDIOBOOKSHELF_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/audiobookshelf-web
  export AUDIOBOOKSHELF_PORT=13378

  export PODGRAB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/podgrab-web
  export PODGRAB_PORT=8098

  export NODE_RED_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/node-red
  export NODE_RED_PORT=1880
}

function main() {
  check_requirements

  set_environment_variables

  sudo -E docker-compose down
}

main