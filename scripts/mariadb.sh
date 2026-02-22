#!/bin/bash

# mariadb - MariaDB Database Server Management
# Install, update, uninstall, and configure MariaDB for all distributions

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
            PKG="mariadb-server"
            CONF_FILE="/etc/mysql/mariadb.conf.d/50-server.cnf"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            PKG="mariadb-server"
            CONF_FILE="/etc/my.cnf.d/mariadb-server.cnf"
            ;;
        arch|archarm|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            PKG="mariadb"
            CONF_FILE="/etc/mysql/my.cnf"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            PKG="mariadb"
            CONF_FILE="/etc/my.cnf"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            PKG="mariadb"
            CONF_FILE="/etc/my.cnf"
            ;;
        *)
            log_error "Unsupported distribution: $OS_DISTRO"
            ;;
    esac
}

install_mariadb() {
    log_info "Installing MariaDB..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL $PKG || log_error "Failed to install MariaDB"
    
    $SUDO_PREFIX systemctl enable mariadb
    $SUDO_PREFIX systemctl start mariadb
    
    log_info "MariaDB installed and started!"
}

update_mariadb() {
    log_info "Updating MariaDB..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL $PKG || log_error "Failed to update MariaDB"
    $SUDO_PREFIX systemctl restart mariadb
    
    log_info "MariaDB updated!"
}

uninstall_mariadb() {
    log_warn "Uninstalling MariaDB..."
    detect_os
    
    $SUDO_PREFIX systemctl stop mariadb || true
    $SUDO_PREFIX systemctl disable mariadb || true
    $SUDO_PREFIX $PKG_UNINSTALL $PKG || log_error "Failed to uninstall MariaDB"
    
    [[ "$DELETE_DATA" == "yes" ]] && $SUDO_PREFIX rm -rf /var/lib/mysql || true
    [[ "$DELETE_CONFIG" == "yes" ]] && $SUDO_PREFIX rm -rf /etc/mysql* || true
    
    log_info "MariaDB uninstalled!"
}

config_mariadb() {
    log_info "Configuring MariaDB..."
    detect_os
    
    [[ ! -f "$CONF_FILE" ]] && log_error "Config file not found: $CONF_FILE"
    
    [[ -n "$MAX_CONNECTIONS" ]] && $SUDO_PREFIX sed -i "s/^max_connections.*/max_connections = $MAX_CONNECTIONS/" "$CONF_FILE"
    [[ -n "$INNODB_BUFFER" ]] && $SUDO_PREFIX sed -i "s/^innodb_buffer_pool_size.*/innodb_buffer_pool_size = $INNODB_BUFFER/" "$CONF_FILE"
    [[ -n "$BIND_ADDRESS" ]] && $SUDO_PREFIX sed -i "s/^bind-address.*/bind-address = $BIND_ADDRESS/" "$CONF_FILE"
    
    $SUDO_PREFIX systemctl restart mariadb
    log_info "MariaDB configured!"
}

case "$ACTION" in
    install)
        install_mariadb
        ;;
    update)
        update_mariadb
        ;;
    uninstall)
        uninstall_mariadb
        ;;
    config)
        config_mariadb
        ;;
    *)
        log_error "Unknown action: $ACTION"
        exit 1
        ;;
esac
