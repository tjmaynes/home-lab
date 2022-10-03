#!/usr/bin/env bash

set -eo pipefail

SUBDOMAIN=$1

function main() {
  source ./scripts/common.sh

  throw_if_program_not_present "curl"

  if ! curl --fail -H "Host: ${SUBDOMAIN}.${SERVICE_DOMAIN}" localhost:80 &> /dev/null; then
    echo "Please setup a proxy-host for '${SUBDOMAIN}.${SERVICE_DOMAIN}' in nginx-proxy."
    exit 1
  fi
}

main