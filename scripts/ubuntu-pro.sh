#!/bin/bash

# Ubuntu Pro Subscription Script
# Attaches Ubuntu Pro subscription to the system

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
    attach)
        [[ -z "$KEY" ]] && log_error "KEY variable not set"
        
        log_info "Updating package lists..."
        if ! sudo apt-get update; then
            log_error "Failed to update package lists"
        fi
        
        log_info "Installing ubuntu-advantage-tools..."
        if ! sudo apt-get install -y ubuntu-advantage-tools; then
            log_error "Failed to install ubuntu-advantage-tools"
        fi
        
        log_info "Attaching Ubuntu Pro with provided key..."
        if ! sudo pro attach "$KEY"; then
            log_error "Failed to attach Ubuntu Pro subscription"
        fi
        
        log_info "Ubuntu Pro subscription attached successfully!"
        log_info "Your system is now covered by Ubuntu Pro."
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage: ubuntu-pro.sh attach,KEY=your-token"
        exit 1
        ;;
esac
