#!/bin/bash

# git - Version control system
# Install, update, uninstall, and configure git for all Linux distributions

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
NC='\033[0m'

log_info() { printf "${GREEN}✓${NC} %s\n" "$1"; }
log_error() { printf "${RED}✗${NC} %s\n" "$1"; exit 1; }

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

install_git() {
    log_info "Installing git..."
    detect_os
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL git || log_error "Failed to install git"
    log_info "git installed successfully!"
    git --version
}

update_git() {
    log_info "Updating git..."
    detect_os
    $SUDO_PREFIX $PKG_UPDATE || true
    $SUDO_PREFIX $PKG_INSTALL git || log_error "Failed to update git"
    log_info "git updated successfully!"
    git --version
}

uninstall_git() {
    log_info "Uninstalling git..."
    detect_os
    $SUDO_PREFIX $PKG_UNINSTALL git || log_error "Failed to uninstall git"
    log_info "git uninstalled successfully!"
}

configure_git() {
    log_info "Configuring git..."
    [[ -z "$GIT_USER" ]] && log_error "GIT_USER not set"
    [[ -z "$GIT_EMAIL" ]] && log_error "GIT_EMAIL not set"
    
    git config --global user.name "$GIT_USER"
    git config --global user.email "$GIT_EMAIL"
    log_info "git configured: $GIT_USER <$GIT_EMAIL>"
    git config --global --list | grep user
}

case "$ACTION" in
    install) install_git ;;
    update) update_git ;;
    uninstall) uninstall_git ;;
    config) configure_git ;;
    *) log_error "Unknown action: $ACTION" ;;
esac
