#!/bin/bash

# curl - HTTP requests utility
# Install, update, uninstall, and configure curl for all Linux distributions

set -e


# Check if we need sudo
if [[ $EUID -ne 0 ]]; then
    SUDO_PREFIX="sudo"
else
    SUDO_PREFIX=""
fi


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
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}✗${NC} %s\n" "$1"
    exit 1
}

# Detect OS and package manager
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
            log_error "Unsupported distribution: $OS_DISTRO"
            ;;
    esac
}

install_curl() {
    log_info "Installing curl..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL curl || log_error "Failed to install curl"
    
    log_info "curl installed successfully!"
    curl --version | head -1
}

update_curl() {
    log_info "Updating curl..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL curl || log_error "Failed to update curl"
    
    log_info "curl updated successfully!"
    curl --version | head -1
}

uninstall_curl() {
    log_info "Uninstalling curl..."
    detect_os
    
    $SUDO_PREFIX $PKG_UNINSTALL curl || log_error "Failed to uninstall curl"
    
    log_info "curl uninstalled successfully!"
}

configure_curl() {
    log_info "curl configuration"
    log_info "No configuration available for curl"
    log_info "Use: curl [OPTIONS] <URL>"
    curl --help | head -20
}

case "$ACTION" in
    install)
        install_curl
        ;;
    update)
        update_curl
        ;;
    uninstall)
        uninstall_curl
        ;;
    config)
        configure_curl
        ;;
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  curl.sh install"
        echo "  curl.sh update"
        echo "  curl.sh uninstall"
        echo "  curl.sh config"
        exit 1
        ;;
esac
