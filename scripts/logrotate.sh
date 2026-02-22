#!/bin/bash

# logrotate - Log file rotation and compression

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure logrotate on all Linux distributions

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

# Install logrotate
install_logrotate() {
    log_info "Installing logrotate..."
    detect_os
    
    $PKG_UPDATE || true
    $PKG_INSTALL logrotate || log_error "Failed"
    
    log_info "logrotate installed!"
}

# Update logrotate
update_logrotate() {
    log_info "Updating logrotate..."
    detect_os
    
    $PKG_UPDATE || true
    $PKG_INSTALL logrotate || log_error "Failed"
    
    log_info "logrotate updated!"
}

# Uninstall logrotate
uninstall_logrotate() {
    log_info "Uninstalling logrotate..."
    detect_os
    
    $PKG_UNINSTALL logrotate || log_error "Failed"
    
    log_info "logrotate uninstalled!"
}

# Configure logrotate
configure_logrotate() {
    log_info "logrotate configuration"
    log_info "Edit /etc/logrotate.conf or /etc/logrotate.d/"
    log_info "Logrotate runs daily via cron"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_logrotate
        ;;
    update)
        update_logrotate
        ;;
    uninstall)
        uninstall_logrotate
        ;;
    config)
        configure_logrotate
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
