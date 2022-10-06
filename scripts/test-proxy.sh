#!/usr/bin/env bash

set -eo pipefail

SUBDOMAIN=$1

function main() {
  source ./scripts/common.sh

  throw_if_program_not_present "curl"

  if ! curl --fail -H "Host: ${SUBDOMAIN}.${SERVICE_DOMAIN}" localhost:80 &> /dev/null; then
    echo "[warning]: Unable to easily check '${SUBDOMAIN}.${SERVICE_DOMAIN}' is setup in nginx-proxy..."
    exit 1
  fi
}

main