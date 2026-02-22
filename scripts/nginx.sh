#!/bin/bash

# nginx - Nginx Web Server Management
# Install, update, uninstall, and configure Nginx for all distributions

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
            SVC_NAME="nginx"
            CONF_DIR="/etc/nginx"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            SVC_NAME="nginx"
            CONF_DIR="/etc/nginx"
            ;;
        arch|archarm|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            SVC_NAME="nginx"
            CONF_DIR="/etc/nginx"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            SVC_NAME="nginx"
            CONF_DIR="/etc/nginx"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            SVC_NAME="nginx"
            CONF_DIR="/etc/nginx"
            ;;
        *)
            log_error "Unsupported distribution: $OS_DISTRO"
            ;;
    esac
}

install_nginx() {
    log_info "Installing Nginx..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL nginx || log_error "Failed to install Nginx"
    
    $SUDO_PREFIX systemctl enable $SVC_NAME
    $SUDO_PREFIX systemctl start $SVC_NAME
    
    log_info "Nginx installed and started!"
}

update_nginx() {
    log_info "Updating Nginx..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL nginx || log_error "Failed to update Nginx"
    $SUDO_PREFIX systemctl restart $SVC_NAME
    
    log_info "Nginx updated!"
}

uninstall_nginx() {
    log_warn "Uninstalling Nginx..."
    detect_os
    
    $SUDO_PREFIX systemctl stop $SVC_NAME || true
    $SUDO_PREFIX systemctl disable $SVC_NAME || true
    $SUDO_PREFIX $PKG_UNINSTALL nginx || log_error "Failed to uninstall Nginx"
    
    [[ "$DELETE_CONFIG" == "yes" ]] && $SUDO_PREFIX rm -rf $CONF_DIR || true
    
    log_info "Nginx uninstalled!"
}

config_server() {
    log_info "Configuring Nginx server block..."
    detect_os
    
    [[ -z "$SERVER_NAME" ]] && log_error "SERVER_NAME not set"
    [[ -z "$ROOT_PATH" ]] && log_error "ROOT_PATH not set"
    
    log_info "Server: $SERVER_NAME"
    log_info "Root: $ROOT_PATH"
    log_info "Configure $CONF_DIR/sites-available/ manually"
    
    $SUDO_PREFIX systemctl restart $SVC_NAME
    log_info "Configuration updated!"
}

case "$ACTION" in
    install)
        install_nginx
        ;;
    update)
        update_nginx
        ;;
    uninstall)
        uninstall_nginx
        ;;
    vhosts)
        config_server
        ;;
    *)
        log_error "Unknown action: $ACTION"
        exit 1
        ;;
esac
