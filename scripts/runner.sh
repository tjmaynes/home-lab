#!/bin/bash

set -eo pipefail

RUN_TYPE=$1

USED_PORTS=$(lsof -i -n -P | awk '{print $9}' | grep ':' | cut -d ":" -f 2 | sort | uniq | grep -v '\->' | grep -v '*')
function safely_set_port_for_env_var() {
  ENV_VAR_KEY=$1
  NEW_PORT=$2

  if [[ -z "$ENV_VAR_KEY" ]]; then
    echo "safely_set_port_for_env_var: Please pass an environment variable key as first argument"
    exit 1
  elif [[ -z "$NEW_PORT" ]]; then
    echo "safely_set_port_for_env_var: Please pass a valid port as second argument"
    exit 1
  fi

  if echo $USED_PORTS | grep -w -q "$NEW_PORT"; then
    echo "Port '$NEW_PORT' for '$ENV_VAR_KEY' is already in use! Please choose another port to set for '$ENV_VAR_KEY'."
    exit 1
  fi

  USED_PORTS+=($NEW_PORT)

  export $1=$2
}

function ensure_directory_exists() {
  TARGET_DIRECTORY=$1

  if [[ ! -d "$TARGET_DIRECTORY" ]]; then
    echo "Creating $TARGET_DIRECTORY directory..."
    mkdir -p "$TARGET_DIRECTORY"
  fi
}

function throw_if_program_not_present() {
  if [[ -z "$(command -v $1)" ]]; then
    echo "Please install '$1' before running this script"
    exit 1
  fi
}

function throw_if_env_var_not_present() {
  ENV_VAR_KEY=$1
  ENV_VAR_VALUE=$2

  if [[ -z "$ENV_VAR_VALUE" ]]; then
    echo "Please set an environment variable for '$ENV_VAR_KEY' before running this script"
    exit 1
  fi
}

function throw_if_directory_not_present() {
  DIRECTORY_ENV_VAR_KEY=$1
  DIRECTORY_ENV_VAR_VALUE=$2

  throw_if_env_var_not_present "$DIRECTORY_ENV_VAR_KEY" "$DIRECTORY_ENV_VAR_VALUE"

  if [[ ! -d "$DIRECTORY_ENV_VAR_VALUE" ]]; then
    echo "Please create a directory ($DIRECTORY_ENV_VAR_VALUE) for environment variable '$DIRECTORY_ENV_VAR_KEY' before running this script"
    exit 1
  fi
}

function check_requirements() {
  throw_if_program_not_present "docker"

  throw_if_env_var_not_present "RUN_TYPE" "$RUN_TYPE"

  throw_if_env_var_not_present "TIMEZONE" "$TIMEZONE"
  throw_if_env_var_not_present "PUID" "$PUID"
  throw_if_env_var_not_present "PGID" "$PGID"

  throw_if_env_var_not_present "NETWORK_INTERFACE_NAME" "$NETWORK_INTERFACE_NAME"
  throw_if_env_var_not_present "SUBNET_IP_ADDRESS" "$SUBNET_IP_ADDRESS"
  throw_if_env_var_not_present "GATEWAY_IP_ADDRESS" "$GATEWAY_IP_ADDRESS"
  throw_if_env_var_not_present "HOST_IP_ADDRESS" "$HOST_IP_ADDRESS"
  throw_if_env_var_not_present "PROXY_IP_ADDRESS" "$PROXY_IP_ADDRESS"
  throw_if_env_var_not_present "DNS_IP_ADDRESS" "$DNS_IP_ADDRESS"

  throw_if_directory_not_present "VIDEOS_DIRECTORY" "$VIDEOS_DIRECTORY"
  throw_if_directory_not_present "MUSIC_DIRECTORY" "$MUSIC_DIRECTORY"
  throw_if_directory_not_present "PHOTOS_DIRECTORY" "$PHOTOS_DIRECTORY"
  throw_if_directory_not_present "BOOKS_DIRECTORY" "$BOOKS_DIRECTORY"
  throw_if_directory_not_present "AUDIOBOOKS_DIRECTORY" "$AUDIOBOOKS_DIRECTORY"
  throw_if_directory_not_present "PODCASTS_DIRECTORY" "$PODCASTS_DIRECTORY"
}

function setup_macvlan_network() {
  throw_if_program_not_present "ip"
  throw_if_env_var_not_present "NETWORK_INTERFACE_NAME" "$NETWORK_INTERFACE_NAME"
  throw_if_env_var_not_present "HOST_IP_ADDRESS" "$HOST_IP_ADDRESS"
  throw_if_env_var_not_present "PROXY_IP_ADDRESS" "$PROXY_IP_ADDRESS"

  if ! ip link show | grep "NETWORK_INTERFACE_NAME"; then
    echo "Please create a virtual network for '$NETWORK_INTERFACE_NAME' before running this script"
    exit 1
  fi

  if ! ip link show | grep "macvlan0"; then
    ip link add macvlan0 link "$NETWORK_INTERFACE_NAME" type macvlan mode bridge
    ip addr add $HOST_IP_ADDRESS/32 dev macvlan0
    ip link set macvlan0 up
    ip route add $PROXY_IP_ADDRESS dev macvlan0
  fi
}

function teardown_macvlan() {
  throw_if_program_not_present "ip"

  if ip link show | grep "macvlan0"; then
    ip link set macvlan0 down
    ip link delete macvlan0
  fi
}

function setup_tailscale() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"

  export TAILSCALE_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/tailscale-agent
  ensure_directory_exists "$TAILSCALE_BASE_DIRECTORY/var/lib"

  if [[ ! -c "/dev/net/tun" ]]; then
    if [[ ! -d "/dev/net" ]]; then
      mkdir -m 755 /dev/net
    fi

    mknod /dev/net/tun c 10 200
    chmod 0755 /dev/net/tun
  fi

  if ( !(lsmod | grep -q "^tun\s") ); then
    insmod /lib/modules/tun.ko
  fi
}

function setup_pihole() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "PIHOLE_DOCKER_TAG" "$PIHOLE_DOCKER_TAG"
  throw_if_env_var_not_present "PIHOLE_PASSWORD" "$PIHOLE_PASSWORD"

  export PIHOLE_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/pihole-server
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/pihole"
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/dnsmasq.d"
}

function setup_nginx_proxy() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NGINX_SERVER_DOCKER_TAG" "$NGINX_SERVER_DOCKER_TAG"

  export NGNIX_PROXY_MANAGER_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/nginx-proxy-manager-server
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/data"
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/letsencrypt"
}

function setup_navidrome() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NAVIDROME_DOCKER_TAG" "$NAVIDROME_DOCKER_TAG"

  export NAVIDROME_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/navidrome-server
  ensure_directory_exists "$NAVIDROME_BASE_DIRECTORY/data"
}

function setup_plex() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "PLEX_CLAIM_TOKEN" "$PLEX_CLAIM_TOKEN"
  throw_if_env_var_not_present "PLEX_DOCKER_TAG" "$PLEX_DOCKER_TAG"

  export PLEX_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/plex-server
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/config"
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/transcode"
}

function setup_calibre_web() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "CALIBRE_WEB_DOCKER_TAG" "$CALIBRE_WEB_DOCKER_TAG"

  export CALIBRE_WEB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/calibre-web
  ensure_directory_exists "$CALIBRE_WEB_BASE_DIRECTORY/config"

  safely_set_port_for_env_var "CALIBRE_WEB_PORT" "8083"
}

function setup_gogs() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "GOGS_DOCKER_TAG" "$GOGS_DOCKER_TAG"

  export GOGS_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/gogs-web
  ensure_directory_exists "$GOGS_BASE_DIRECTORY/data"

  safely_set_port_for_env_var "GOGS_PORT" "3000"
  safely_set_port_for_env_var "GOGS_SSH_PORT" "2222"

  throw_if_env_var_not_present "GOGS_DB_DOCKER_TAG" "$GOGS_DB_DOCKER_TAG"

  export GOGS_DB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/gogs-db
  ensure_directory_exists "$GOGS_DB_BASE_DIRECTORY"

  export GOGS_USER=gogs
  export GOGS_DB=gogs
  export GOGS_DB_PASSWORD=gogs
  safely_set_port_for_env_var "GOGS_DB_PORT" "5433"
}

function setup_home_assistant() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "HOME_ASSISTANT_DOCKER_TAG" "$HOME_ASSISTANT_DOCKER_TAG"

  export HOME_ASSISTANT_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/home-assistant-web
  ensure_directory_exists "$HOME_ASSISTANT_BASE_DIRECTORY/config"

  safely_set_port_for_env_var "HOME_ASSISTANT_PORT" "8123"
}

function setup_nodered() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NODE_RED_DOCKER_TAG" "$NODE_RED_DOCKER_TAG"

  export NODE_RED_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/node-red
  ensure_directory_exists "$NODE_RED_BASE_DIRECTORY/data"

  chmod 777 "$NODE_RED_BASE_DIRECTORY/data"

  safely_set_port_for_env_var "NODE_RED_PORT" "1880"
}

function setup_remote_homer() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "SERVICE_DOMAIN" "$SERVICE_DOMAIN"
  throw_if_env_var_not_present "HOMER_DOCKER_TAG" "$HOMER_DOCKER_TAG"

  export HOMER_REMOTE_WEB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/homer-remote-web
  ensure_directory_exists "$HOMER_LOCAL_WEB_BASE_DIRECTORY/www/assets"

  safely_set_port_for_env_var "HOMER_REMOTE_WEB_PORT" "8081"

  sed \
    -e "s/%protocol-type%/https/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    data/homer.template.yml > "$HOMER_REMOTE_WEB_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/homer-logo.png "$HOMER_REMOTE_WEB_BASE_DIRECTORY/www/assets/logo.png"
}

function setup_local_homer() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "SERVICE_DOMAIN" "$SERVICE_DOMAIN"
  throw_if_env_var_not_present "HOMER_DOCKER_TAG" "$HOMER_DOCKER_TAG"

  export HOMER_LOCAL_WEB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/homer-local-web
  ensure_directory_exists "$HOMER_REMOTE_WEB_BASE_DIRECTORY/www/assets"

  safely_set_port_for_env_var "HOMER_LOCAL_WEB_PORT" "8080"

  sed \
    -e "s/%protocol-type%/http/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    data/homer.template.yml > "$HOMER_LOCAL_WEB_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/homer-logo.png "$HOMER_LOCAL_WEB_BASE_DIRECTORY/www/assets/logo.png"
}

function setup_audiobookshelf() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "AUDIOBOOKSHELF_DOCKER_TAG" "$AUDIOBOOKSHELF_DOCKER_TAG"

  export AUDIOBOOKSHELF_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/audiobookshelf-web
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/config"
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/metadata"

  safely_set_port_for_env_var "AUDIOBOOKSHELF_PORT" "13378"
}

function setup_podgrab() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "PODGRAB_DOCKER_TAG" "$PODGRAB_DOCKER_TAG"

  export PODGRAB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/podgrab-web
  ensure_directory_exists "$PODGRAB_BASE_DIRECTORY/config"

  safely_set_port_for_env_var "PODGRAB_PORT" "9087"
}

function setup_photoviewer() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "PHOTOVIEWER_DOCKER_TAG" "$PHOTOVIEWER_DOCKER_TAG" 

  export PHOTOVIEWER_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/photoviewer-server
  ensure_directory_exists "$PHOTOVIEWER_BASE_DIRECTORY/cache"

  safely_set_port_for_env_var "PHOTOVIEWER_PORT" "9080"

  export PHOTOVIEWER_DB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/photoviewer-db
  ensure_directory_exists "$PHOTOVIEWER_DB_BASE_DIRECTORY"
  throw_if_env_var_not_present "PHOTOVIEWER_DB_DOCKER_TAG" "$PHOTOVIEWER_DB_DOCKER_TAG"

  export PHOTOVIEWER_DB_NAME=photoview
  export PHOTOVIEWER_DB_USER=photoview
  export PHOTOVIEWER_DB_PASSWORD=password

  safely_set_port_for_env_var "PHOTOVIEWER_DB_PORT" "9081"
}

function setup_photouploader() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "PHOTOUPLOADER_DOCKER_TAG" "$PHOTOUPLOADER_DOCKER_TAG"

  export PHOTOUPLOADER_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/photouploader-server
  ensure_directory_exists "$PHOTOUPLOADER_BASE_DIRECTORY/config"
  ensure_directory_exists "$PHOTOUPLOADER_BASE_DIRECTORY/database"

  touch "$PHOTOUPLOADER_BASE_DIRECTORY/database/filebrowser.db"

  safely_set_port_for_env_var "PHOTOUPLOADER_PORT" "9003"

  cp -f data/photo-uploader.json "$PHOTOUPLOADER_BASE_DIRECTORY/config/settings.json"
}

function setup_drawio() {
  throw_if_env_var_not_present "DRAWIO_DOCKER_TAG" "$DRAWIO_DOCKER_TAG"

  safely_set_port_for_env_var "DRAWIO_PORT" "9092"
  safely_set_port_for_env_var "DRAWIO_HTTPS_PORT" "9093"
}

function setup_bitwarden() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "BITWARDEN_DOCKER_TAG" "$BITWARDEN_DOCKER_TAG"

  export BITWARDEN_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/bitwarden-server
  ensure_directory_exists "$BITWARDEN_BASE_DIRECTORY/data"

  safely_set_port_for_env_var "BITWARDEN_PORT" "8084"
  safely_set_port_for_env_var "BITWARDEN_HTTPS_PORT" "8085"
}

function start_apps() {
  setup_macvlan_network

  setup_tailscale
  setup_pihole
  setup_nginx_proxy
  setup_navidrome
  # setup_plex
  setup_calibre_web
  setup_gogs
  setup_home_assistant
  setup_nodered
  setup_remote_homer
  setup_local_homer
  setup_audiobookshelf
  setup_podgrab
  setup_photoviewer
  setup_photouploader
  setup_drawio
  setup_bitwarden

  docker-compose up -d --remove-orphans

  docker exec tailscale-agent tailscale up \
    --accept-dns=false \
    --advertise-exit-node \
    --advertise-routes=${SUBNET_IP_ADDRESS}/22 \
    --reset
}

function stop_apps() {
  docker-compose down

  teardown_macvlan
}

function main() {
  check_requirements

  case "$RUN_TYPE" in
    "start")
      start_apps
      ;;
    "stop")
      stop_apps
      ;;
    *)
      echo "Unable to run kratos script with parameter 1 '$RUN_TYPE'."
      exit 1
      ;;
  esac

  echo "Done!"
}

main