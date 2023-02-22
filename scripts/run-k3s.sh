#!/usr/bin/env bash

set -e

ENV_FILE=.env.production

source $ENV_FILE

function main() {
  if [[ "$1" == "apply" ]] || [[ "$1" == "delete" ]]; then
    envsubst < $3 | kubectl $1 $2 -
  else
    kubectl "$@"
  fi
}

main
