#!/bin/bash

# ulh Script Template
# Use this as a starting point for new system management scripts
# Parameter format: action,VAR1=val1,VAR2=val2

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

# Detect OS and set package manager variables
detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    OS_DISTRO="${ID,,}"
    
    case "$OS_DISTRO" in
        ubuntu|debian|raspbian|linuxmint|pop)
            PKG_UPDATE="apt-get update"
            PKG_INSTALL="apt-get install -y"
            PKG_UNINSTALL="apt-get remove -y"
            # Add distro-specific variables here
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

# Action functions
install_package() {
    log_info "Installing package..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL package_name || log_error "Failed to install"
    
    log_info "Package installed!"
}

update_package() {
    log_info "Updating package..."
    detect_os
    
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL package_name || log_error "Failed to update"
    
    log_info "Package updated!"
}

uninstall_package() {
    log_warn "Uninstalling package..."
    detect_os
    
    $SUDO_PREFIX $PKG_UNINSTALL package_name || log_error "Failed to uninstall"
    
    log_info "Package uninstalled!"
}

configure_package() {
    log_info "Configuring package..."
    
    # Configuration logic here
    # Access variables passed from config.yaml prompts:
    # - $VAR_NAME (any variable defined in config.yaml actions)
    
    log_info "Configuration complete!"
}

# Main switch
case "$ACTION" in
    install)
        install_package
        ;;
    update)
        update_package
        ;;
    uninstall)
        uninstall_package
        ;;
    config)
        configure_package
        ;;
    *)
        log_error "Unknown action: $ACTION"
        exit 1
        ;;
esac
