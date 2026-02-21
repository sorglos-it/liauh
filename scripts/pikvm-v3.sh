#!/bin/bash

# pikvm-v3 - PiKVM v3 management for Raspberry Pi 4
# Update system and manage PiKVM-specific features (OLED, VNC, ISO mounting)

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

# Verify this is running on Arch Linux for PiKVM
detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    [[ "${ID,,}" == "archarm" ]] || log_error "This script is for Arch (PiKVM v3) only"
}

# Update system packages
update_pikvm() {
    log_info "Updating PiKVM v3..."
    detect_os
    
    $SUDO_PREFIX pacman -Syu --noconfirm || log_error "Failed"
    
    log_info "PiKVM v3 updated!"
}

# Mount ISO storage directory with write permissions
mount_iso() {
    log_info "Mounting ISO directory..."
    detect_os
    
    $SUDO_PREFIX mount -o remount,rw /mnt/msd || log_error "Failed"
    
    log_info "ISO directory mounted (rw)!"
}

# Dismount ISO storage directory (read-only)
dismount_iso() {
    log_info "Dismounting ISO directory..."
    detect_os
    
    $SUDO_PREFIX mount -o remount,ro /mnt/msd || log_error "Failed"
    
    log_info "ISO directory dismounted (ro)!"
}

# Enable OLED display service
enable_oled() {
    log_info "Enabling OLED..."
    detect_os
    
    $SUDO_PREFIX systemctl enable --now pikvm-oled || log_error "Failed"
    
    log_info "OLED enabled!"
}

# Enable VNC service
enable_vnc() {
    log_info "Enabling VNC..."
    detect_os
    
    $SUDO_PREFIX systemctl enable --now vncserver-x11-serviced || log_error "Failed"
    
    log_info "VNC enabled!"
}

# Route to appropriate action
case "$ACTION" in
    update)
        update_pikvm
        ;;
    mount-iso)
        mount_iso
        ;;
    dismount-iso)
        dismount_iso
        ;;
    oled-enable)
        enable_oled
        ;;
    vnc-enable)
        enable_vnc
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
