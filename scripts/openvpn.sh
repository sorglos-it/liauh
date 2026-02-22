#!/bin/bash

# openvpn - Virtual Private Network
# Install, update, uninstall, and configure OpenVPN on all Linux distributions

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
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            ;;
        arch|archarm|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            ;;
        *)
            log_error "Unsupported distribution"
            ;;
    esac
}

# Install OpenVPN
install_openvpn() {
    log_info "Installing openvpn..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL openvpn || log_error "Failed"
    $SUDO_PREFIX systemctl enable openvpn
    
    log_info "openvpn installed!"
}

# Update OpenVPN
update_openvpn() {
    log_info "Updating openvpn..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL openvpn || log_error "Failed"
    
    log_info "openvpn updated!"
}

# Uninstall OpenVPN
uninstall_openvpn() {
    log_info "Uninstalling openvpn..."
    detect_os
    
    $SUDO_PREFIX systemctl disable openvpn || true
    $SUDO_PREFIX $PKG_UNINSTALL openvpn || log_error "Failed"
    
    log_info "openvpn uninstalled!"
}

# Configure OpenVPN
configure_openvpn() {
    log_info "openvpn configuration"
    log_info "Place .ovpn file in /etc/openvpn/"
    log_info "Start with: $SUDO_PREFIX systemctl start openvpn@<profile-name>"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_openvpn
        ;;
    update)
        update_openvpn
        ;;
    uninstall)
        uninstall_openvpn
        ;;
    config)
        configure_openvpn
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
