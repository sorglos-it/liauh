#!/bin/bash

# wget - HTTP/FTP download utility
# Install, update, uninstall, and configure wget for all Linux distributions

set -e

FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}✗${NC} %s\n" "$1"
    exit 1
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_DISTRO="${ID,,}"
    else
        log_error "Cannot detect OS"
    fi
    
    case "$OS_DISTRO" in
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
        arch|manjaro|endeavouros)
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
            log_error "Unsupported distribution: $OS_DISTRO"
            ;;
    esac
}

install_wget() {
    log_info "Installing wget..."
    detect_os
    
    sudo $PKG_UPDATE || true
    sudo $PKG_INSTALL wget || log_error "Failed to install wget"
    
    log_info "wget installed successfully!"
    wget --version | head -1
}

update_wget() {
    log_info "Updating wget..."
    detect_os
    
    sudo $PKG_UPDATE || true
    sudo $PKG_INSTALL wget || log_error "Failed to update wget"
    
    log_info "wget updated successfully!"
    wget --version | head -1
}

uninstall_wget() {
    log_info "Uninstalling wget..."
    detect_os
    
    sudo $PKG_UNINSTALL wget || log_error "Failed to uninstall wget"
    
    log_info "wget uninstalled successfully!"
}

configure_wget() {
    log_info "wget configuration"
    log_info "No configuration available for wget"
    log_info "Use: wget [OPTIONS] <URL>"
    wget --help | head -20
}

case "$ACTION" in
    install)
        install_wget
        ;;
    update)
        update_wget
        ;;
    uninstall)
        uninstall_wget
        ;;
    config)
        configure_wget
        ;;
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  wget.sh install"
        echo "  wget.sh update"
        echo "  wget.sh uninstall"
        echo "  wget.sh config"
        exit 1
        ;;
esac
