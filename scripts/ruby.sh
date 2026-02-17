#!/bin/bash

# Ruby Management Script
# Install, update, uninstall, and configure Ruby

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

install_ruby() {
    log_info "Installing Ruby..."
    
    local version="${VERSION:-latest}"
    local pm=$(detect_package_manager)
    
    log_info "Installing Ruby (version: $version)..."
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get install -y ruby ruby-dev || log_error "Failed to install Ruby"
            ;;
        dnf)
            sudo dnf install -y ruby ruby-devel || log_error "Failed to install Ruby"
            ;;
        yum)
            sudo yum install -y ruby ruby-devel || log_error "Failed to install Ruby"
            ;;
        pacman)
            sudo pacman -S --noconfirm ruby || log_error "Failed to install Ruby"
            ;;
        zypper)
            sudo zypper install -y ruby ruby-devel || log_error "Failed to install Ruby"
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            sudo apk add ruby ruby-dev || log_error "Failed to install Ruby"
            ;;
    esac
    
    log_info "Ruby installed successfully!"
    ruby --version
    gem --version
}

update_ruby() {
    log_info "Updating Ruby..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get upgrade -y ruby ruby-dev || log_error "Failed to update Ruby"
            ;;
        dnf)
            sudo dnf upgrade -y ruby ruby-devel || log_error "Failed to update Ruby"
            ;;
        yum)
            sudo yum upgrade -y ruby ruby-devel || log_error "Failed to update Ruby"
            ;;
        pacman)
            sudo pacman -S --noconfirm ruby || log_error "Failed to update Ruby"
            ;;
        zypper)
            sudo zypper update -y ruby ruby-devel || log_error "Failed to update Ruby"
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            sudo apk upgrade ruby ruby-dev || log_error "Failed to update Ruby"
            ;;
    esac
    
    log_info "Ruby updated successfully!"
    ruby --version
    gem --version
}

uninstall_ruby() {
    log_info "Uninstalling Ruby..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get remove -y ruby ruby-dev || log_error "Failed to uninstall Ruby"
            ;;
        dnf|yum)
            sudo $pm remove -y ruby ruby-devel || log_error "Failed to uninstall Ruby"
            ;;
        pacman)
            sudo pacman -R --noconfirm ruby || log_error "Failed to uninstall Ruby"
            ;;
        zypper)
            sudo zypper remove -y ruby ruby-devel || log_error "Failed to uninstall Ruby"
            ;;
        apk)
            sudo apk del ruby ruby-dev || log_error "Failed to uninstall Ruby"
            ;;
    esac
    
    log_info "Ruby uninstalled successfully!"
}

configure_ruby() {
    log_info "Configuring Ruby..."
    
    log_info "Updating RubyGems..."
    sudo gem update --system || log_warn "Failed to update RubyGems"
    
    if [[ -n "$GEM_HOME" ]]; then
        log_info "Setting GEM_HOME to: $GEM_HOME..."
        mkdir -p "$GEM_HOME"
        echo "export GEM_HOME=$GEM_HOME" >> ~/.bashrc || log_warn "Failed to set GEM_HOME"
    fi
    
    if [[ -n "$GEM_PATH" ]]; then
        log_info "Setting GEM_PATH to: $GEM_PATH..."
        echo "export GEM_PATH=$GEM_PATH" >> ~/.bashrc || log_warn "Failed to set GEM_PATH"
    fi
    
    log_info "Ruby configuration updated!"
    ruby --version
    gem --version
}

case "$ACTION" in
    install)
        install_ruby
        ;;
    
    update)
        update_ruby
        ;;
    
    uninstall)
        uninstall_ruby
        ;;
    
    config)
        configure_ruby
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  ruby.sh install,VERSION=latest"
        echo "  ruby.sh update"
        echo "  ruby.sh uninstall"
        echo "  ruby.sh config,GEM_HOME=~/.gem,GEM_PATH=~/.gem"
        exit 1
        ;;
esac
