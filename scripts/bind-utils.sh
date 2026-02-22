#!/bin/bash

# bind-utils - DNS tools and utilities
# Install, update, uninstall, and configure BIND utilities on all Linux distributions

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
            PKG="bind9-utils"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            PKG="bind-utils"
            ;;
        arch|archarm|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            PKG="bind-tools"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            PKG="bind-utils"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            PKG="bind-tools"
            ;;
        *)
            log_error "Unsupported distribution"
            ;;
    esac
}

# Install BIND utilities
install_bind_utils() {
    log_info "Installing bind-utils..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL $PKG || log_error "Failed"
    
    log_info "bind-utils installed!"
}

# Update BIND utilities
update_bind_utils() {
    log_info "Updating bind-utils..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL $PKG || log_error "Failed"
    
    log_info "bind-utils updated!"
}

# Uninstall BIND utilities
uninstall_bind_utils() {
    log_info "Uninstalling bind-utils..."
    detect_os
    
    $SUDO_PREFIX $PKG_UNINSTALL $PKG || log_error "Failed"
    
    log_info "bind-utils uninstalled!"
}

# Configure and show BIND utilities information
configure_bind_utils() {
    log_info "bind-utils includes: dig, nslookup, host"
    dig --version | head -1
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_bind_utils
        ;;
    update)
        update_bind_utils
        ;;
    uninstall)
        uninstall_bind_utils
        ;;
    config)
        configure_bind_utils
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
