#!/usr/bin/env bash

set -e

function check_requirements() {
  throw_if_program_not_present "docker"

  throw_if_env_var_not_present "PUID" "$PUID"
  throw_if_env_var_not_present "PGID" "$PGID"
}

function setup_grafana_agent() {
  add_step "Setting up grafana-agent"

  throw_if_env_var_not_present "GRAFANA_AGENT_BASE_DIRECTORY" "$GRAFANA_AGENT_BASE_DIRECTORY"
  ensure_directory_exists "${GRAFANA_AGENT_BASE_DIRECTORY}/data"

  throw_if_env_var_not_present "GRAFANA_USERNAME" "$GRAFANA_USERNAME"
  throw_if_env_var_not_present "GRAFANA_API_KEY" "$GRAFANA_API_KEY"
  throw_if_env_var_not_present "LOKI_URI" "$LOKI_URI"

  if [[ ! -f "${GRAFANA_AGENT_BASE_DIRECTORY}/agent.yaml" ]]; then
    sudo tee -a "${GRAFANA_AGENT_BASE_DIRECTORY}/agent.yaml" <<EOF
server:
  log_level: info

metrics:
  wal_directory: /tmp/wal
  global:
    remote_write:
      - url: https://prometheus-prod-10-prod-us-central-0.grafana.net/api/prom/push
        basic_auth:
          username: ${GRAFANA_USERNAME}
          password: ${GRAFANA_API_KEY}

integrations:
  agent:
    enabled: true
    instance: geck

  node_exporter:
    enabled: true
    relabel_configs:
    - replacement: hostname
      target_label: instance

logs:
  configs:
  - name: integrations
    positions:
      filename: /tmp/positions.yaml
    scrape_configs:
    - job_name: integrations/node_exporter_journal_scrape
      journal:
        max_age: 24h
        labels:
          instance: geck
          job: integrations/node_exporter
      relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: 'unit'
      - source_labels: ['__journal__boot_id']
        target_label: 'boot_id'
      - source_labels: ['__journal__transport']
        target_label: 'transport'
      - source_labels: ['__journal_priority_keyword']
        target_label: 'level'
EOF
  fi
}

function setup_promtail_agent() {
  add_step "Setting up promtail-agent"

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
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*log
  
  pipeline_stages:
  - static_labels:
      hostname: "geck"

- job_name: containers
  static_configs:
  - targets:
      - localhost
    labels:
      job: containerlogs
      __path__: /var/lib/docker/containers/*/*log

  # --log-opt tag="{{.ImageName}}|{{.Name}}|{{.ImageFullID}}|{{.FullID}}"
  pipeline_stages:
  - static_labels:
      hostname: "geck"

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

function main() {
  source ./scripts/common.sh

  check_requirements

  setup_grafana_agent
  setup_promtail_agent
}

main