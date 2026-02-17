#!/bin/bash

# Debian System Management Script
# Update and manage Debian system

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

case "$ACTION" in
    update)
        log_info "Starting Debian system update..."
        
        log_info "Step 1: Update package lists..."
        sudo apt-get update || log_error "Failed to update package lists"
        
        log_info "Step 2: Upgrading packages..."
        sudo apt-get upgrade -y || log_error "Failed to upgrade packages"
        
        log_info "Step 3: Distribution upgrade..."
        sudo apt-get dist-upgrade -y || log_error "Failed to perform distribution upgrade"
        
        log_info "Step 4: Cleaning up..."
        sudo apt-get autoclean || log_warn "Failed to autoclean packages"
        sudo apt-get autoremove -y || log_warn "Failed to autoremove packages"
        
        log_info "Debian system updated successfully!"
        log_warn "You may need to restart your system: sudo reboot"
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage: debian.sh update"
        exit 1
        ;;
esac
