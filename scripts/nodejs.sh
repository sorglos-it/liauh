#!/bin/bash

# nodejs - Node.js JavaScript runtime and npm package manager

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure Node.js on all Linux distributions

set -e


# Check if we need sudo


# Parse action from first parameter
ACTION="${1%%,*}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Log informational messages with green checkmark

# Log error messages with red X and exit

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

# Install Node.js
install_nodejs() {
    log_info "Installing Node.js..."
    detect_os
    
    $PKG_UPDATE || true
    $PKG_INSTALL nodejs npm || log_error "Failed"
    
    log_info "Node.js installed!"
}

# Update Node.js
update_nodejs() {
    log_info "Updating Node.js..."
    detect_os
    
    $PKG_UPDATE || true
    $PKG_INSTALL nodejs npm || log_error "Failed"
    
    log_info "Node.js updated!"
}

# Uninstall Node.js
uninstall_nodejs() {
    log_info "Uninstalling Node.js..."
    detect_os
    
    $PKG_UNINSTALL nodejs npm || log_error "Failed"
    
    log_info "Node.js uninstalled!"
}

# Configure Node.js
configure_nodejs() {
    log_info "Node.js configured"
    log_info "See docs for configuration"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_nodejs
        ;;
    update)
        update_nodejs
        ;;
    uninstall)
        uninstall_nodejs
        ;;
    config)
        configure_nodejs
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
