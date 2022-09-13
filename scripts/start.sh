#!/usr/bin/env bash

set -e
set -x

function check_requirements() {
  throw_if_program_not_present "docker"

  throw_if_env_var_not_present "TIMEZONE" "$TIMEZONE"
  throw_if_env_var_not_present "PUID" "$PUID"
  throw_if_env_var_not_present "PGID" "$PGID"

  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
}

function setup_macvlan_network() {
  add_step "Setting up macvlan network"

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

function setup_pihole() {
  add_step "Setting up pihole"

  throw_if_env_var_not_present "DNS_IP_ADDRESS" "$DNS_IP_ADDRESS"
  throw_if_env_var_not_present "PIHOLE_PASSWORD" "$PIHOLE_PASSWORD"

  export PIHOLE_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/pihole-server
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/pihole"
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/dnsmasq.d"

  ensure_directory_exists "/etc/timezone"
}

function setup_nginx_proxy() {
  throw_if_env_var_not_present "PROXY_IP_ADDRESS" "$PROXY_IP_ADDRESS"

  export NGNIX_PROXY_MANAGER_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/nginx-proxy-manager-server
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/data"
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/letsencrypt"
}

function setup_tailscale() {
  add_step "Setting up tailscale"

  throw_if_program_not_present "insmod"
  throw_if_program_not_present "lsmod"

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
    uname -r
    find /lib/modules/$(uname -r) -name tun.ko -exec file {} \;
    TUN_LOCATION=$(find /lib/modules/$(uname -r) -name tun.ko -exec file {} \;)
    echo $TUN_LOCATION
    insmod $TUN_LOCATION
  fi
}

function setup_duplicati_web() {
  add_step "Setting up duplicati"

  export DUPLICATI_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/duplicai-web
  ensure_directory_exists "$DUPLICATI_BASE_DIRECTORY/config"
}

function setup_plex() {
  add_step "Setting up plex"

  throw_if_env_var_not_present "PLEX_CLAIM_TOKEN" "$PLEX_CLAIM_TOKEN"

  export PLEX_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/plex-server
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/config"
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/transcode"
}

function setup_navidrome() {
  add_step "Setting up navidrome"

  export NAVIDROME_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/navidrome-server
  ensure_directory_exists "$NAVIDROME_BASE_DIRECTORY/data"
}

function setup_calibre_web() {
  add_step "Setting up calibre-web"

  export CALIBRE_WEB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/calibre-web
  ensure_directory_exists "$CALIBRE_WEB_BASE_DIRECTORY/config"
}

function setup_gogs() {
  add_step "Setting up gogs"

  export GOGS_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/gogs-web
  ensure_directory_exists "$GOGS_BASE_DIRECTORY/data"

  export GOGS_DB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/gogs-db
  ensure_directory_exists "$GOGS_DB_BASE_DIRECTORY"
}

function setup_homer() {
  add_step "Setting up homer"

  throw_if_env_var_not_present "SERVICE_DOMAIN" "$SERVICE_DOMAIN"

  export HOMER_WEB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/homer-web
  ensure_directory_exists "$HOMER_LOCAL_WEB_BASE_DIRECTORY/www/assets"

  sed \
    -e "s/%protocol-type%/https/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    data/homer.template.yml > "$HOMER_WEB_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/homer-logo.png "$HOMER_WEB_BASE_DIRECTORY/www/assets/logo.png"
}

function setup_audiobookshelf() {
  add_step "Setting up audiobookshelf"

  export AUDIOBOOKSHELF_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/audiobookshelf-web
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/config"
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/metadata"
}

function setup_podgrab() {
  add_step "Setting up podgrab"

  export PODGRAB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/podgrab-web
  ensure_directory_exists "$PODGRAB_BASE_DIRECTORY/config"
}

function setup_bitwarden() {
  add_step "Setting up bitwarden"

  export BITWARDEN_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/bitwarden-server
  ensure_directory_exists "$BITWARDEN_BASE_DIRECTORY/data"
}

function setup_monitoring() {
  add_step "Setting up monitoring"

  # InfluxDB
  throw_if_env_var_not_present "INFLUXDB_ADMIN_USERNAME" "$INFLUXDB_ADMIN_USERNAME"
  throw_if_env_var_not_present "INFLUXDB_ADMIN_PASSWORD" "$INFLUXDB_ADMIN_PASSWORD"

  export INFLUXDB_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/monitoring-influxdb
  ensure_directory_exists "$INFLUXDB_BASE_DIRECTORY/data"
  ensure_directory_exists "$INFLUXDB_BASE_DIRECTORY/init"

  # Grafana
  throw_if_env_var_not_present "INFLUXDB_ADMIN_USERNAME" "$INFLUXDB_ADMIN_USERNAME"
  throw_if_env_var_not_present "INFLUXDB_ADMIN_PASSWORD" "$INFLUXDB_ADMIN_PASSWORD"

  export GRAFANA_BASE_DIRECTORY=${DOCKER_BASE_DIRECTORY}/monitoring-grafana
  ensure_directory_exists "${GRAFANA_BASE_DIRECTORY}/var/lib/grafana"
  ensure_directory_exists "${GRAFANA_BASE_DIRECTORY}/provisioning/datasources"
}

function add_influxdb_to_monitoring() {
  curl -X PUT \
    --data-binary '{"name":"Zeus","type":"influxdb","url":"http://localhost:18089","access":"proxy","isDefault":true,"database":"zeus","user":"${INFLUXDB_ADMIN_USERNAME}","password":"${INFLUXDB_ADMIN_PASSWORD}"}' \
    'http://localhost:18888/api/datasources'
}

function post_install_monitoring() {
  add_step "Running post intstall - monitoring"

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

  setup_macvlan_network

  setup_tailscale
  setup_pihole
  setup_nginx_proxy
  setup_plex
  setup_navidrome
  setup_calibre_web
  setup_gogs
  setup_homer
  setup_audiobookshelf
  setup_podgrab
  setup_bitwarden
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
