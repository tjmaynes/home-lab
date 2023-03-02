#!/usr/bin/env bash

set -e

RUN_TYPE=$1

function throw_if_required_env_var_not_exists() {
  if [[ -z "$2" ]]; then
    echo "Please set environment variable '$1' before running this script"
    exit 1
  fi
}

function check_requirements() {
  throw_if_required_env_var_not_exists "SERVICE_DOMAIN" "$SERVICE_DOMAIN"
  throw_if_required_env_var_not_exists "CLOUDFLARE_TUNNEL_UUID" "$CLOUDFLARE_TUNNEL_UUID"
  throw_if_required_env_var_not_exists "PLEX_CLAIM_TOKEN" "$PLEX_CLAIM_TOKEN"
  throw_if_required_env_var_not_exists "NGINX_PROXY_MANAGER_DB_PASSWORD" "$NGINX_PROXY_MANAGER_DB_PASSWORD"

  throw_if_required_env_var_not_exists "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"

  throw_if_required_env_var_not_exists "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "HOMER_BASE_DIRECTORY" "$HOMER_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "PIHOLE_BASE_DIRECTORY" "$PIHOLE_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "PLEX_BASE_DIRECTORY" "$PLEX_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "CALIBRE_WEB_BASE_DIRECTORY" "$CALIBRE_WEB_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "PIGALLERY_BASE_DIRECTORY" "$PIGALLERY_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "GOGS_BASE_DIRECTORY" "$GOGS_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "AUDIOBOOKSHELF_BASE_DIRECTORY" "$AUDIOBOOKSHELF_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "PODGRAB_BASE_DIRECTORY" "$PODGRAB_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "OCTOPRINT_BASE_DIRECTORY" "$OCTOPRINT_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "HOMEASSISTANT_BASE_DIRECTORY" "$HOMEASSISTANT_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "NODERED_BASE_DIRECTORY" "$NODERED_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "MEDIAFILEBROWSER_BASE_DIRECTORY" "$MEDIAFILEBROWSER_BASE_DIRECTORY"
}

function taint_3dprinter_node() {
  kubectl taint nodes raspberrypi type=3dprinter:NoSchedule --overwrite
}

function create_namespace() {
  NAMESPACE=$1

  if ! kubectl get namespace | grep "$NAMESPACE" &> /dev/null; then
    kubectl create namespace "$NAMESPACE"
  fi
}

function copy_cloudflare_tunnel_credentials() {
  if ! kubectl -n geck get secret | grep "cloudflare-tunnel-credentials" &> /dev/null; then
    kubectl -n geck create secret generic cloudflare-tunnel-credentials \
      --from-file=credentials.json=./tmp/.cloudflared/$CLOUDFLARE_TUNNEL_UUID.json
  fi
}

function install_node_red_plugins() {
  NODE_RED_POD=$(kubectl -n geck get pod -l app=node-red -o jsonpath="{.items[0].metadata.name}")
  # kubectl -n geck exec -it "$NODE_RED_POD" -- /bin/bash -c "mkdir -p /data/.npm && chown -R 1000:1000 /data/.npm"

  if ! kubectl -n geck exec -it "$NODE_RED_POD" -- /bin/bash -c "npm list node-red-node-twilio" &> /dev/null; then
    echo "Installing node-red dependencies..."
    kubectl -n geck exec -it "$NODE_RED_POD" -- /bin/bash -c "npm install node-red-node-twilio"
  fi
}

function update_home_assistant_env_var() {
  PROXY_SERVER_IP=$(kubectl -n geck get pod -l app=nginx-proxy-manager -o jsonpath="{.items[0].status.podIP}")

  if ! kubectl -n geck get pod -l app=home-assistant -o jsonpath="{.items[0].spec.containers[0].env}" | grep -w "$PROXY_SERVER_IP" &> /dev/null; then
    kubectl -n geck set env deployment/home-assistant PROXY_SERVER_IP=${PROXY_SERVER_IP}
  fi
}

function run_apply() {
  create_namespace "geck"
  create_namespace "monitoring"
  taint_3dprinter_node
  copy_cloudflare_tunnel_credentials

  for f in ./k8s/*.yml; do envsubst < "$f" | kubectl apply -f -; done

  install_node_red_plugins
  update_home_assistant_env_var
}

function main() {
  check_requirements

  case "$RUN_TYPE" in
    "apply")
      run_apply
      ;;
    "delete")
      for f in ./k8s/*.yml; do envsubst < "$f" | kubectl delete -f - || true; done
      ;;
    *)
      echo "Arg '$RUN_TYPE' is not valid, please use 'apply' or 'delete'."
      exit 1
      ;;
  esac
}

main
