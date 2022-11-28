#!/usr/bin/env bash

set -e

RUN_TYPE=$1

function check_requirements() {
  throw_if_program_not_present "docker"

  throw_if_env_var_not_present "TIMEZONE" "$TIMEZONE"
  throw_if_env_var_not_present "PUID" "$PUID"
  throw_if_env_var_not_present "PGID" "$PGID"

  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
}

function setup_firewall() {
  add_step "Setting up firewall"

  ensure_program_installed "ufw"

  ufw default allow outgoing
  ufw default deny incoming

  OPEN_PORTS=(22/tcp 80/tcp 443/tcp)
  for port in "${OPEN_PORTS[@]}"; do
    ufw allow "$port"
  done

  ufw --force enable
}

function setup_nfs_media_mount() {
  add_step "Setting up NFS mounts"

  throw_if_program_not_present "mount"

  throw_if_env_var_not_present "NAS_MEDIA_DIRECTORY" "$NAS_MEDIA_DIRECTORY"
  throw_if_env_var_not_present "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"

  ensure_directory_exists "$MEDIA_BASE_DIRECTORY"

  setup_nas_mount "$NAS_MEDIA_DIRECTORY" "$MEDIA_BASE_DIRECTORY"

  throw_if_directory_not_present "VIDEOS_DIRECTORY" "$VIDEOS_DIRECTORY"
  throw_if_directory_not_present "MUSIC_DIRECTORY" "$MUSIC_DIRECTORY"
  throw_if_directory_not_present "PHOTOS_DIRECTORY" "$PHOTOS_DIRECTORY"
  throw_if_directory_not_present "BOOKS_DIRECTORY" "$BOOKS_DIRECTORY"
  throw_if_directory_not_present "AUDIOBOOKS_DIRECTORY" "$AUDIOBOOKS_DIRECTORY"
  throw_if_directory_not_present "PODCASTS_DIRECTORY" "$PODCASTS_DIRECTORY"
  throw_if_directory_not_present "DOWNLOADS_DIRECTORY" "$DOWNLOADS_DIRECTORY"
}

function setup_cloudflare_tunnel() {
  add_step "Setting up cloudflare-tunnel"

  throw_if_env_var_not_present "CLOUDFLARE_BASE_DIRECTORY" "$CLOUDFLARE_BASE_DIRECTORY"
  ensure_directory_exists "$CLOUDFLARE_BASE_DIRECTORY/.cloudflared"
  throw_if_env_var_not_present "CLOUDFLARE_TUNNEL_UUID" "$CLOUDFLARE_TUNNEL_UUID"

  CLOUDFLARE_CREDENTIALS_FILE="$CLOUDFLARE_BASE_DIRECTORY/.cloudflared/$CLOUDFLARE_TUNNEL_UUID.json"
  CLOUDFLARE_CREDENTIALS_FILE=$(echo "$CLOUDFLARE_CREDENTIALS_FILE" | sed 's/\//\\\//g')

  sed \
    -e "s/%cloudflare-tunnel-uuid%/${CLOUDFLARE_TUNNEL_UUID}/g" \
    -e "s/%cloudflare-credentials-file%/${CLOUDFLARE_CREDENTIALS_FILE}/g" \
    -e "s/%hostname%/${NONROOT_USER}/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    static/templates/cloudflare.template.yml > "$CLOUDFLARE_BASE_DIRECTORY/config.yaml"

  sysctl -w net.core.rmem_max=2500000 &> /dev/null

  install_cloudflared "$CLOUDFLARED_VERSION"
}

function setup_nginx_proxy() {
  add_step "Setting up nginx-proxy"

  throw_if_env_var_not_present "NGNIX_PROXY_MANAGER_BASE_DIRECTORY" "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY"

  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/data"
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/letsencrypt"

  if ! docker network ls | grep "proxy_network" &> /dev/null; then
    docker network create proxy_network
  fi
}

function setup_homer() {
  add_step "Setting up homer"

  throw_if_env_var_not_present "SERVICE_DOMAIN" "$SERVICE_DOMAIN"

  throw_if_env_var_not_present "HOMER_BASE_DIRECTORY" "$HOMER_BASE_DIRECTORY"

  ensure_directory_exists "$HOMER_BASE_DIRECTORY/www/assets"

  sed \
    -e "s/%protocol-type%/https/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    static/templates/homer.template.yml > "$HOMER_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/images/logo.webp "$HOMER_BASE_DIRECTORY/www/assets/logo.webp"
}

function setup_pihole() {
  add_step "Setting up pihole"

  throw_if_file_not_present "/etc/timezone"

  throw_if_env_var_not_present "PIHOLE_PASSWORD" "$PIHOLE_PASSWORD"
  throw_if_env_var_not_present "HOST_INTERFACE_NAME" "$HOST_INTERFACE_NAME"

  throw_if_env_var_not_present "PIHOLE_BASE_DIRECTORY" "$PIHOLE_BASE_DIRECTORY"
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/pihole"
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/dnsmasq.d"

  if ! docker network ls | grep "pihole_network" &> /dev/null; then
    docker network create -d macvlan \
      -o parent=${HOST_INTERFACE_NAME} \
      --subnet 192.168.5.0/22 \
      --gateway 192.168.5.1 \
      --ip-range 192.168.5.200/32 \
      --aux-address 'host=192.168.5.210' \
      pihole_network
  fi
}

function setup_plex_server() {
  add_step "Setting up plex-server"

  throw_if_env_var_not_present "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"
  throw_if_env_var_not_present "PLEX_CLAIM_TOKEN" "$PLEX_CLAIM_TOKEN"

  throw_if_env_var_not_present "PLEX_BASE_DIRECTORY" "$PLEX_BASE_DIRECTORY"
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/config"
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/transcode"

  if [[ ! -f "/etc/ufw/applications.d/plexmediaserver" ]]; then
    tee -a /etc/ufw/applications.d/plexmediaserver &> /dev/null <<EOF
[plexmediaserver]
title=Plex Media Server (Standard)
description=The Plex Media Server
ports=32400/tcp|3005/tcp|5353/udp|8324/tcp|32410:32414/udp

[plexmediaserver-dlna]
title=Plex Media Server (DLNA)
description=The Plex Media Server (additional DLNA capability only)
ports=1900/udp|32469/tcp

[plexmediaserver-all]
title=Plex Media Server (Standard + DLNA)
description=The Plex Media Server (with additional DLNA capability)
ports=32400/tcp|3005/tcp|5353/udp|8324/tcp|32410:32414/udp|1900/udp|32469/tcp
EOF
  fi

  ufw app update plexmediaserver

  ufw allow plexmediaserver-all
}

function setup_calibre_web() {
  add_step "Setting up calibre-web"

  throw_if_env_var_not_present "CALIBRE_WEB_BASE_DIRECTORY" "$CALIBRE_WEB_BASE_DIRECTORY"

  ensure_directory_exists "$CALIBRE_WEB_BASE_DIRECTORY/config"
}

function setup_pigallary_web() {
  add_step "Setting up pi-gallery"

  throw_if_directory_not_present "PHOTOS_DIRECTORY" "$PHOTOS_DIRECTORY"

  throw_if_env_var_not_present "PIGALLERY_BASE_DIRECTORY" "$PIGALLERY_BASE_DIRECTORY"

  ensure_directory_exists "$PIGALLERY_BASE_DIRECTORY/config"
  ensure_directory_exists "$PIGALLERY_BASE_DIRECTORY/db"
  ensure_directory_exists "$PIGALLERY_BASE_DIRECTORY/tmp"
}

function setup_audiobookshelf() {
  add_step "Setting up audiobookshelf"

  throw_if_env_var_not_present "AUDIOBOOKSHELF_BASE_DIRECTORY" "$AUDIOBOOKSHELF_BASE_DIRECTORY"

  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/config"
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/metadata"
}

function setup_miniflux_web() {
  add_step "Setting up miniflux-web"

  throw_if_env_var_not_present "MINIFLUX_DB_USERNAME" "$MINIFLUX_DB_USERNAME"
  throw_if_env_var_not_present "MINIFLUX_DB_PASSWORD" "$MINIFLUX_DB_PASSWORD"
  throw_if_env_var_not_present "MINIFLUX_ADMIN_USERNAME" "$MINIFLUX_ADMIN_USERNAME"
  throw_if_env_var_not_present "MINIFLUX_ADMIN_PASSWORD" "$MINIFLUX_ADMIN_PASSWORD"

  throw_if_env_var_not_present "MINIFLUX_DB_BASE_DIRECTORY" "$MINIFLUX_DB_BASE_DIRECTORY"
  ensure_directory_exists "$MINIFLUX_DB_BASE_DIRECTORY"
}

function setup_code_server() {
  add_step "Setting up code-server"

  throw_if_env_var_not_present "CODE_SERVER_PASSWORD" "$CODE_SERVER_PASSWORD"
  throw_if_env_var_not_present "CODE_SERVER_SUDO_PASSWORD" "$CODE_SERVER_SUDO_PASSWORD"

  throw_if_env_var_not_present "CODE_SERVER_BASE_DIRECTORY" "$CODE_SERVER_BASE_DIRECTORY"
  ensure_directory_exists "$CODE_SERVER_BASE_DIRECTORY"
}

function setup_codimd() {
  add_step "Setting up codimd"

  throw_if_env_var_not_present "CODIMD_DB_URL" "$CODIMD_DB_URL"

  throw_if_env_var_not_present "CODIMD_BASE_DIRECTORY" "$CODIMD_BASE_DIRECTORY"
  ensure_directory_exists "$CODIMD_BASE_DIRECTORY/uploads"

  throw_if_env_var_not_present "CODIMD_DB_BASE_DIRECTORY" "$CODIMD_DB_BASE_DIRECTORY"
  ensure_directory_exists "$CODIMD_DB_BASE_DIRECTORY/data"

  throw_if_env_var_not_present "CODIMD_DB_USERNAME" "$CODIMD_DB_USERNAME"
  throw_if_env_var_not_present "CODIMD_DB_PASSWORD" "$CODIMD_DB_PASSWORD"
}

function setup_gogs() {
  add_step "Setting up gogs"

  throw_if_env_var_not_present "GOGS_BASE_DIRECTORY" "$GOGS_BASE_DIRECTORY"
  ensure_directory_exists "$GOGS_BASE_DIRECTORY/data"
}

function setup_podgrab() {
  add_step "Setting up podgrab"

  throw_if_env_var_not_present "PODGRAB_BASE_DIRECTORY" "$PODGRAB_BASE_DIRECTORY"
  ensure_directory_exists "$PODGRAB_BASE_DIRECTORY/config"
}

function setup_youtube_downloader() {
  add_step "Setting up youtube-downloader"

  throw_if_directory_not_present "DOWNLOADS_DIRECTORY" "$DOWNLOADS_DIRECTORY"
  mkdir -p "$DOWNLOADS_DIRECTORY/youtube"
}

function setup_home_assistant() {
  add_step "Setting up home assistant"

  throw_if_env_var_not_present "HOME_ASSISTANT_BASE_DIRECTORY" "$HOME_ASSISTANT_BASE_DIRECTORY"

  ensure_directory_exists "$HOME_ASSISTANT_BASE_DIRECTORY/config"
}

function setup_nodered() {
  add_step "Setting up nodered"

  throw_if_env_var_not_present "NODERED_BASE_DIRECTORY" "$NODERED_BASE_DIRECTORY"

  ensure_directory_exists "$NODERED_BASE_DIRECTORY/data"
}

function setup_grafana_agent() {
  add_step "Setting up grafana-agent"

  throw_if_env_var_not_present "GRAFANA_AGENT_BASE_DIRECTORY" "$GRAFANA_AGENT_BASE_DIRECTORY"
  ensure_directory_exists "${GRAFANA_AGENT_BASE_DIRECTORY}/data"

  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"
  throw_if_env_var_not_present "GRAFANA_USERNAME" "$GRAFANA_USERNAME"
  throw_if_env_var_not_present "GRAFANA_API_KEY" "$GRAFANA_API_KEY"
  throw_if_env_var_not_present "LOKI_URI" "$LOKI_URI"

  if [[ ! -f "${GRAFANA_AGENT_BASE_DIRECTORY}/agent.yaml" ]]; then
    tee -a "${GRAFANA_AGENT_BASE_DIRECTORY}/agent.yaml" <<EOF
metrics:
  wal_directory: /tmp/grafana-agent/wal
  global:
    scrape_interval: 1m
    remote_write:
      - url: https://prometheus-prod-10-prod-us-central-0.grafana.net/api/prom/push
        basic_auth:
          username: ${GRAFANA_USERNAME}
          password: ${GRAFANA_API_KEY}

integrations:
  node_exporter:
    enabled: true
    relabel_configs:
    - replacement: hostname
      source_labels:
      - __address__
      target_label: instance

    rootfs_path: /
    sysfs_path: /sys
    procfs_path: /proc

logs:
  positions_directory: /tmp/grafana-positions
  configs: 
  - name: integrations
    scrape_configs:
    - job_name: integrations/node_exporter_direct_scrape
      static_configs:
      - targets:
          - localhost
        labels:
          instance: hostname
          __path__: /var/log/{syslog,messages,*.log}
          job: integrations/node_exporter

    - job_name: integrations/node_exporter_journal_scrape
      journal:
        max_age: 24h
        labels:
          instance: hostname
          job: integrations/node_exporter
      relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: 'unit'
      - source_labels: ['__journal__boot_id']
        target_label: 'boot_id'
      - source_labels: ['__journal__transport']
        target_label: 'transport'

  - name: scrape-docker
    target_config:
      sync_period: 10s
    scrape_configs:
    - job_name: integrations/docker
      docker_sd_configs:
        - host: unix:///var/run/docker.sock
          refresh_interval: 5s
      relabel_configs:
        - source_labels: ['__meta_docker_container_name']
          regex: '/(.*).[0-9]\..*'
          target_label: 'name'
        - source_labels: ['__meta_docker_container_name']
          regex: '/(.*).[0-9a-z]*\..*'
          target_label: 'name'
        - source_labels: ['__meta_docker_container_name']
          regex: '/.*.([0-9]{1,2})\..*'
          target_label: 'replica'
        - action: replace
          replacement: integrations/docker
          source_labels: ['__meta_docker_container_id']
          target_label: job
        - source_labels: ['__meta_docker_container_name']
          regex: '/(.*)'
          target_label: container
        - source_labels: ['__meta_docker_container_log_stream']
          target_label: stream
EOF
  fi
}

function setup_promtail_agent() {
  add_step "Setting up promtail-agent"

  throw_if_env_var_not_present "NONROOT_USER" "${NONROOT_USER}"
  throw_if_env_var_not_present "PROMTAIL_AGENT_BASE_DIRECTORY" "$PROMTAIL_AGENT_BASE_DIRECTORY"

  ensure_directory_exists "$PROMTAIL_AGENT_BASE_DIRECTORY"

  if [[ ! -f "${PROMTAIL_AGENT_BASE_DIRECTORY}/config.yaml" ]]; then
    tee -a "${PROMTAIL_AGENT_BASE_DIRECTORY}/config.yaml" <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: ${LOKI_URI}

scrape_configs:
- job_name: system-logs
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*log

- job_name: scrape-containers
  docker_sd_configs:
    - host: unix:///var/run/docker.sock
      refresh_interval: 5s
  relabel_configs:
    - source_labels: ['__meta_docker_container_name']
      regex: '/(.*)\.[0-9]\..*'
      target_label: 'name'
    - source_labels: ['__meta_docker_container_name']
      regex: '/(.*)\.[0-9a-z]*\..*'
      target_label: 'name'
    - source_labels: ['__meta_docker_container_name']
      regex: '/.*\.([0-9]{1,2})\..*'
      target_label: 'replica'
    - action: replace
      replacement: integrations/docker
      source_labels:
        - __meta_docker_container_id
      target_label: job 
    - source_labels:
        - __meta_docker_container_name
      regex: '/(.*)'
      target_label: container
    - source_labels:
        - __meta_docker_container_log_stream
      target_label: stream

  # --log-opt tag="{{.ImageName}}|{{.Name}}|{{.ImageFullID}}|{{.FullID}}"
  pipeline_stages:
  - json:
      expressions:
        stream: stream
        attrs: attrs
        tag: attrs.tag
  - regex:
      expression: (?P<image_name>(?:[^|]*[^|])).(?P<container_name>(?:[^|]*[^|])).(?P<image_id>(?:[^|]*[^|])).(?P<container_id>(?:[^|]*[^|]))
      source: "tag"

  - labels:
      tag:
      stream:
      image_name:
      container_name:
      image_id:
      container_id:
EOF
  fi
}

function setup_grafana() {
  add_step "Setting up grafana"

  throw_if_env_var_not_present "GRAFANA_BASE_DIRECTORY" "$GRAFANA_BASE_DIRECTORY"

  ensure_directory_exists "$GRAFANA_BASE_DIRECTORY/var/lib/grafana"
  ensure_directory_exists "$GRAFANA_BASE_DIRECTORY/provisioning/datasources"
}

function setup_prometheus() {
  add_step "Setting up prometheus"

  throw_if_env_var_not_present "PROMETHEUS_BASE_DIRECTORY" "$PROMETHEUS_BASE_DIRECTORY"
  ensure_directory_exists "$PROMETHEUS_BASE_DIRECTORY" "104"

  touch "$PROMETHEUS_BASE_DIRECTORY/prometheus.yml"
}

function setup_monitoring() {
  setup_grafana
  setup_grafana_agent
  setup_promtail_agent
  setup_prometheus

  if ! docker network ls | grep "monitoring_network" &> /dev/null; then
    docker network create monitoring_network
  fi
}

function turn_off_wifi() {
  throw_if_program_not_present "rfkill"

  rfkill block wifi
}

function turn_off_bluetooth() {
  throw_if_program_not_present "rfkill"

  rfkill block bluetooth
}

function reset_pihole_password() {
  throw_if_env_var_not_present "PIHOLE_PASSWORD" "$PIHOLE_PASSWORD"
  
  echo "Setting pihole-server password..."
  docker exec pihole-server pihole -a -p "$PIHOLE_PASSWORD"
}

function setup_cloudflare_dns_entries() {
  cloudflare_tunnel="/opt/tools/cloudflared --config $CLOUDFLARE_BASE_DIRECTORY/config.yaml --origincert $CLOUDFLARE_BASE_DIRECTORY/.cloudflared/cert.pem tunnel"
  
  SUBDOMAINS=(home listen read media rss connector git podgrab proxy admin queue ytdl git photos notes coding ssh gladys monitoring mermaid drawio)
  for subdomain in "${SUBDOMAINS[@]}"; do
    $cloudflare_tunnel route dns geck "${subdomain}.${SERVICE_DOMAIN}" || true

    ./scripts/test-proxy.sh "$subdomain" || true
  done

  $cloudflare_tunnel ingress validate
}

function add_plugins_for_home_automation() {
  if ! docker exec nodered-web npm list node-red-node-twilio &> /dev/null; then
    docker exec nodered-web npm install node-red-node-twilio
  fi
}

function post_run() {
  turn_off_wifi
  turn_off_bluetooth

  reset_pihole_password

  setup_cloudflare_dns_entries

  add_plugins_for_home_automation

  git config --global alias.co checkout
  git config --global alias.st status
  git config --global alias.gl "log --oneline --graph"
}

function main() {
  if [[ -z "$RUN_TYPE" ]]; then
    echo "Please pass an argument for 'RUN_TYPE'."
    exit 1
  fi

  source ./scripts/common.sh

  check_requirements

  setup_firewall

  setup_nfs_media_mount

  setup_cloudflare_tunnel
  setup_nginx_proxy
  setup_homer
  setup_pihole
  setup_plex_server
  setup_calibre_web
  setup_pigallary_web
  setup_miniflux_web
  setup_audiobookshelf
  setup_code_server
  setup_codimd
  setup_gogs
  setup_podgrab
  setup_youtube_downloader
  setup_home_assistant
  setup_nodered

  setup_monitoring

  case "$RUN_TYPE" in
    "start")
      docker compose up -d --remove-orphans
      ;;
    "restart")
      docker compose restart
      ;;
    "boot")
      docker compose restart

      /opt/tools/cloudflared \
        --config "$CLOUDFLARE_BASE_DIRECTORY/config.yaml" \
        tunnel --no-autoupdate run geck
      ;;
    *)
      echo "Run type '$RUN_TYPE' is not valid, please use start, restart, or boot."
      exit 1
      ;;
  esac

  post_run
}

main
