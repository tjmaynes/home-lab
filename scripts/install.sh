#!/usr/bin/env bash

set -e

function check_requirements() {
  throw_if_program_not_present "apt-get"

  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"
}

function setup_macvlan_service() {
  if [[ ! -f "/etc/systemd/system/macvlan.service" ]]; then
    sudo tee -a /etc/systemd/system/macvlan.service <<EOF
[Unit]
Description=Setup Macvlan Network
After=network.target

[Service]
WorkingDirectory=/home/$NONROOT_USER/workspace/tjmaynes/geck
ExecStart=sudo make macvlan

[Install]
WantedBy=default.target
EOF
  fi

  sudo systemctl enable macvlan
}

function setup_start_geck_service() {
  if [[ ! -f "/etc/systemd/system/start-geck.service" ]]; then
    sudo tee -a /etc/systemd/system/start-geck.service <<EOF
[Unit]
Description=Start geck
After=network.target

[Service]
WorkingDirectory=/home/$NONROOT_USER/workspace/tjmaynes/geck
ExecStart=sudo make start

[Install]
WantedBy=default.target
EOF
  fi

  sudo systemctl enable start-geck
}

function setup_cronjobs() {
  throw_if_program_not_present "cron"

  BACKUP_CRONTAB="0 0-6/2 * * *  cd ~/workspace/tjmaynes/geck && sudo make backup"
  if ! crontab -l | grep "$BACKUP_CRONTAB"; then
    echo -e "Backups are not setup. Copy command and paste via 'crontab -e': $BACKUP_CRONTAB"
  fi
}

function install_docker() {
  if [[ -z "$(command -v docker)" ]]; then
    ./scripts/install-docker.sh
  fi

  usermod -aG docker "$NONROOT_USER"
}

function install_argon_one_case() {
  if [[ -z "$(command -v argonone-config)" ]]; then
    ./scripts/setup-argon1-fan.sh
  fi
}

function install_required_programs() {
  ensure_program_installed "usermod"
  ensure_program_installed "curl"
  ensure_program_installed "lsof"
  ensure_program_installed "ffmpeg"
  ensure_program_installed "vim"
  ensure_program_installed "htop"

  install_docker
  install_argon_one_case
}

function setup_nfs_media_mount() {
  throw_if_program_not_present "mount"

  throw_if_env_var_not_present "NAS_IP" "$NAS_IP"
  throw_if_env_var_not_present "NAS_MEDIA_DIRECTORY" "$NAS_MEDIA_DIRECTORY"
  throw_if_env_var_not_present "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"
  
  ensure_directory_exists "$MEDIA_BASE_DIRECTORY"

  FSTAB_CONFIG="$NAS_IP:$NAS_MEDIA_DIRECTORY $MEDIA_BASE_DIRECTORY nfs rw,relatime,user,noauto 0 0"
  if ! cat /etc/fstab | grep -q "$FSTAB_CONFIG"; then
    echo "$FSTAB_CONFIG" >> /etc/fstab
  fi
}

function setup_nfs_mounts() {
  setup_nfs_media_mount
}

function setup_sysctl() {
  IPV4_CONFIG="net.ipv4.ip_forward=1"
  if ! cat /etc/sysctl.conf | grep "$IPV4_CONFIG"; then
    echo "$IPV4_CONFIG" >> /etc/sysctl.conf
  fi

  IPV6_CONFIG="net.ipv6.conf.all.forwarding=1"
  if ! cat /etc/sysctl.conf | grep "$IPV6_CONFIG"; then
    echo "$IPV6_CONFIG" >> /etc/sysctl.conf
  fi
}

function turn_off_wifi() {
  ensure_program_installed "rfkill"

  rfkill block wifi
}

function turn_off_bluetooth() {
  ensure_program_installed "rfkill"

  rfkill block bluetooth
}

function main() {
  source ./scripts/common.sh

  check_requirements

  apt-get update && apt-get upgrade -y

  install_required_programs

  setup_macvlan_service
  setup_start_geck_service

  setup_sysctl
  setup_cronjobs
  setup_nfs_mounts

  throw_if_program_not_present "raspi-config"
  raspi-config nonint do_boot_wait 0

  turn_off_wifi
  turn_off_bluetooth

  reboot
}

main
