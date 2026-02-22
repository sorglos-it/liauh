#!/bin/bash

# debian - Debian system management
# Update system packages and manage Debian distributions

set -e


# Check if we need sudo
if [[ $EUID -ne 0 ]]; then
    SUDO_PREFIX="sudo"
else
    SUDO_PREFIX=""
fi


# Parse action and parameters
FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

# Export any additional parameters
if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Log informational messages with green checkmark
log_info() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

# Log error messages with red X and exit
log_error() {
    printf "${RED}✗${NC} %s\n" "$1"
    exit 1
}

# Verify this is running on Debian
detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    [[ "${ID,,}" == "debian" ]] || log_error "This script is for Debian only"
}

# Update system packages
update_debian() {
    log_info "Updating Debian..."
    detect_os
    
    $SUDO_PREFIX apt-get update || true
    $SUDO_PREFIX apt-get upgrade -y || log_error "Failed"
    $SUDO_PREFIX apt-get autoremove -y || true
    
    log_info "Debian updated!"
}

# Perform distribution upgrade
dist_upgrade_debian() {
    log_info "Distribution upgrade..."
    detect_os
    
    $SUDO_PREFIX apt-get update || true
    $SUDO_PREFIX apt-get dist-upgrade -y || log_error "Failed"
    
    log_info "Debian dist-upgrade complete!"
}

# Route to appropriate action
case "$ACTION" in
    update)
        update_debian
        ;;
    dist-upgrade)
        dist_upgrade_debian
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
