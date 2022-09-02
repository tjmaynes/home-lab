#!/bin/bash

set -eo pipefail

function check_requirements() {
  throw_if_program_not_present "docker"

  throw_if_env_var_not_present "TIMEZONE" "$TIMEZONE"
  throw_if_env_var_not_present "PUID" "$PUID"
  throw_if_env_var_not_present "PGID" "$PGID"

  throw_if_env_var_not_present "NETWORK_INTERFACE_NAME" "$NETWORK_INTERFACE_NAME"
  throw_if_env_var_not_present "SUBNET_IP_ADDRESS" "$SUBNET_IP_ADDRESS"
  throw_if_env_var_not_present "GATEWAY_IP_ADDRESS" "$GATEWAY_IP_ADDRESS"
  throw_if_env_var_not_present "HOST_IP_ADDRESS" "$HOST_IP_ADDRESS"
  throw_if_env_var_not_present "PROXY_IP_ADDRESS" "$PROXY_IP_ADDRESS"
  throw_if_env_var_not_present "DNS_IP_ADDRESS" "$DNS_IP_ADDRESS"
}

function setup_cronjobs() {
  throw_if_program_not_present "cron"
  throw_if_program_not_present "rsync"

  force_symlink_between_files "$(pwd)/cron.d/onreboot.crontab" "/etc/cron.d/onreboot.crontab"
  force_symlink_between_files "$(pwd)/cron.d/backup.crontab" "/etc/cron.d/backup.crontab"
}

function setup_nfs_media_mount() {
  throw_if_program_not_present "mount"

  throw_if_env_var_not_present "NAS_IP" "$NAS_IP"
  throw_if_env_var_not_present "NAS_MEDIA_DIRECTORY" "$NAS_MEDIA_DIRECTORY"
  throw_if_env_var_not_present "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"

  ensure_directory_exists "$MEDIA_BASE_DIRECTORY"

  mount \
    -t nfs \
    "$NAS_IP:$NAS_MEDIA_DIRECTORY" "$MEDIA_BASE_DIRECTORY" || true

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

  ip link show

  if ! ip link show | grep "$NETWORK_INTERFACE_NAME"; then
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

function setup_tailscale() {
  throw_if_program_not_present "insmod"
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"

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
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "PIHOLE_DOCKER_TAG" "$PIHOLE_DOCKER_TAG"
  throw_if_env_var_not_present "PIHOLE_PASSWORD" "$PIHOLE_PASSWORD"

  export PIHOLE_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/pihole-server
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/pihole"
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/dnsmasq.d"

  ensure_directory_exists "/etc/timezone"
}

function setup_nginx_proxy() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NGINX_SERVER_DOCKER_TAG" "$NGINX_SERVER_DOCKER_TAG"

  export NGNIX_PROXY_MANAGER_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/nginx-proxy-manager-server
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/data"
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/letsencrypt"
}

function setup_nextcloud_server() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NEXTCLOUD_DOCKER_TAG" "$NEXTCLOUD_DOCKER_TAG"
  throw_if_env_var_not_present "NEXTCLOUD_PORT" "$NEXTCLOUD_PORT"

  export NEXTCLOUD_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/nextcloud-server
  ensure_directory_exists "$NEXTCLOUD_BASE_DIRECTORY/www/html"

  throw_if_env_var_not_present "NEXTCLOUD_ADMIN_USER" "$NEXTCLOUD_ADMIN_USER"
  throw_if_env_var_not_present "NEXTCLOUD_ADMIN_PASSWORD" "$NEXTCLOUD_ADMIN_PASSWORD"
  throw_if_env_var_not_present "NEXTCLOUD_DB_USER" "$NEXTCLOUD_DB_USER"
  throw_if_env_var_not_present "NEXTCLOUD_DB_PASSWORD" "$NEXTCLOUD_DB_PASSWORD"
  throw_if_env_var_not_present "NEXTCLOUD_DB_NAME" "$NEXTCLOUD_DB_NAME"

  safely_set_port_for_env_var "NEXTCLOUD_PORT" "18080"
}

function setup_nextcloud_db() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NEXTCLOUD_DB_DOCKER_TAG" "$NEXTCLOUD_DB_DOCKER_TAG"
  throw_if_env_var_not_present "NEXTCLOUD_DB_PORT" "$NEXTCLOUD_DB_PORT"

  export NEXTCLOUD_DB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/nextcloud-db
  ensure_directory_exists "$NEXTCLOUD_DB_BASE_DIRECTORY/data"

  throw_if_env_var_not_present "NEXTCLOUD_DB_USER" "$NEXTCLOUD_DB_USER"
  throw_if_env_var_not_present "NEXTCLOUD_DB_PASSWORD" "$NEXTCLOUD_DB_PASSWORD"

  safely_set_port_for_env_var "NEXTCLOUD_DB_PORT" "15432"
}

function setup_nextcloud_redis() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NEXTCLOUD_REDIS_DOCKER_TAG" "$NEXTCLOUD_REDIS_DOCKER_TAG"
  throw_if_env_var_not_present "NEXTCLOUD_REDIS_PORT" "$NEXTCLOUD_REDIS_PORT"

  export NEXTCLOUD_REDIS_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/nextcloud-redis
  ensure_directory_exists "$NEXTCLOUD_REDIS_BASE_DIRECTORY"

  safely_set_port_for_env_var "NEXTCLOUD_REDIS_PORT" "16379"
}

function setup_nextcloud_collabora() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NEXTCLOUD_COLLABORA_DOCKER_TAG" "$NEXTCLOUD_COLLABORA_DOCKER_TAG"
  throw_if_env_var_not_present "SERVICE_DOMAIN" "$SERVICE_DOMAIN"

  safely_set_port_for_env_var "NEXTCLOUD_COLLABORA_PORT" "19980"

  throw_if_env_var_not_present "NEXTCLOUD_COLLABORA_USERNAME" "$NEXTCLOUD_COLLABORA_USERNAME"
  throw_if_env_var_not_present "NEXTCLOUD_COLLABORA_PASSWORD" "$NEXTCLOUD_COLLABORA_PASSWORD"
}

function setup_nextcloud() {
  setup_nextcloud_db
  setup_nextcloud_redis
  setup_nextcloud_collabora
  setup_nextcloud_server
}

function setup_navidrome() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NAVIDROME_DOCKER_TAG" "$NAVIDROME_DOCKER_TAG"

  export NAVIDROME_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/navidrome-server
  ensure_directory_exists "$NAVIDROME_BASE_DIRECTORY/data"

  safely_set_port_for_env_var "NAVIDROME_PORT" "14533"
}

function setup_plex() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "PLEX_CLAIM_TOKEN" "$PLEX_CLAIM_TOKEN"
  throw_if_env_var_not_present "PLEX_DOCKER_TAG" "$PLEX_DOCKER_TAG"

  export PLEX_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/plex-server
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/config"
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/transcode"
}

function setup_calibre_web() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "CALIBRE_WEB_DOCKER_TAG" "$CALIBRE_WEB_DOCKER_TAG"

  export CALIBRE_WEB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/calibre-web
  ensure_directory_exists "$CALIBRE_WEB_BASE_DIRECTORY/config"

  safely_set_port_for_env_var "CALIBRE_WEB_PORT" "18083"
}

function setup_gogs() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "GOGS_DOCKER_TAG" "$GOGS_DOCKER_TAG"

  export GOGS_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/gogs-web
  ensure_directory_exists "$GOGS_BASE_DIRECTORY/data"

  safely_set_port_for_env_var "GOGS_PORT" "13000"
  safely_set_port_for_env_var "GOGS_SSH_PORT" "12222"

  throw_if_env_var_not_present "GOGS_DB_DOCKER_TAG" "$GOGS_DB_DOCKER_TAG"

  export GOGS_DB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/gogs-db
  ensure_directory_exists "$GOGS_DB_BASE_DIRECTORY"

  export GOGS_USER=gogs
  export GOGS_DB=gogs
  safely_set_port_for_env_var "GOGS_DB_PORT" "15433"
}

function setup_homer() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "SERVICE_DOMAIN" "$SERVICE_DOMAIN"
  throw_if_env_var_not_present "HOMER_DOCKER_TAG" "$HOMER_DOCKER_TAG"

  export HOMER_WEB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/homer-web
  ensure_directory_exists "$HOMER_LOCAL_WEB_BASE_DIRECTORY/www/assets"

  safely_set_port_for_env_var "HOMER_WEB_PORT" "18081"

  sed \
    -e "s/%protocol-type%/https/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    data/homer.template.yml > "$HOMER_WEB_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/homer-logo.png "$HOMER_WEB_BASE_DIRECTORY/www/assets/logo.png"
}

function setup_audiobookshelf() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "AUDIOBOOKSHELF_DOCKER_TAG" "$AUDIOBOOKSHELF_DOCKER_TAG"

  export AUDIOBOOKSHELF_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/audiobookshelf-web
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/config"
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/metadata"

  safely_set_port_for_env_var "AUDIOBOOKSHELF_PORT" "13378"
}

function setup_podgrab() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "PODGRAB_DOCKER_TAG" "$PODGRAB_DOCKER_TAG"

  export PODGRAB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/podgrab-web
  ensure_directory_exists "$PODGRAB_BASE_DIRECTORY/config"

  safely_set_port_for_env_var "PODGRAB_PORT" "18084"
}

function setup_drawio() {
  throw_if_env_var_not_present "DRAWIO_DOCKER_TAG" "$DRAWIO_DOCKER_TAG"

  safely_set_port_for_env_var "DRAWIO_PORT" "18085"
  safely_set_port_for_env_var "DRAWIO_HTTPS_PORT" "18443"
}

function setup_bitwarden() {
  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "BITWARDEN_DOCKER_TAG" "$BITWARDEN_DOCKER_TAG"

  export BITWARDEN_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/bitwarden-server
  ensure_directory_exists "$BITWARDEN_BASE_DIRECTORY/data"

  safely_set_port_for_env_var "BITWARDEN_PORT" "18086"
  safely_set_port_for_env_var "BITWARDEN_HTTPS_PORT" "18444"
}

function setup_home_assistant() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "HOME_ASSISTANT_DOCKER_TAG" "$HOME_ASSISTANT_DOCKER_TAG"

  export HOME_ASSISTANT_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/home-assistant-web
  ensure_directory_exists "$HOME_ASSISTANT_BASE_DIRECTORY/config"

  safely_set_port_for_env_var "HOME_ASSISTANT_PORT" "18123"
}

function setup_nodered() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_env_var_not_present "NODE_RED_DOCKER_TAG" "$NODE_RED_DOCKER_TAG"

  export NODE_RED_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/node-red
  ensure_directory_exists "$NODE_RED_BASE_DIRECTORY/data"

  chmod 777 "$NODE_RED_BASE_DIRECTORY/data"

  safely_set_port_for_env_var "NODE_RED_PORT" "11880"
}

function setup_monitoring() {
  throw_if_directory_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"

  # InfluxDB
  throw_if_env_var_not_present "INFLUXDB_DOCKER_TAG" "$INFLUXDB_DOCKER_TAG"
  throw_if_env_var_not_present "INFLUXDB_ADMIN_USERNAME" "$INFLUXDB_ADMIN_USERNAME"
  throw_if_env_var_not_present "INFLUXDB_ADMIN_PASSWORD" "$INFLUXDB_ADMIN_PASSWORD"

  export INFLUXDB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/monitoring-influxdb
  ensure_directory_exists "$INFLUXDB_BASE_DIRECTORY/data"
  ensure_directory_exists "$INFLUXDB_BASE_DIRECTORY/init"

  safely_set_port_for_env_var "INFLUXDB_PORT" "18089"

  # Telegraf
  throw_if_env_var_not_present "TELEGRAF_DOCKER_TAG" "$INFLUXDB_DOCKER_TAG"

  # Grafana
  throw_if_env_var_not_present "GRAFANA_DOCKER_TAG" "$INFLUXDB_DOCKER_TAG"
  throw_if_env_var_not_present "INFLUXDB_ADMIN_USERNAME" "$INFLUXDB_ADMIN_USERNAME"
  throw_if_env_var_not_present "INFLUXDB_ADMIN_PASSWORD" "$INFLUXDB_ADMIN_PASSWORD"

  export GRAFANA_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/monitoring-grafana
  ensure_directory_exists "${GRAFANA_BASE_DIRECTORY}/var/lib/grafana"
  ensure_directory_exists "${GRAFANA_BASE_DIRECTORY}/provisioning/datasources"

  safely_set_port_for_env_var "GRAFANA_PORT" "18888"
}

function add_influxdb_to_monitoring() {
  curl -X PUT \
    --data-binary '{"name":"GECK","type":"influxdb","url":"http://localhost:18089","access":"proxy","isDefault":true,"database":"geck","user":"${INFLUXDB_ADMIN_USERNAME}","password":"${INFLUXDB_ADMIN_PASSWORD}"}' \
    'http://localhost:18888/api/datasources'
}

function post_install_monitoring() {
  throw_if_env_var_not_present "INFLUXDB_ADMIN_USERNAME" "$INFLUXDB_ADMIN_USERNAME"
  throw_if_env_var_not_present "INFLUXDB_ADMIN_PASSWORD" "$INFLUXDB_ADMIN_PASSWORD"

  docker exec monitoring-inflxudb \
    influx apply -f https://raw.githubusercontent.com/influxdata/community-templates/master/raspberry-pi/raspberry-pi-system.yml

  wait_for_service_to_be_up "http://localhost:18888"

  add_influxdb_to_monitoring
}

function main() {
  source ./scripts/common.sh

  check_requirements

  setup_cronjobs
  setup_nfs_media_mount

  setup_macvlan_network

  setup_tailscale
  setup_pihole
  setup_nginx_proxy
  setup_nextcloud
  # setup_plex
  setup_navidrome
  setup_calibre_web
  setup_gogs
  setup_homer
  setup_audiobookshelf
  setup_podgrab
  setup_drawio
  setup_bitwarden
  setup_home_assistant
  setup_nodered
  setup_monitoring

  docker-compose up -d --remove-orphans

  docker exec tailscale-agent tailscale up \
    --accept-dns=false \
    --advertise-exit-node \
    --advertise-routes=${SUBNET_IP_ADDRESS}/22 \
    --reset

  post_install_monitoring
}

main
