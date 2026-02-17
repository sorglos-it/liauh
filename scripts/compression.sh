#!/bin/bash

# Compression Tools Script
# Installs/uninstalls zip and unzip on all platforms

set -e

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

log_warn() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}✗${NC} %s\n" "$1"
    exit 1
}

detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v apk &>/dev/null; then
        echo "apk"
    else
        log_error "Could not detect package manager"
    fi
}

install_packages() {
    local pm=$(detect_package_manager)
    
    log_info "Installing zip and unzip..."
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get install -y zip unzip || log_error "Failed to install packages with apt"
            ;;
        dnf)
            sudo dnf install -y zip unzip || log_error "Failed to install packages with dnf"
            ;;
        yum)
            sudo yum install -y zip unzip || log_error "Failed to install packages with yum"
            ;;
        pacman)
            sudo pacman -S --noconfirm zip unzip || log_error "Failed to install packages with pacman"
            ;;
        zypper)
            sudo zypper install -y zip unzip || log_error "Failed to install packages with zypper"
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            sudo apk add zip unzip || log_error "Failed to install packages with apk"
            ;;
        *)
            log_error "Unknown package manager: $pm"
            ;;
    esac
    
    log_info "zip and unzip installed successfully!"
}

uninstall_packages() {
    local pm=$(detect_package_manager)
    
    log_info "Uninstalling zip and unzip..."
    
    case "$pm" in
        apt)
            sudo apt-get remove -y zip unzip || log_error "Failed to uninstall packages with apt"
            ;;
        dnf)
            sudo dnf remove -y zip unzip || log_error "Failed to uninstall packages with dnf"
            ;;
        yum)
            sudo yum remove -y zip unzip || log_error "Failed to uninstall packages with yum"
            ;;
        pacman)
            sudo pacman -R --noconfirm zip unzip || log_error "Failed to uninstall packages with pacman"
            ;;
        zypper)
            sudo zypper remove -y zip unzip || log_error "Failed to uninstall packages with zypper"
            ;;
        apk)
            sudo apk del zip unzip || log_error "Failed to uninstall packages with apk"
            ;;
        *)
            log_error "Unknown package manager: $pm"
            ;;
    esac
    
    log_info "zip and unzip uninstalled successfully!"
}

case "$ACTION" in
    install)
        install_packages
        ;;
    
    uninstall)
        uninstall_packages
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  compression.sh install     (install zip and unzip)"
        echo "  compression.sh uninstall   (uninstall zip and unzip)"
        exit 1
        ;;
esac
