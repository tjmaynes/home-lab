#!/usr/bin/env bash

set -e

CONTAINER_NAME=$1

function main() {
  if [[ -z "$CONTAINER_NAME" ]]; then
    echo "Please pass an argument for a container name to the script"
    exit 1
  fi

  CONTAINER_STATE=$(docker container inspect -f '{{.State.Status}}' "$CONTAINER_NAME")
  if [[ "$CONTAINER_STATE" = "running" ]]; then
    echo "Stopping and deleting '$CONTAINER_NAME' container..."
    docker stop "$CONTAINER_NAME" &> /dev/null
    docker rm "$CONTAINER_NAME" &> /dev/null

    echo "Deleting '$CONTAINER_NAME' container state..."
    sudo rm -rf "$DOCKER_BASE_DIRECTORY/$CONTAINER_NAME"
  else
    echo "Container name '$CONTAINER_NAME' not running, current state: '$CONTAINER_STATE'"
    exit 1
  fi
}

main