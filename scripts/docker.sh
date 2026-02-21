#!/bin/bash

# docker - Container platform
# Install, update, uninstall, and configure Docker on all Linux distributions

set -e


# Check if we need sudo
if [[ $EUID -ne 0 ]]; then
    SUDO_PREFIX="sudo"
else
    SUDO_PREFIX=""
fi


# Parse action and parameters
FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

# Export any additional parameters
if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

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
    
    OS_DISTRO="${ID,,}"
    
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

# Install Docker
install_docker() {
    log_info "Installing Docker..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL docker.io docker || log_error "Failed"
    $SUDO_PREFIX systemctl enable docker
    $SUDO_PREFIX systemctl start docker
    
    log_info "Docker installed!"
}

# Update Docker
update_docker() {
    log_info "Updating Docker..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL docker.io docker || log_error "Failed"
    $SUDO_PREFIX systemctl restart docker
    
    log_info "Docker updated!"
}

# Uninstall Docker
uninstall_docker() {
    log_info "Uninstalling Docker..."
    detect_os
    
    $SUDO_PREFIX systemctl stop docker || true
    $SUDO_PREFIX systemctl disable docker || true
    $SUDO_PREFIX $PKG_UNINSTALL docker.io docker || log_error "Failed"
    
    # Optionally delete Docker images and containers data
    [[ "$DELETE_IMAGES" == "yes" ]] && $SUDO_PREFIX rm -rf /var/lib/docker || true
    
    log_info "Docker uninstalled!"
}

# Configure Docker settings
configure_docker() {
    log_info "Docker configured"
    
    # Show storage driver if specified
    [[ -n "$STORAGE_DRIVER" ]] && log_info "Storage: $STORAGE_DRIVER"
    
    # Show logging driver if specified
    [[ -n "$LOG_DRIVER" ]] && log_info "Logging: $LOG_DRIVER"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_docker
        ;;
    update)
        update_docker
        ;;
    uninstall)
        uninstall_docker
        ;;
    config)
        configure_docker
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
