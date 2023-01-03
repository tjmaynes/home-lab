#!/usr/bin/env bash

set -eo pipefail

function main() {
  source ./scripts/common.sh

  throw_if_env_var_not_present "HOST_IP" "$HOST_IP"
  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"

  ssh -L32400:localhost:32400 "$NONROOT_USER@$HOST_IP"
}

main
