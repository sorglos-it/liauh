#!/bin/bash

# syslog-ng - Advanced system logging daemon
# Install, update, uninstall, and configure syslog-ng on all Linux distributions

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

# Install syslog-ng
install_syslog_ng() {
    log_info "Installing syslog-ng..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL syslog-ng || log_error "Failed"
    $SUDO_PREFIX systemctl enable syslog-ng
    $SUDO_PREFIX systemctl start syslog-ng
    
    log_info "syslog-ng installed and started!"
}

# Update syslog-ng
update_syslog_ng() {
    log_info "Updating syslog-ng..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL syslog-ng || log_error "Failed"
    
    log_info "syslog-ng updated!"
}

# Uninstall syslog-ng
uninstall_syslog_ng() {
    log_info "Uninstalling syslog-ng..."
    detect_os
    
    $SUDO_PREFIX systemctl stop syslog-ng
    $SUDO_PREFIX systemctl disable syslog-ng
    $SUDO_PREFIX $PKG_UNINSTALL syslog-ng || log_error "Failed"
    
    log_info "syslog-ng uninstalled!"
}

# Configure syslog-ng
configure_syslog_ng() {
    log_info "syslog-ng configuration"
    log_info "Edit /etc/syslog-ng/syslog-ng.conf and restart: $SUDO_PREFIX systemctl restart syslog-ng"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_syslog_ng
        ;;
    update)
        update_syslog_ng
        ;;
    uninstall)
        uninstall_syslog_ng
        ;;
    config)
        configure_syslog_ng
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
