#!/bin/bash

# Python/pip Management Script
# Install, update, uninstall, and configure Python

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

install_python() {
    log_info "Installing Python..."
    
    local version="${VERSION:-3}"
    local pm=$(detect_package_manager)
    
    log_info "Installing Python (version: $version)..."
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            if [[ "$version" == "latest" || "$version" == "3" ]]; then
                sudo apt-get install -y python3 python3-pip || log_error "Failed to install Python"
            else
                sudo apt-get install -y "python$version" "python$version-pip" || log_error "Failed to install Python $version"
            fi
            ;;
        dnf)
            if [[ "$version" == "latest" || "$version" == "3" ]]; then
                sudo dnf install -y python3 python3-pip || log_error "Failed to install Python"
            else
                sudo dnf install -y "python$version" "python$version-pip" || log_error "Failed to install Python $version"
            fi
            ;;
        yum)
            if [[ "$version" == "latest" || "$version" == "3" ]]; then
                sudo yum install -y python3 python3-pip || log_error "Failed to install Python"
            else
                sudo yum install -y "python$version" "python$version-pip" || log_error "Failed to install Python $version"
            fi
            ;;
        pacman)
            sudo pacman -S --noconfirm python python-pip || log_error "Failed to install Python"
            ;;
        zypper)
            sudo zypper install -y python3 python3-pip || log_error "Failed to install Python"
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            sudo apk add python3 py3-pip || log_error "Failed to install Python"
            ;;
    esac
    
    log_info "Python installed successfully!"
    python3 --version
    pip3 --version
}

update_python() {
    log_info "Updating Python..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get upgrade -y python3 python3-pip || log_error "Failed to update Python"
            ;;
        dnf)
            sudo dnf upgrade -y python3 python3-pip || log_error "Failed to update Python"
            ;;
        yum)
            sudo yum upgrade -y python3 python3-pip || log_error "Failed to update Python"
            ;;
        pacman)
            sudo pacman -S --noconfirm python python-pip || log_error "Failed to update Python"
            ;;
        zypper)
            sudo zypper update -y python3 python3-pip || log_error "Failed to update Python"
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            sudo apk upgrade python3 py3-pip || log_error "Failed to update Python"
            ;;
    esac
    
    log_info "Python updated successfully!"
    python3 --version
    pip3 --version
}

uninstall_python() {
    log_info "Uninstalling Python..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get remove -y python3 python3-pip || log_error "Failed to uninstall Python"
            ;;
        dnf|yum)
            sudo $pm remove -y python3 python3-pip || log_error "Failed to uninstall Python"
            ;;
        pacman)
            sudo pacman -R --noconfirm python python-pip || log_error "Failed to uninstall Python"
            ;;
        zypper)
            sudo zypper remove -y python3 python3-pip || log_error "Failed to uninstall Python"
            ;;
        apk)
            sudo apk del python3 py3-pip || log_error "Failed to uninstall Python"
            ;;
    esac
    
    log_info "Python uninstalled successfully!"
}

configure_python() {
    log_info "Configuring Python..."
    
    if [[ -n "$PIP_REQUIRE_VIRTUALENV" ]]; then
        log_info "Setting PIP_REQUIRE_VIRTUALENV..."
        echo "export PIP_REQUIRE_VIRTUALENV=$PIP_REQUIRE_VIRTUALENV" >> ~/.bashrc || log_warn "Failed to set PIP_REQUIRE_VIRTUALENV"
    fi
    
    if [[ -n "$PYTHONPATH" ]]; then
        log_info "Setting PYTHONPATH to: $PYTHONPATH..."
        echo "export PYTHONPATH=$PYTHONPATH" >> ~/.bashrc || log_warn "Failed to set PYTHONPATH"
    fi
    
    log_info "Upgrading pip..."
    pip3 install --upgrade pip || log_warn "Failed to upgrade pip"
    
    log_info "Python configuration updated!"
    python3 --version
    pip3 --version
}

case "$ACTION" in
    install)
        install_python
        ;;
    
    update)
        update_python
        ;;
    
    uninstall)
        uninstall_python
        ;;
    
    config)
        configure_python
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  python.sh install,VERSION=3"
        echo "  python.sh update"
        echo "  python.sh uninstall"
        echo "  python.sh config,PIP_REQUIRE_VIRTUALENV=true,PYTHONPATH=/usr/local/lib/python3"
        exit 1
        ;;
esac
