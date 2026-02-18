#!/bin/bash
set -e
FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
[[ -n "${FULL_PARAMS#*,}" && "${FULL_PARAMS#*,}" != "$FULL_PARAMS" ]] && while IFS='=' read -r key val; do [[ -n "$key" ]] && export "$key=$val"; done <<< "${{FULL_PARAMS#*,}/,/$'\n'}"
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
log_info() { printf "${GREEN}✓${NC} %s\n" "$1"; }
log_error() { printf "${RED}✗${NC} %s\n" "$1"; exit 1; }
detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    case "${ID,,}" in
        ubuntu|debian|raspbian|linuxmint|pop) PKG_UPDATE="apt-get update"; PKG_INSTALL="apt-get install -y"; PKG_UNINSTALL="apt-get remove -y" ;;
        fedora|rhel|centos|rocky|alma) PKG_UPDATE="dnf check-update || true"; PKG_INSTALL="dnf install -y"; PKG_UNINSTALL="dnf remove -y" ;;
        arch|manjaro|endeavouros) PKG_UPDATE="pacman -Sy"; PKG_INSTALL="pacman -S --noconfirm"; PKG_UNINSTALL="pacman -R --noconfirm" ;;
        opensuse*|sles) PKG_UPDATE="zypper refresh"; PKG_INSTALL="zypper install -y"; PKG_UNINSTALL="zypper remove -y" ;;
        alpine) PKG_UPDATE="apk update"; PKG_INSTALL="apk add"; PKG_UNINSTALL="apk del" ;;
        *) log_error "Unsupported distribution" ;;
    esac
}
case "$ACTION" in
    install) log_info "Installing htop..."; detect_os; sudo $PKG_UPDATE || true; sudo $PKG_INSTALL htop || log_error "Failed"; log_info "htop installed!"; htop --version ;;
    update) log_info "Updating htop..."; detect_os; sudo $PKG_UPDATE || true; sudo $PKG_INSTALL htop || log_error "Failed"; log_info "htop updated!"; htop --version ;;
    uninstall) log_info "Uninstalling htop..."; detect_os; sudo $PKG_UNINSTALL htop || log_error "Failed"; log_info "htop uninstalled!" ;;
    config) log_info "htop configuration"; log_info "Edit ~/.config/htop/htoprc"; [[ -f ~/.config/htop/htoprc ]] && log_info "Found htoprc" || log_info "Run 'htop' first to generate config" ;;
    *) log_error "Unknown action: $ACTION" ;;
esac
