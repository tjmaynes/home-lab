#!/usr/bin/env bash

set -e

function check_requirements() {
  throw_if_program_not_present "apt-get"

  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"
}

function setup_cronjobs() {
  throw_if_program_not_present "cron"

  force_symlink_between_files "$(pwd)/cron.d/onreboot.crontab" "/etc/cron.d/onreboot.crontab"
}

function setup_nfs_media_mount() {
  throw_if_program_not_present "mount"

  throw_if_env_var_not_present "NAS_IP" "$NAS_IP"
  throw_if_env_var_not_present "NAS_MEDIA_DIRECTORY" "$NAS_MEDIA_DIRECTORY"
  throw_if_env_var_not_present "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"

  ensure_directory_exists "$MEDIA_BASE_DIRECTORY"

  sudo mount -t nfs "$NAS_IP:$NAS_MEDIA_DIRECTORY" "$MEDIA_BASE_DIRECTORY" || true

  throw_if_directory_not_present "VIDEOS_DIRECTORY" "$VIDEOS_DIRECTORY"
  throw_if_directory_not_present "MUSIC_DIRECTORY" "$MUSIC_DIRECTORY"
  throw_if_directory_not_present "PHOTOS_DIRECTORY" "$PHOTOS_DIRECTORY"
  throw_if_directory_not_present "BOOKS_DIRECTORY" "$BOOKS_DIRECTORY"
  throw_if_directory_not_present "AUDIOBOOKS_DIRECTORY" "$AUDIOBOOKS_DIRECTORY"
  throw_if_directory_not_present "PODCASTS_DIRECTORY" "$PODCASTS_DIRECTORY"
}

function setup_nfs_backup_mount() {
  throw_if_program_not_present "mount"

  throw_if_env_var_not_present "NAS_IP" "$NAS_IP"
  throw_if_env_var_not_present "NAS_BACKUP_DIRECTORY" "$NAS_BACKUP_DIRECTORY"
  throw_if_env_var_not_present "LOCAL_BACKUP_DIRECTORY" "$LOCAL_BACKUP_DIRECTORY"

  ensure_directory_exists "$LOCAL_BACKUP_DIRECTORY"

  mount -t nfs "$NAS_IP:$NAS_BACKUP_DIRECTORY" "$LOCAL_BACKUP_DIRECTORY" || true
}

function setup_nfs_mounts() {
  setup_nfs_backup_mount
  setup_nfs_media_mount
}

function install_docker() {
  if [[ -z "$(command -v docker)" ]]; then
    sudo ./scripts/install-docker.sh
  fi

  sudo usermod -aG docker "$NONROOT_USER"
}

function install_argon_one_case() {
  sudo ./scripts/setup-argon1-fan.sh
}

function install_required_programs() {
  ensure_program_installed "usermod"
  ensure_program_installed "curl"
  ensure_program_installed "lsof"
  ensure_program_installed "ffmpeg"
  ensure_program_installed "vim"

  install_docker
  install_argon_one_case
}

function main() {
  source ./scripts/common.sh

  check_requirements

  sudo apt-get update && sudo apt-get upgrade -y

  install_required_programs

  setup_cronjobs
  setup_nfs_mounts

  sudo reboot
}

main
