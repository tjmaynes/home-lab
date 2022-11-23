#!/usr/bin/env bash

set -eo pipefail

CLOUDFLARED_VERSION=$1

function main() {
  source ./scripts/common.sh

  install_cloudflared "$CLOUDFLARED_VERSION"
}

main