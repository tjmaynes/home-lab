#!/usr/bin/env bash

set -eo pipefail

function setup_env_vars() {
  if [[ ! -f ".envrc.production" ]]; then
    echo "Please create a production config: .envrc.production"
    exit 1
  fi

  export PUID=$(id -u)
  export PGID=$(id -g)

  source .envrc.production
}

function setup_nas_mount() {
  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"
  throw_if_env_var_not_present "NAS_MOUNT_PASSWORD" "$NAS_MOUNT_PASSWORD"
  throw_if_env_var_not_present "NAS_IP" "$NAS_IP"

  delay=0
  while ! mount | grep "//$NAS_IP/$1 on $2 type cifs" > /dev/null; do
    sleep $delay

    if [ "$delay" -gt 60 ]; then
        exit 1
    fi

    sudo mount -t cifs "//$NAS_IP/$1" "$2" \
      -o "username=$NONROOT_USER,password=$NAS_MOUNT_PASSWORD" || true

    delay=$((delay+5))
  done
}

# https://unix.stackexchange.com/a/137639
function fail() {
  echo "$1" >&2
  exit 1
}

# https://unix.stackexchange.com/a/137639
function retry() {
  local n=1
  local max=5
  local delay=15

  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

function ensure_directory_exists() {
  TARGET_DIRECTORY=$1
  ALLOWED_USER=${2:-$NONROOT_USER}

  if [[ ! -d "$TARGET_DIRECTORY" ]]; then
    echo "Creating $TARGET_DIRECTORY directory..."
    sudo -u "$ALLOWED_USER" mkdir -p "$TARGET_DIRECTORY"
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

function throw_if_file_not_present() {
  FILE=$1

  if [[ ! -f "$FILE" ]]; then
    echo "Please create '$FILE' before running this script"
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

  if [[ -L "$TARGET" ]]; then
    unlink "$TARGET"
  fi

  ln -s "$SOURCE" "$TARGET"
}

function ensure_program_installed() {
  if [[ -n "$1" ]] && [[ -z "$(command -v $1)" ]]; then
    apt-get install "$1" -y
  fi
}

function install_cloudflared() {
  CLOUDFLARED_VERSION=$1

  if [[ -z "$CLOUDFLARED_VERSION" ]]; then
    echo "install_cloudflared: Please pass a version for cloudflared"
    exit 1
  fi

  throw_if_env_var_not_present "CPU_ARCH" "$CPU_ARCH"

  if [[ ! -f "/opt/tools/cloudflared" ]] || ! cat /opt/tools/.cloudflared-version | grep "$CLOUDFLARED_VERSION" &> /dev/null; then
    rm -rf /opt/tools/cloudflared

    curl -OL "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${CPU_ARCH}"

    chmod a+x "cloudflared-linux-${CPU_ARCH}"

    mv "cloudflared-linux-${CPU_ARCH}" "/opt/tools/cloudflared"

    rm -f /opt/tools/.cloudflared-version
    tee -a /opt/tools/.cloudflared-version <<EOF
$CLOUDFLARED_VERSION
EOF
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

# USED_PORTS=$(lsof -i -n -P | awk '{print $9}' | grep ':' | cut -d ':' -f 2 | sort | uniq | grep -v '\->' | grep -v '*')
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

  # if echo $USED_PORTS | grep -w -q "$NEW_PORT"; then
  #   echo "Port '$NEW_PORT' for '$ENV_VAR_KEY' is already in use! Please choose another port to set for '$ENV_VAR_KEY'."
  #   exit 1
  # fi

  # USED_PORTS+=($NEW_PORT)

  export $1=$2
}

STEPS=$()
STEP_COUNT=1
function add_step() {
  STEP=$1

  if [[ -z "$STEP" ]]; then
    echo "add_step: Please pass a string for argument 1"
    exit 1
  fi

  echo "step ${STEP_COUNT}: $1"

  ((STEP_COUNT+=1))
  STEPS+=(STEP)
}

setup_env_vars