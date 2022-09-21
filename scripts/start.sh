#!/usr/bin/env bash

set -e

function main() {
  ./scripts/run-docker-compose.sh "start"
}

main