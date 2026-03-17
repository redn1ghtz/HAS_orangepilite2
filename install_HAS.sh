#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

log() { echo -e "\n[INFO] $*"; }
warn() { echo -e "\n[WARN] $*"; }
err() { echo -e "\n[ERROR] $*" >&2; }

install_base_packages() {
  log "Installing required system packages"
  apt update
  apt install -y \
    apparmor apparmor-utils jq wget curl udisks2 dbus \
    network-manager avahi-daemon ca-certificates gnupg lsb-release
}

configure_networkmanager() {
  log "Configuring NetworkManager to manage interfaces"
  mkdir -p /etc/NetworkManager/conf.d
  tee /etc/NetworkManager/conf.d/99-managed-devices.conf >/dev/null <<'EOF'
[keyfile]
unmanaged-devices=none

[ifupdown]
managed=true
EOF

  rm -f /etc/NetworkManager/conf.d/*unmanaged*.conf

  tee /etc/network/interfaces >/dev/null <<'EOF'
auto lo
iface lo inet loopback
EOF

  log "Checking effective NetworkManager config"
  grep -RnsE "unmanaged-devices|managed=" /usr/lib/NetworkManager /etc/NetworkManager || true

  systemctl enable NetworkManager
  systemctl restart NetworkManager
  sleep 2
  nmcli device status || true

  log "Open armbian-config now. Complete network setup, then exit armbian-config."
  if command -v armbian-config >/dev/null 2>&1; then
    armbian-config
  else
    err "armbian-config not found. Install it and run again."
    exit 1
  fi
  read -r -p "After finishing armbian-config, press Enter to continue installation..."
}

install_docker() {
  log "Installing Docker from official repository"
  apt update
  apt install -y ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "${VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable docker
  systemctl restart docker
  docker --version
}

install_os_agent() {
  log "Installing os-agent 1.8.1 (aarch64)"
  wget -O /tmp/os-agent_1.8.1_linux_aarch64.deb \
    https://github.com/home-assistant/os-agent/releases/download/1.8.1/os-agent_1.8.1_linux_aarch64.deb
  dpkg -i /tmp/os-agent_1.8.1_linux_aarch64.deb
}

install_home_assistant_supervised() {
  log "Installing Home Assistant Supervised"
  wget -O /tmp/homeassistant-supervised.deb \
    https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
  BYPASS_OS_CHECK=true apt install -y /tmp/homeassistant-supervised.deb
}

post_checks() {
  log "Post-install checks"
  docker ps || true
  ha network info || true
  ha supervisor info || true
  warn "First startup may take 5-15 minutes: http://<your-device-ip>:8123"
}

main() {
  install_base_packages
  configure_networkmanager
  install_docker
  install_os_agent
  install_home_assistant_supervised
  post_checks
  log "Done."
}

main "$@"
