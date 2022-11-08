#!/usr/bin/env bash

set -e

function setup_grafana_agent() {
  add_step "Setting up grafana-agent"

  throw_if_env_var_not_present "GRAFANA_AGENT_BASE_DIRECTORY" "$GRAFANA_AGENT_BASE_DIRECTORY"
  ensure_directory_exists "${GRAFANA_AGENT_BASE_DIRECTORY}/data"

  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"
  throw_if_env_var_not_present "GRAFANA_USERNAME" "$GRAFANA_USERNAME"
  throw_if_env_var_not_present "GRAFANA_API_KEY" "$GRAFANA_API_KEY"
  throw_if_env_var_not_present "LOKI_URI" "$LOKI_URI"

  if [[ ! -f "${GRAFANA_AGENT_BASE_DIRECTORY}/agent.yaml" ]]; then
    sudo tee -a "${GRAFANA_AGENT_BASE_DIRECTORY}/agent.yaml" <<EOF
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

  throw_if_env_var_not_present "GRAFANA_AGENT_VERSION" "$GRAFANA_AGENT_VERSION"

  mkdir -p "/opt/tools"

  if [[ ! -f "/opt/tools/grafana-agent" ]]; then
    curl -O -L "https://github.com/grafana/agent/releases/download/v$GRAFANA_AGENT_VERSION/agent-linux-${CPU_ARCH}.zip"

    unzip "agent-linux-${CPU_ARCH}.zip"

    chmod a+x "agent-linux-${CPU_ARCH}"

    mv "agent-linux-${CPU_ARCH}" "/opt/tools/grafana-agent"

    rm -rf "agent-linux-${CPU_ARCH}.zip"
  fi

  if [[ ! -f "/etc/systemd/system/grafana-agent.service" ]]; then
    sudo tee -a /etc/systemd/system/grafana-agent.service <<EOF
[Unit]
Description=Run grafana-agent
After=network.target

[Service]
ExecStart=sudo /opt/tools/grafana-agent -config.file ${GRAFANA_AGENT_BASE_DIRECTORY}/agent.yaml
Restart=always
TimeoutStopSec=3

[Install]
WantedBy=multi-user.target
EOF
  fi

  sudo systemctl enable grafana-agent
}

function setup_promtail_agent() {
  add_step "Setting up promtail-agent"

  throw_if_env_var_not_present "NONROOT_USER" "${NONROOT_USER}"
  throw_if_env_var_not_present "PROMTAIL_AGENT_BASE_DIRECTORY" "$PROMTAIL_AGENT_BASE_DIRECTORY"

  ensure_directory_exists "$PROMTAIL_AGENT_BASE_DIRECTORY"

  if [[ ! -f "${PROMTAIL_AGENT_BASE_DIRECTORY}/config.yaml" ]]; then
    sudo tee -a "${PROMTAIL_AGENT_BASE_DIRECTORY}/config.yaml" <<EOF
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

  throw_if_env_var_not_present "PROMTAIL_AGENT_VERSION" "$PROMTAIL_AGENT_VERSION"

  mkdir -p "/opt/tools"

  if [[ ! -f "/opt/tools/promtail" ]]; then
    curl -O -L "https://github.com/grafana/loki/releases/download/v$PROMTAIL_AGENT_VERSION/promtail-linux-${CPU_ARCH}.zip"

    unzip "promtail-linux-${CPU_ARCH}.zip"

    chmod a+x "promtail-linux-${CPU_ARCH}"

    mv "promtail-linux-${CPU_ARCH}" "/opt/tools/promtail"

    rm -rf "promtail-linux-${CPU_ARCH}.zip"
  fi

  if [[ ! -f "/etc/systemd/system/promtail-agent.service" ]]; then
    sudo tee -a /etc/systemd/system/promtail-agent.service <<EOF
[Unit]
Description=Run promtail-agent
After=network.target

[Service]
ExecStart=sudo /opt/tools/promtail -config.file ${PROMTAIL_AGENT_BASE_DIRECTORY}/config.yaml
Restart=always
TimeoutStopSec=3

[Install]
WantedBy=multi-user.target
EOF
  fi

  sudo systemctl enable promtail-agent
}

function main() {
  source ./scripts/common.sh

  throw_if_env_var_not_present "CPU_ARCH" "$CPU_ARCH"

  setup_grafana_agent
  setup_promtail_agent
}

main
