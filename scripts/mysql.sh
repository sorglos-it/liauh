#!/bin/bash

# mysql - MySQL relational database
# Install, update, uninstall, and configure MySQL for all distributions

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
            PKG="mysql-server"
            CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
            SERVICE="mysql"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            PKG="mysql-server"
            CONF_FILE="/etc/my.cnf"
            SERVICE="mysqld"
            ;;
        arch|archarm|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            PKG="mysql"
            CONF_FILE="/etc/mysql/my.cnf"
            SERVICE="mysqld"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            PKG="mysql-community-server"
            CONF_FILE="/etc/my.cnf"
            SERVICE="mysqld"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            PKG="mysql"
            CONF_FILE="/etc/my.cnf"
            SERVICE="mysqld"
            ;;
        *)
            log_error "Unsupported distribution: $OS_DISTRO"
            ;;
    esac
}

install_mysql() {
    log_info "Installing MySQL..."
    detect_os
    
    # Update package manager
    $SUDO_PREFIX $PKG_UPDATE || true
    
    # Install MySQL
    $SUDO_PREFIX $PKG_INSTALL $PKG || log_error "Failed to install MySQL"
    
    # Enable and start service
    $SUDO_PREFIX systemctl enable $SERVICE
    $SUDO_PREFIX systemctl start $SERVICE
    
    log_info "MySQL installed and started!"
    mysql --version || true
}

update_mysql() {
    log_info "Updating MySQL..."
    detect_os
    
    # Update package manager
    $SUDO_PREFIX $PKG_UPDATE || true
    
    # Update MySQL
    $SUDO_PREFIX $PKG_INSTALL $PKG || log_error "Failed to update MySQL"
    
    # Restart service
    $SUDO_PREFIX systemctl restart $SERVICE
    
    log_info "MySQL updated!"
}

uninstall_mysql() {
    log_warn "Uninstalling MySQL..."
    detect_os
    
    # Stop and disable service
    $SUDO_PREFIX systemctl stop $SERVICE || true
    $SUDO_PREFIX systemctl disable $SERVICE || true
    
    # Uninstall MySQL
    $SUDO_PREFIX $PKG_UNINSTALL $PKG || log_error "Failed to uninstall MySQL"
    
    # Remove data if requested
    [[ "$DELETE_DATA" == "yes" ]] && $SUDO_PREFIX rm -rf /var/lib/mysql* || true
    [[ "$DELETE_CONFIG" == "yes" ]] && $SUDO_PREFIX rm -rf /etc/mysql* || true
    
    log_info "MySQL uninstalled!"
}

config_mysql() {
    log_info "Configuring MySQL..."
    detect_os
    
    # Display connection information
    log_info "MySQL Configuration:"
    log_info "Default user: root"
    log_info "Default port: 3306"
    log_info "Socket location: /var/run/mysqld/mysqld.sock"
    
    # Ensure service is enabled and running
    $SUDO_PREFIX systemctl enable $SERVICE
    $SUDO_PREFIX systemctl start $SERVICE
    
    log_info "MySQL configured and running!"
}

case "$ACTION" in
    install)
        install_mysql
        ;;
    update)
        update_mysql
        ;;
    uninstall)
        uninstall_mysql
        ;;
    config)
        config_mysql
        ;;
    *)
        log_error "Unknown action: $ACTION"
        exit 1
        ;;
esac
