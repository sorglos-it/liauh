#!/bin/bash

# build-essential - C/C++ compiler and development tools

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure build-essential on all Linux distributions

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
            PKG="build-essential"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf groupinstall -y"
            PKG_UNINSTALL="dnf groupremove -y"
            PKG="'Development Tools'"
            ;;
        arch|archarm|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            PKG="base-devel"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y -t pattern"
            PKG_UNINSTALL="zypper remove -y -t pattern"
            PKG="devel_basis"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            PKG="build-base"
            ;;
        *)
            log_error "Unsupported distribution"
            ;;
    esac
}

# Install build-essential tools
install_build_essential() {
    log_info "Installing build-essential..."
    detect_os
    
    $PKG_UPDATE || true
    $PKG_INSTALL $PKG || log_error "Failed"
    
    log_info "build-essential installed!"
}

# Update build-essential tools
update_build_essential() {
    log_info "Updating build-essential..."
    detect_os
    
    $PKG_UPDATE || true
    $PKG_INSTALL $PKG || log_error "Failed"
    
    log_info "build-essential updated!"
}

# Uninstall build-essential tools
uninstall_build_essential() {
    log_info "Uninstalling build-essential..."
    detect_os
    
    $PKG_UNINSTALL $PKG || log_error "Failed"
    
    log_info "build-essential uninstalled!"
}

# Configure and show build-essential information
configure_build_essential() {
    log_info "build-essential includes: gcc, g++, make, gdb"
    gcc --version | head -1
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_build_essential
        ;;
    update)
        update_build_essential
        ;;
    uninstall)
        uninstall_build_essential
        ;;
    config)
        configure_build_essential
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
