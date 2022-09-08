#!/usr/bin/env bash

set -eo pipefail

GIVEN_RUN_TYPE=$1

function main() {
  if [[ -z "$GIVEN_RUN_TYPE" ]]; then
    echo "Please pass an argument for 'GIVEN_RUN_TYPE'."
    exit 1
  elif [[ ! -f "./scripts/$GIVEN_RUN_TYPE.sh" ]]; then
    echo "Unable to run script with argument 1 '$GIVEN_RUN_TYPE'."
    exit 1
  else
    ./scripts/$GIVEN_RUN_TYPE.sh
    echo "Done!"
  fi
}

main
