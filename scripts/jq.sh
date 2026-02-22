#!/bin/bash

# jq - JSON query processor

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure jq on all Linux distributions

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

# Install jq
install_jq() {
    log_info "Installing jq..."
    detect_os
    
    $PKG_UPDATE || true
    $PKG_INSTALL jq || log_error "Failed"
    
    log_info "jq installed!"
    jq --version
}

# Update jq
update_jq() {
    log_info "Updating jq..."
    detect_os
    
    $PKG_UPDATE || true
    $PKG_INSTALL jq || log_error "Failed"
    
    log_info "jq updated!"
    jq --version
}

# Uninstall jq
uninstall_jq() {
    log_info "Uninstalling jq..."
    detect_os
    
    $PKG_UNINSTALL jq || log_error "Failed"
    
    log_info "jq uninstalled!"
}

# Configure jq
configure_jq() {
    log_info "jq - JSON query processor"
    log_info "Usage: jq '.field' file.json"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_jq
        ;;
    update)
        update_jq
        ;;
    uninstall)
        uninstall_jq
        ;;
    config)
        configure_jq
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
