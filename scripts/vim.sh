#!/bin/bash

# vim - Vi IMproved text editor
# Install, update, uninstall, and configure vim on all Linux distributions

set -e


# Check if we need sudo
if [[ $EUID -ne 0 ]]; then
    SUDO_PREFIX="sudo"
else
    SUDO_PREFIX=""
fi


# ============================================================================
# Parameter Parsing
# ============================================================================
FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

# ============================================================================
# Color Codes for Terminal Output
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Log success messages with green checkmark
log_info() { printf "${GREEN}✓${NC} %s\n" "$1"; }

# Log error messages with red X and exit
log_error() { printf "${RED}✗${NC} %s\n" "$1"; exit 1; }

# ============================================================================
# Operating System Detection and Package Manager Configuration
# ============================================================================
detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    OS_DISTRO="${ID,,}"
    
    case "$OS_DISTRO" in
        ubuntu|debian|raspbian|linuxmint|pop) PKG_UPDATE="apt-get update"; PKG_INSTALL="apt-get install -y"; PKG_UNINSTALL="apt-get remove -y" ;;
        fedora|rhel|centos|rocky|alma) PKG_UPDATE="dnf check-update || true"; PKG_INSTALL="dnf install -y"; PKG_UNINSTALL="dnf remove -y" ;;
        arch|archarm|manjaro|endeavouros) PKG_UPDATE="pacman -Sy"; PKG_INSTALL="pacman -S --noconfirm"; PKG_UNINSTALL="pacman -R --noconfirm" ;;
        opensuse*|sles) PKG_UPDATE="zypper refresh"; PKG_INSTALL="zypper install -y"; PKG_UNINSTALL="zypper remove -y" ;;
        alpine) PKG_UPDATE="apk update"; PKG_INSTALL="apk add"; PKG_UNINSTALL="apk del" ;;
        *) log_error "Unsupported distribution: $OS_DISTRO" ;;
    esac
}

# ============================================================================
# Vim Installation, Update, Uninstall, and Configuration Functions
# ============================================================================

# Install vim text editor
install_vim() {
    log_info "Installing vim..."
    detect_os
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL vim || log_error "Failed to install vim"
    log_info "vim installed successfully!"
    vim --version | head -1
}

# Update vim to the latest version
update_vim() {
    log_info "Updating vim..."
    detect_os
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL vim || log_error "Failed to update vim"
    log_info "vim updated successfully!"
    vim --version | head -1
}

# Uninstall vim from the system
uninstall_vim() {
    log_info "Uninstalling vim..."
    detect_os
    $SUDO_PREFIX $PKG_UNINSTALL vim || log_error "Failed to uninstall vim"
    log_info "vim uninstalled successfully!"
}

# Display vim configuration information and instructions
configure_vim() {
    log_info "vim configuration"
    log_info "Edit ~/.vimrc for configuration"
    [[ -f ~/.vimrc ]] && log_info "Found ~/.vimrc" || log_info "No ~/.vimrc found - create with: vim ~/.vimrc"
}

# ============================================================================
# Main Action Dispatcher
# ============================================================================
case "$ACTION" in
    install) install_vim ;;
    update) update_vim ;;
    uninstall) uninstall_vim ;;
    config) configure_vim ;;
    *) log_error "Unknown action: $ACTION" ;;
esac
