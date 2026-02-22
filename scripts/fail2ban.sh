#!/bin/bash

# fail2ban - Intrusion prevention system
# Install, update, uninstall, and configure fail2ban on all Linux distributions

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

# Install fail2ban
install_fail2ban() {
    log_info "Installing fail2ban..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL fail2ban || log_error "Failed"
    $SUDO_PREFIX systemctl enable fail2ban
    $SUDO_PREFIX systemctl start fail2ban
    
    log_info "fail2ban installed and started!"
}

# Update fail2ban
update_fail2ban() {
    log_info "Updating fail2ban..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL fail2ban || log_error "Failed"
    
    log_info "fail2ban updated!"
}

# Uninstall fail2ban
uninstall_fail2ban() {
    log_info "Uninstalling fail2ban..."
    detect_os
    
    $SUDO_PREFIX systemctl stop fail2ban
    $SUDO_PREFIX systemctl disable fail2ban
    $SUDO_PREFIX $PKG_UNINSTALL fail2ban || log_error "Failed"
    
    log_info "fail2ban uninstalled!"
}

# Configure fail2ban
configure_fail2ban() {
    log_info "fail2ban configuration"
    log_info "Copy /etc/fail2ban/jail.conf to /etc/fail2ban/jail.local and edit"
    log_info "Then: $SUDO_PREFIX systemctl restart fail2ban"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_fail2ban
        ;;
    update)
        update_fail2ban
        ;;
    uninstall)
        uninstall_fail2ban
        ;;
    config)
        configure_fail2ban
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
