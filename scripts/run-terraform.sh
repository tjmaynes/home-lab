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
  throw_if_required_env_var_not_exists "CLOUDFLARE_EMAIL" "$CLOUDFLARE_EMAIL"
  throw_if_required_env_var_not_exists "CLOUDFLARE_GOOGLE_CLIENT_ID" "$CLOUDFLARE_GOOGLE_CLIENT_ID"
  throw_if_required_env_var_not_exists "CLOUDFLARE_GOOGLE_CLIENT_SECRET" "$CLOUDFLARE_GOOGLE_CLIENT_SECRET"
  throw_if_required_env_var_not_exists "CLOUDFLARE_ACCESS_EMAILS" "$CLOUDFLARE_ACCESS_EMAILS"
}

function main() {
  check_requirements

  case "$RUN_TYPE" in
    "apply")
      pushd terraform
        [[ ! -d ".terraform" ]] && terraform init
        terraform "$RUN_TYPE"
      popd
      ;;
    "plan")
      cd terraform && terraform "$RUN_TYPE"
      ;;
    *)
      echo "Arg '$RUN_TYPE' is not valid, please use 'apply' or 'plan'."
      exit 1
      ;;
  esac
}

main
