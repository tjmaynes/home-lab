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

  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"
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
    scrape_interval: 15s
    remote_write:
      - url: https://prometheus-prod-10-prod-us-central-0.grafana.net/api/prom/push
        basic_auth:
          username: ${GRAFANA_USERNAME}
          password: ${GRAFANA_API_KEY}

integrations:
  agent:
    enabled: true
    instance: ${NONROOT_USER}

  node_exporter:
    enabled: true
    rootfs_path: /host/root
    sysfs_path: /host/sys
    procfs_path: /host/proc
    relabel_configs:
    - replacement: hostname
      target_label: instance
    - replacement: integrations/${NONROOT_USER}/docker
      target_label: job

logs:
  configs:
  - name: linux-scraping
    positions:
      filename: /tmp/positions-linux.yaml
    scrape_configs:
    - job_name: integrations/node_exporter_journal_scrape
      journal:
        max_age: 24h
        labels:
          instance: ${NONROOT_USER}
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

  - name: docker-scraping
    positions:
      filename: /tmp/positions-docker.yaml
    target_config:
      sync_period: 10s 
    scrape_configs:
    - job_name: integrations/${NONROOT_USER}/docker
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
          replacement: integrations/${NONROOT_USER}/docker
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
EOF
  fi
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
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*log

  pipeline_stages:
  - static_labels:
      hostname: ${NONROOT_USER}

- job_name: ${NONROOT_USER}/containers
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
      replacement: integrations/${NONROOT_USER}/docker
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

function main() {
  source ./scripts/common.sh

  check_requirements

  setup_grafana_agent
  setup_promtail_agent
}

main