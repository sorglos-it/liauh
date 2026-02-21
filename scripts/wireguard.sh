#!/bin/bash

# wireguard - VPN tunnel management
# Install, update, uninstall, and configure WireGuard VPN on all Linux distributions

set -e


# Check if we need sudo
if [[ $EUID -ne 0 ]]; then
    SUDO_PREFIX="sudo"
else
    SUDO_PREFIX=""
fi


# Parse action and parameters
FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

# Export any additional parameters
if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Log informational messages with green checkmark
log_info() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

# Log error messages with red X and exit
log_error() {
    printf "${RED}✗${NC} %s\n" "$1"
    exit 1
}

# Detect operating system and set appropriate package manager commands
detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    
    case "${ID,,}" in
        ubuntu|debian|raspbian|linuxmint|pop)
            PKG_UPDATE="apt-get update"
            PKG_INSTALL="apt-get install -y"
            PKG_UNINSTALL="apt-get remove -y"
            PKG="wireguard wireguard-tools"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            PKG="wireguard-tools"
            ;;
        arch|archarm|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            PKG="wireguard-tools"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            PKG="wireguard-tools"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            PKG="wireguard-tools"
            ;;
        *)
            log_error "Unsupported distribution"
            ;;
    esac
}

# Install WireGuard
install_wireguard() {
    log_info "Installing wireguard..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL $PKG || log_error "Failed"
    
    log_info "wireguard installed!"
}

# Update WireGuard
update_wireguard() {
    log_info "Updating wireguard..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL $PKG || log_error "Failed"
    
    log_info "wireguard updated!"
}

# Uninstall WireGuard
uninstall_wireguard() {
    log_info "Uninstalling wireguard..."
    detect_os
    
    $SUDO_PREFIX $PKG_UNINSTALL $PKG || log_error "Failed"
    
    log_info "wireguard uninstalled!"
}

# Configure WireGuard
configure_wireguard() {
    log_info "wireguard configuration"
    log_info "Generate keys: wg genkey | tee privatekey | wg pubkey > publickey"
    log_info "Create /etc/wireguard/wg0.conf and bring up: $SUDO_PREFIX wg-quick up wg0"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_wireguard
        ;;
    update)
        update_wireguard
        ;;
    uninstall)
        uninstall_wireguard
        ;;
    config)
        configure_wireguard
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
