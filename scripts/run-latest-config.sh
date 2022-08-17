#!/bin/bash

set -e

export BASE_DIRECTORY=$1
export SERVICE_DOMAIN=$2
export PLEX_CLAIM_TOKEN=$3

function check_requirements() {
  if [[ -z "$(command -v docker)" ]]; then
    echo "Please install 'docker' before running this script"
    exit 1
  fi
}

function ensure_tailscale_tunnel_exists() {
  if [[ ! -c "/dev/net/tun" ]]; then
    if [[ ! -d "/dev/net" ]]; then
      mkdir -m 755 /dev/net
    fi

    mknod /dev/net/tun c 10 200
    chmod 0755 /dev/net/tun
  fi

  if ( !(lsmod | grep -q "^tun\s") ); then
    insmod /lib/modules/tun.ko
  fi
}

function main() {
  check_requirements

  if [[ -d "kratos" ]]; then
	  sudo rm -rf kratos
  fi

  curl -SL https://github.com/tjmaynes/kratos/archive/master.tar.gz | tar xz
  mv kratos-main kratos

  ensure_tailscale_tunnel_exists

  pushd kratos
    ./scripts/install.sh "$BASE_DIRECTORY" "$SERVICE_DOMAIN" "$PLEX_CLAIM_TOKEN"
  popd
}

main
