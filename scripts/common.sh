#!/bin/bash

set -eo pipefail

function ensure_directory_exists() {
  TARGET_DIRECTORY=$1

  if [[ ! -d "$TARGET_DIRECTORY" ]]; then
    echo "Creating $TARGET_DIRECTORY directory..."
    mkdir -p "$TARGET_DIRECTORY"
  fi
}

function throw_if_program_not_present() {
  if [[ -z "$(command -v $1)" ]]; then
    echo "Please install '$1' before running this script"
    exit 1
  fi
}

function throw_if_env_var_not_present() {
  ENV_VAR_KEY=$1
  ENV_VAR_VALUE=$2

  if [[ -z "$ENV_VAR_VALUE" ]]; then
    echo "Please set an environment variable for '$ENV_VAR_KEY' before running this script"
    exit 1
  fi
}

function throw_if_directory_not_present() {
  DIRECTORY_ENV_VAR_KEY=$1
  DIRECTORY_ENV_VAR_VALUE=$2

  throw_if_env_var_not_present "$DIRECTORY_ENV_VAR_KEY" "$DIRECTORY_ENV_VAR_VALUE"

  if [[ ! -d "$DIRECTORY_ENV_VAR_VALUE" ]]; then
    echo "Please create a directory ($DIRECTORY_ENV_VAR_VALUE) for environment variable '$DIRECTORY_ENV_VAR_KEY' before running this script"
    exit 1
  fi
}

function wait_for_service_to_be_up() {
  throw_if_program_not_present "curl"

  SERVICE_URL=$1

  if [[ -z "$SERVICE_URL" ]]; then
    echo "wait_for_service_to_be_up: Please pass an argument for 'SERVICE_URL'"
    exit 1
  fi

  attempt_counter=0
  max_attempts=5

  until $(curl --output /dev/null --silent --head --fail $SERVICE_URL); do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached"
      exit 1
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 5
  done
}