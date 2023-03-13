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

  throw_if_required_env_var_not_exists "PROGRAMS_BASE_DIRECTORY" "$PROGRAMS_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "HOMER_BASE_DIRECTORY" "$HOMER_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "PLEX_BASE_DIRECTORY" "$PLEX_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "CALIBRE_WEB_BASE_DIRECTORY" "$CALIBRE_WEB_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "PIGALLERY_BASE_DIRECTORY" "$PIGALLERY_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "GOGS_BASE_DIRECTORY" "$GOGS_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "AUDIOBOOKSHELF_BASE_DIRECTORY" "$AUDIOBOOKSHELF_BASE_DIRECTORY"
  throw_if_required_env_var_not_exists "PODGRAB_BASE_DIRECTORY" "$PODGRAB_BASE_DIRECTORY"
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
  if ! kubectl -n vpn get secret | grep "cloudflare-tunnel-credentials" &> /dev/null; then
    kubectl -n vpn create secret generic cloudflare-tunnel-credentials \
      --from-file=credentials.json=./tmp/.cloudflared/$CLOUDFLARE_TUNNEL_UUID.json
  fi
}

function run_apply() {
  create_namespace "vpn"
  copy_cloudflare_tunnel_credentials
  for f in ./k8s/vpn/*.yml; do envsubst < "$f" | kubectl apply -f -; done

  create_namespace "media"
  for f in ./k8s/media/*.yml; do envsubst < "$f" | kubectl apply -f -; done

  create_namespace "development"
  for f in ./k8s/development/*.yml; do envsubst < "$f" | kubectl apply -f -; done

  create_namespace "monitoring"
  for f in ./k8s/monitoring/*.yml; do envsubst < "$f" | kubectl apply -f -; done
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
