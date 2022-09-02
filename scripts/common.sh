#!/bin/bash

set -eo pipefail

function setup_env_vars() {
  DEFAULT_ENV_FILE=.envrc.development.$(uname -m)
  if [[ -z "$ENV_FILE" ]]; then
    ENV_FILE=$DEFAULT_ENV_FILE
  fi

  export PUID=$(id -u)
  export PGID=$(id -g)

  source "$ENV_FILE"
}

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

function force_symlink_between_files() {
  SOURCE=$1
  TARGET=$2

  if [[ -z "$SOURCE" ]]; then
    echo "force_symlink_between_files: Please provide a source for arg 1"
    exit 1
  fi

  if [[ -z "$TARGET" ]]; then
    echo "force_symlink_between_files: Please provide a target for arg 2"
    exit 1
  fi

  if [[ ! "$(readlink $TARGET)" -ef "$SOURCE" ]]; then
    rm -rf "$TARGET"
    ln -s "$TARGET" "$SOURCE"
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

USED_PORTS=$(lsof -i -n -P | awk '{print $9}' | grep ':' | cut -d ":" -f 2 | sort | uniq | grep -v '\->' | grep -v '*')
function safely_set_port_for_env_var() {
  ENV_VAR_KEY=$1
  NEW_PORT=$2

  if [[ -z "$ENV_VAR_KEY" ]]; then
    echo "safely_set_port_for_env_var: Please pass an environment variable key as first argument"
    exit 1
  elif [[ -z "$NEW_PORT" ]]; then
    echo "safely_set_port_for_env_var: Please pass a valid port as second argument"
    exit 1
  fi

  if echo $USED_PORTS | grep -w -q "$NEW_PORT"; then
    echo "Port '$NEW_PORT' for '$ENV_VAR_KEY' is already in use! Please choose another port to set for '$ENV_VAR_KEY'."
    exit 1
  fi

  USED_PORTS+=($NEW_PORT)

  export $1=$2
}

setup_env_vars