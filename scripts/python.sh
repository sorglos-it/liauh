#!/bin/bash

# python - Python programming language
# Install, update, uninstall, and configure Python on all Linux distributions

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

# Install Python
install_python() {
    log_info "Installing Python..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL python3 python3-pip || log_error "Failed"
    
    log_info "Python installed!"
}

# Update Python
update_python() {
    log_info "Updating Python..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL python3 python3-pip || log_error "Failed"
    
    log_info "Python updated!"
}

# Uninstall Python
uninstall_python() {
    log_info "Uninstalling Python..."
    detect_os
    
    $SUDO_PREFIX $PKG_UNINSTALL python3 python3-pip || log_error "Failed"
    
    log_info "Python uninstalled!"
}

# Configure Python
configure_python() {
    log_info "Python configured"
    log_info "See docs for configuration"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_python
        ;;
    update)
        update_python
        ;;
    uninstall)
        uninstall_python
        ;;
    config)
        configure_python
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
