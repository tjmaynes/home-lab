#!/usr/bin/env bash

set -e

function check_requirements() {
  throw_if_program_not_present "apt-get"

  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"
}

function setup_start_geck_service() {
  if [[ ! -f "/etc/systemd/system/start-geck.service" ]]; then
    sudo tee -a /etc/systemd/system/start-geck.service <<EOF
[Unit]
Description=Start GECK
After=network.target

[Service]
WorkingDirectory=/home/$NONROOT_USER/workspace/tjmaynes/geck
ExecStart=sudo make restart

[Install]
WantedBy=default.target
EOF
  fi

  sudo systemctl enable start-geck
}

function setup_cloudflared_service() {
  if [[ ! -f "/opt/tools/cloudflared" ]]; then
    CLOUDFLARED_VERSION=2022.10.3

    curl -OL "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${CPU_ARCH}"

    chmod a+x "cloudflared-linux-${CPU_ARCH}"

    mv "cloudflared-linux-${CPU_ARCH}" "/opt/tools/cloudflared"
  fi

  throw_if_env_var_not_present "CLOUDFLARE_BASE_DIRECTORY" "$CLOUDFLARE_BASE_DIRECTORY"
  ensure_directory_exists "$CLOUDFLARE_BASE_DIRECTORY/.cloudflared"
  throw_if_env_var_not_present "CLOUDFLARE_TUNNEL_UUID" "$CLOUDFLARE_TUNNEL_UUID"

  CLOUDFLARE_CREDENTIALS_FILE="$CLOUDFLARE_BASE_DIRECTORY/.cloudflared/$CLOUDFLARE_TUNNEL_UUID.json"
  CLOUDFLARE_CREDENTIALS_FILE=$(echo "$CLOUDFLARE_CREDENTIALS_FILE" | sed 's/\//\\\//g')

  sed \
    -e "s/%cloudflare-credentials-file%/${CLOUDFLARE_CREDENTIALS_FILE}/g" \
    -e "s/%cloudflare-tunnel-uuid%/${CLOUDFLARE_TUNNEL_UUID}/g" \
    -e "s/%hostname%/${NONROOT_USER}/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    static/templates/cloudflare.template.yml > "$CLOUDFLARE_BASE_DIRECTORY/config.yaml"

  if [[ ! -f "/etc/systemd/system/start-cloudflare-tunnel.service" ]]; then
    throw_if_env_var_not_present "CLOUDFLARE_BASE_DIRECTORY" "$CLOUDFLARE_BASE_DIRECTORY"

    sudo tee -a /etc/systemd/system/start-cloudflare-tunnel.service <<EOF
[Unit]
Description=Start Cloudflare Tunnel
After=network.target

[Service]
WorkingDirectory=/home/$NONROOT_USER/workspace/tjmaynes/geck
ExecStart=/opt/tools/cloudflared tunnel --config $CLOUDFLARE_BASE_DIRECTORY/config.yaml --no-autoupdate run geck

[Install]
WantedBy=default.target
EOF
  fi

  sudo systemctl enable start-cloudflare-tunnel
}

function setup_cronjobs() {
  throw_if_program_not_present "cron"

  BACKUP_CRONTAB="0 0-6/2 * * *  cd ~/workspace/tjmaynes/geck && sudo make backup"
  if ! crontab -l | grep "$BACKUP_CRONTAB"; then
    echo -e "Backups are not setup. Copy command and paste via 'crontab -e': $BACKUP_CRONTAB"
  fi

  CRON_LINE="#cron.*"
  if cat /etc/rsyslog.conf | grep "$CRON_LINE"; then
    echo -e "Cron logging is not configured. Uncomment 'cron' line in /etc/rsyslog.conf"
  fi
}

function setup_ip_forwarding() {
  IPV4_CONFIG="net.ipv4.ip_forward=1"
  if ! cat /etc/sysctl.conf | grep "$IPV4_CONFIG"; then
    echo "$IPV4_CONFIG" | sudo tee -a /etc/sysctl.conf
  fi

  IPV6_CONFIG="net.ipv6.conf.all.forwarding=1"
  if ! cat /etc/sysctl.conf | grep "$IPV6_CONFIG"; then
    echo "$IPV6_CONFIG" | sudo tee -a /etc/sysctl.conf
  fi
}

function install_docker() {
  if [[ -z "$(command -v docker)" ]]; then
    ./scripts/install-docker.sh
  fi

  usermod -aG docker "$NONROOT_USER"
}

function install_required_programs() {
  apt-get update && apt-get upgrade -y
  
  DEB_PACKAGES=(cron usermod curl lsof ffmpeg vim htop ethtool rfkill rsync openssh-server)
  for package in "${DEB_PACKAGES[@]}"; do
    ensure_program_installed "$package"
  done

  if [[ -z "$(command -v nslookup)" ]]; then
    ensure_program_installed "dnsutils"
  fi

  if [[ -z "$(command -v ifconfig)" ]]; then
    ensure_program_installed "net-tools"
  fi

  install_docker
}

function setup_firewall() {
  ensure_program_installed "ufw"

  ufw default allow outgoing
  ufw default deny incoming

  OPEN_PORTS=(22/tcp 80/tcp 443/tcp 32400/tcp)
  for port in "${OPEN_PORTS[@]}"; do
    ufw allow "$port"
  done

  ufw enable

  ufw status
}

function main() {
  source ./scripts/common.sh

  check_requirements

  install_required_programs

  setup_start_geck_service
  setup_cloudflared_service

  setup_cronjobs
  setup_ip_forwarding
  setup_firewall

  git config --global alias.co checkout
  git config --global alias.st status
  git config --global alias.gl "log --oneline --graph"

  reboot
}

main
