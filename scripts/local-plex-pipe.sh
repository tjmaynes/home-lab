#!/usr/bin/env bash

set -eo pipefail

function main() {
  source ./scripts/common.sh

  throw_if_env_var_not_present "HOST_IP" "$HOST_IP"
  
  ssh -L32400:localhost:32400 geck@${HOST_IP}
}

main
