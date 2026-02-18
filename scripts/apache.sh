#!/bin/bash

# Apache Web Server Management
# Install, update, uninstall, and configure Apache for all distributions

set -e

FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}✗${NC} %s\n" "$1"
    exit 1
}

detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    OS_DISTRO="${ID,,}"
    
    case "$OS_DISTRO" in
        ubuntu|debian|raspbian|linuxmint|pop)
            PKG_UPDATE="apt-get update"
            PKG_INSTALL="apt-get install -y"
            PKG_UNINSTALL="apt-get remove -y"
            SVC_NAME="apache2"
            CONF_DIR="/etc/apache2"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            SVC_NAME="httpd"
            CONF_DIR="/etc/httpd"
            ;;
        arch|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            SVC_NAME="apache"
            CONF_DIR="/etc/httpd"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            SVC_NAME="apache2"
            CONF_DIR="/etc/apache2"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            SVC_NAME="apache2"
            CONF_DIR="/etc/apache2"
            ;;
        *)
            log_error "Unsupported distribution: $OS_DISTRO"
            ;;
    esac
}

install_apache() {
    log_info "Installing Apache..."
    detect_os
    
    sudo $PKG_UPDATE || true
    sudo $PKG_INSTALL apache2 httpd || log_error "Failed to install Apache"
    
    sudo systemctl enable $SVC_NAME
    sudo systemctl start $SVC_NAME
    
    log_info "Apache installed and started!"
}

update_apache() {
    log_info "Updating Apache..."
    detect_os
    
    sudo $PKG_UPDATE || true
    sudo $PKG_INSTALL apache2 httpd || log_error "Failed to update Apache"
    sudo systemctl restart $SVC_NAME
    
    log_info "Apache updated!"
}

uninstall_apache() {
    log_warn "Uninstalling Apache..."
    detect_os
    
    sudo systemctl stop $SVC_NAME || true
    sudo systemctl disable $SVC_NAME || true
    sudo $PKG_UNINSTALL apache2 httpd || log_error "Failed to uninstall Apache"
    
    [[ "$DELETE_CONFIG" == "yes" ]] && sudo rm -rf $CONF_DIR || true
    
    log_info "Apache uninstalled!"
}

config_vhosts() {
    log_info "Configuring Virtual Hosts..."
    detect_os
    
    [[ -z "$VHOST_NAME" ]] && log_error "VHOST_NAME not set"
    [[ -z "$VHOST_ROOT" ]] && log_error "VHOST_ROOT not set"
    
    log_info "Virtual Host: $VHOST_NAME"
    log_info "Root: $VHOST_ROOT"
    log_info "Configure $CONF_DIR manually"
    
    sudo systemctl restart $SVC_NAME
    log_info "Configuration updated!"
}

case "$ACTION" in
    install)
        install_apache
        ;;
    update)
        update_apache
        ;;
    uninstall)
        uninstall_apache
        ;;
    vhosts)
        config_vhosts
        ;;
    *)
        log_error "Unknown action: $ACTION"
        exit 1
        ;;
esac
