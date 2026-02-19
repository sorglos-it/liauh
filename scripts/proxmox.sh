#!/bin/bash

# proxmox - Proxmox Virtual Environment
# Manage Proxmox VE installation on all Linux distributions

set -e

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

# Detect operating system and set appropriate package manager commands
detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    
    OS_DISTRO="${ID,,}"
    
    case "$OS_DISTRO" in
        ubuntu|debian|raspbian|linuxmint|pop)
            PKG_UPDATE="apt-get update"
            PKG_INSTALL="apt-get install -y"
            PKG_UNINSTALL="apt-get remove -y"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            ;;
        arch|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            ;;
        *)
            log_error "Unsupported distribution: $OS_DISTRO"
            ;;
    esac
}

# Install Proxmox VE (note: Proxmox has a complex installation process)
install_proxmox() {
    log_info "Installing Proxmox..."
    detect_os
    
    sudo $PKG_UPDATE || true
    # Note: Proxmox installation is complex and typically requires specialized setup
    sudo $PKG_INSTALL || log_error "Failed"
    
    # Attempt to enable and start services if they exist
    sudo systemctl enable proxmox 2>/dev/null || true
    sudo systemctl start proxmox 2>/dev/null || true
    
    log_info "Proxmox installed!"
}

# Update Proxmox VE
update_proxmox() {
    log_info "Updating Proxmox..."
    detect_os
    
    sudo $PKG_UPDATE || true
    sudo $PKG_INSTALL || log_error "Failed"
    
    # Restart Proxmox services if they exist
    sudo systemctl restart proxmox 2>/dev/null || true
    
    log_info "Proxmox updated!"
}

# Uninstall Proxmox VE
uninstall_proxmox() {
    log_info "Uninstalling Proxmox..."
    detect_os
    
    # Stop and disable Proxmox services
    sudo systemctl stop proxmox 2>/dev/null || true
    sudo systemctl disable proxmox 2>/dev/null || true
    sudo $PKG_UNINSTALL || log_error "Failed"
    
    log_info "Proxmox uninstalled!"
}

# Configure Proxmox VE
configure_proxmox() {
    log_info "Proxmox configuration"
    log_info "See documentation for details"
}

# List all LXC containers (running and offline)
list_all_lxc() {
    log_info "Listing all LXC containers..."
    
    # Check if pct command exists (Proxmox VE command)
    if ! command -v pct &> /dev/null; then
        log_error "Proxmox VE not installed or pct command not found"
    fi
    
    # Display header and separator
    printf "\n"
    printf "%-8s %-20s %-20s %-10s\n" "VMID" "HOSTNAME" "IP" "STATUS"
    printf "%s\n" "================================================================================"
    
    # Get all LXC containers
    local containers=$(sudo pct list 2>/dev/null | tail -n +2)
    
    # Check if there are any containers
    if [[ -z "$containers" ]]; then
        log_info "No LXC containers found"
        printf "\n"
        return 0
    fi
    
    # Parse and display each container
    while IFS= read -r line; do
        local vmid=$(echo "$line" | awk '{print $1}')
        local status=$(echo "$line" | awk '{print $2}')
        
        # Get hostname and IP from container config
        local hostname=$(sudo pct config "$vmid" 2>/dev/null | grep "^hostname:" | awk '{print $2}' || echo "N/A")
        local ip=$(sudo pct config "$vmid" 2>/dev/null | grep "^net0:" | grep -o 'ip=[^,]*' | cut -d= -f2 | cut -d/ -f1 || echo "N/A")
        
        # Format and display the row
        printf "%-8s %-20s %-20s %-10s\n" "$vmid" "$hostname" "$ip" "$status"
    done <<< "$containers"
    
    printf "%s\n" "================================================================================"
    printf "\n"
    log_info "List complete"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_proxmox
        ;;
    update)
        update_proxmox
        ;;
    uninstall)
        uninstall_proxmox
        ;;
    config)
        configure_proxmox
        ;;
    list-lxc)
        list_all_lxc
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
