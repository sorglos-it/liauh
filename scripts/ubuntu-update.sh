#!/bin/bash

# Ubuntu System Update Script
# Handles Ubuntu version upgrades with gnupg reinstall
# Solves issues with 25.04 → 25.10 upgrades

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
        log_info "Starting Ubuntu system update..."
        
        log_info "Step 1: Update package lists..."
        sudo apt-get update || log_error "Failed to update package lists"
        
        log_info "Step 2: Reinstalling gnupg..."
        sudo apt-get install --reinstall gnupg -y || log_error "Failed to reinstall gnupg"
        
        log_info "Step 3: Upgrading packages..."
        sudo apt-get upgrade -y || log_error "Failed to upgrade packages"
        
        log_info "Step 4: Starting distribution upgrade..."
        log_warn "This may take several minutes. Press 'y' when prompted."
        sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y || log_error "Failed to upgrade distribution"
        
        log_info "Step 5: Performing release upgrade..."
        sudo do-release-upgrade -f DistUpgradeViewNonInteractive || log_error "Failed to perform release upgrade"
        
        log_info "Ubuntu update completed successfully!"
        log_warn "You may need to restart your system: sudo reboot"
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage: ubuntu-update.sh update"
        exit 1
        ;;
esac
