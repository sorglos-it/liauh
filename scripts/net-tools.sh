#!/bin/bash

# net-tools - Network utilities (ifconfig, netstat, arp, route)
# Install, update, uninstall, and configure net-tools on all Linux distributions

set -e


# Check if we need sudo
if [[ $EUID -ne 0 ]]; then
    SUDO_PREFIX="sudo"
else
    SUDO_PREFIX=""
fi


# Parse action from first parameter
ACTION="${1%%,*}"

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

# Install net-tools
install_net_tools() {
    log_info "Installing net-tools..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL net-tools || log_error "Failed"
    
    log_info "net-tools installed!"
}

# Update net-tools
update_net_tools() {
    log_info "Updating net-tools..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL net-tools || log_error "Failed"
    
    log_info "net-tools updated!"
}

# Uninstall net-tools
uninstall_net_tools() {
    log_info "Uninstalling net-tools..."
    detect_os
    
    $SUDO_PREFIX $PKG_UNINSTALL net-tools || log_error "Failed"
    
    log_info "net-tools uninstalled!"
}

# Configure net-tools
configure_net_tools() {
    log_info "net-tools includes: ifconfig, netstat, arp, route"
    ifconfig --version 2>/dev/null || log_info "Use 'ifconfig' for network info"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_net_tools
        ;;
    update)
        update_net_tools
        ;;
    uninstall)
        uninstall_net_tools
        ;;
    config)
        configure_net_tools
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
