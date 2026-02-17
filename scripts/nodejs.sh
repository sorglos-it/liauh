#!/bin/bash

# Node.js/npm Management Script
# Install, update, uninstall, and configure Node.js

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

install_nodejs() {
    log_info "Installing Node.js..."
    
    local version="${VERSION:-latest}"
    local pm=$(detect_package_manager)
    
    log_info "Installing Node.js (version: $version)..."
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            if [[ "$version" == "latest" ]]; then
                sudo apt-get install -y nodejs npm || log_error "Failed to install Node.js"
            else
                sudo apt-get install -y "nodejs=$version*" || log_error "Failed to install Node.js version $version"
            fi
            ;;
        dnf)
            if [[ "$version" == "latest" ]]; then
                sudo dnf install -y nodejs npm || log_error "Failed to install Node.js"
            else
                sudo dnf install -y "nodejs-$version" || log_error "Failed to install Node.js version $version"
            fi
            ;;
        yum)
            if [[ "$version" == "latest" ]]; then
                sudo yum install -y nodejs npm || log_error "Failed to install Node.js"
            else
                sudo yum install -y "nodejs-$version" || log_error "Failed to install Node.js version $version"
            fi
            ;;
        pacman)
            sudo pacman -S --noconfirm nodejs npm || log_error "Failed to install Node.js"
            ;;
        zypper)
            sudo zypper install -y nodejs npm || log_error "Failed to install Node.js"
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            sudo apk add nodejs npm || log_error "Failed to install Node.js"
            ;;
    esac
    
    log_info "Node.js installed successfully!"
    node --version
    npm --version
}

update_nodejs() {
    log_info "Updating Node.js..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get upgrade -y nodejs npm || log_error "Failed to update Node.js"
            ;;
        dnf)
            sudo dnf upgrade -y nodejs npm || log_error "Failed to update Node.js"
            ;;
        yum)
            sudo yum upgrade -y nodejs npm || log_error "Failed to update Node.js"
            ;;
        pacman)
            sudo pacman -S --noconfirm nodejs npm || log_error "Failed to update Node.js"
            ;;
        zypper)
            sudo zypper update -y nodejs npm || log_error "Failed to update Node.js"
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            sudo apk upgrade nodejs npm || log_error "Failed to update Node.js"
            ;;
    esac
    
    log_info "Node.js updated successfully!"
    node --version
    npm --version
}

uninstall_nodejs() {
    log_info "Uninstalling Node.js..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get remove -y nodejs npm || log_error "Failed to uninstall Node.js"
            ;;
        dnf|yum)
            sudo $pm remove -y nodejs npm || log_error "Failed to uninstall Node.js"
            ;;
        pacman)
            sudo pacman -R --noconfirm nodejs npm || log_error "Failed to uninstall Node.js"
            ;;
        zypper)
            sudo zypper remove -y nodejs npm || log_error "Failed to uninstall Node.js"
            ;;
        apk)
            sudo apk del nodejs npm || log_error "Failed to uninstall Node.js"
            ;;
    esac
    
    log_info "Node.js uninstalled successfully!"
}

configure_nodejs() {
    log_info "Configuring Node.js..."
    
    log_info "Setting npm registry..."
    npm config set registry https://registry.npmjs.org/ || log_warn "Failed to set npm registry"
    
    if [[ -n "$NPM_PREFIX" ]]; then
        log_info "Setting npm prefix to: $NPM_PREFIX..."
        npm config set prefix "$NPM_PREFIX" || log_warn "Failed to set npm prefix"
    fi
    
    if [[ -n "$NODE_PATH" ]]; then
        log_info "Setting NODE_PATH to: $NODE_PATH..."
        echo "export NODE_PATH=$NODE_PATH" >> ~/.bashrc || log_warn "Failed to set NODE_PATH"
    fi
    
    log_info "Node.js configuration updated!"
    npm config list
}

case "$ACTION" in
    install)
        install_nodejs
        ;;
    
    update)
        update_nodejs
        ;;
    
    uninstall)
        uninstall_nodejs
        ;;
    
    config)
        configure_nodejs
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  nodejs.sh install,VERSION=latest"
        echo "  nodejs.sh update"
        echo "  nodejs.sh uninstall"
        echo "  nodejs.sh config,NPM_PREFIX=/usr/local,NODE_PATH=/usr/local/lib/node_modules"
        exit 1
        ;;
esac
