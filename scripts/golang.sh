#!/bin/bash

# Go/Golang Management Script
# Install, update, uninstall, and configure Go

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

install_golang() {
    log_info "Installing Go..."
    
    local pm=$(detect_package_manager)
    
    log_info "Installing Go..."
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get install -y golang-go || log_error "Failed to install Go"
            ;;
        dnf)
            sudo dnf install -y golang || log_error "Failed to install Go"
            ;;
        yum)
            sudo yum install -y golang || log_error "Failed to install Go"
            ;;
        pacman)
            sudo pacman -S --noconfirm go || log_error "Failed to install Go"
            ;;
        zypper)
            sudo zypper install -y go || log_error "Failed to install Go"
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            sudo apk add go || log_error "Failed to install Go"
            ;;
    esac
    
    log_info "Go installed successfully!"
    go version
}

update_golang() {
    log_info "Updating Go..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get upgrade -y golang-go || log_error "Failed to update Go"
            ;;
        dnf)
            sudo dnf upgrade -y golang || log_error "Failed to update Go"
            ;;
        yum)
            sudo yum upgrade -y golang || log_error "Failed to update Go"
            ;;
        pacman)
            sudo pacman -S --noconfirm go || log_error "Failed to update Go"
            ;;
        zypper)
            sudo zypper update -y go || log_error "Failed to update Go"
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            sudo apk upgrade go || log_error "Failed to update Go"
            ;;
    esac
    
    log_info "Go updated successfully!"
    go version
}

uninstall_golang() {
    log_info "Uninstalling Go..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get remove -y golang-go || log_error "Failed to uninstall Go"
            ;;
        dnf|yum)
            sudo $pm remove -y golang || log_error "Failed to uninstall Go"
            ;;
        pacman)
            sudo pacman -R --noconfirm go || log_error "Failed to uninstall Go"
            ;;
        zypper)
            sudo zypper remove -y go || log_error "Failed to uninstall Go"
            ;;
        apk)
            sudo apk del go || log_error "Failed to uninstall Go"
            ;;
    esac
    
    log_info "Go uninstalled successfully!"
}

configure_golang() {
    log_info "Configuring Go..."
    
    if [[ -n "$GOPATH" ]]; then
        log_info "Setting GOPATH to: $GOPATH..."
        mkdir -p "$GOPATH"
        echo "export GOPATH=$GOPATH" >> ~/.bashrc || log_warn "Failed to set GOPATH"
    fi
    
    if [[ -n "$GOROOT" ]]; then
        log_info "Setting GOROOT to: $GOROOT..."
        echo "export GOROOT=$GOROOT" >> ~/.bashrc || log_warn "Failed to set GOROOT"
    fi
    
    log_info "Go configuration updated!"
    go version
}

case "$ACTION" in
    install)
        install_golang
        ;;
    
    update)
        update_golang
        ;;
    
    uninstall)
        uninstall_golang
        ;;
    
    config)
        configure_golang
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  golang.sh install"
        echo "  golang.sh update"
        echo "  golang.sh uninstall"
        echo "  golang.sh config,GOPATH=~/go,GOROOT=/usr/local/go"
        exit 1
        ;;
esac
