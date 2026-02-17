#!/bin/bash

# Docker Management Script
# Install, update, uninstall, and configure Docker

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
    else
        log_error "Could not detect package manager"
    fi
}

install_docker() {
    log_info "Installing Docker..."
    
    local pm=$(detect_package_manager)
    
    log_info "Step 1: Updating package manager..."
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1 || log_error "Failed to update package lists"
            ;;
        dnf|yum|pacman)
            log_warn "Skipping update for $pm"
            ;;
    esac
    
    log_info "Step 2: Installing Docker..."
    case "$pm" in
        apt)
            sudo apt-get install -y docker.io || log_error "Failed to install docker.io"
            ;;
        dnf)
            sudo dnf install -y docker || log_error "Failed to install docker"
            ;;
        yum)
            sudo yum install -y docker || log_error "Failed to install docker"
            ;;
        pacman)
            sudo pacman -S --noconfirm docker || log_error "Failed to install docker"
            ;;
    esac
    
    log_info "Step 3: Starting Docker service..."
    sudo systemctl start docker || log_error "Failed to start Docker"
    sudo systemctl enable docker || log_error "Failed to enable Docker"
    
    log_info "Step 4: Adding current user to docker group..."
    sudo usermod -aG docker "$USER" || log_warn "Failed to add user to docker group"
    log_warn "You may need to log out and back in for group changes to take effect"
    
    log_info "Docker installed successfully!"
}

update_docker() {
    log_info "Updating Docker..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get upgrade -y docker.io || log_error "Failed to update docker.io"
            ;;
        dnf)
            sudo dnf upgrade -y docker || log_error "Failed to upgrade docker"
            ;;
        yum)
            sudo yum upgrade -y docker || log_error "Failed to upgrade docker"
            ;;
        pacman)
            sudo pacman -S --noconfirm docker || log_error "Failed to update docker"
            ;;
    esac
    
    log_info "Restarting Docker service..."
    sudo systemctl restart docker || log_error "Failed to restart Docker"
    
    log_info "Docker updated successfully!"
}

uninstall_docker() {
    log_warn "Uninstalling Docker..."
    log_warn "DELETE_IMAGES setting: $DELETE_IMAGES"
    log_warn "DELETE_VOLUMES setting: $DELETE_VOLUMES"
    
    local pm=$(detect_package_manager)
    
    log_info "Removing Docker..."
    case "$pm" in
        apt)
            sudo apt-get remove -y docker.io || log_error "Failed to remove docker.io"
            ;;
        dnf|yum)
            sudo $pm remove -y docker || log_error "Failed to remove docker"
            ;;
        pacman)
            sudo pacman -R --noconfirm docker || log_error "Failed to remove docker"
            ;;
    esac
    
    # Remove images
    if [[ "$DELETE_IMAGES" == "yes" ]]; then
        log_info "Removing Docker images (/var/lib/docker/image/)..."
        sudo rm -rf /var/lib/docker/image* || log_warn "Could not remove docker images"
    fi
    
    # Remove volumes
    if [[ "$DELETE_VOLUMES" == "yes" ]]; then
        log_info "Removing Docker volumes (/var/lib/docker/volumes/)..."
        sudo rm -rf /var/lib/docker/volumes* || log_warn "Could not remove docker volumes"
    fi
    
    # Full cleanup
    if [[ "$DELETE_IMAGES" == "yes" && "$DELETE_VOLUMES" == "yes" ]]; then
        log_info "Removing all Docker data (/var/lib/docker/)..."
        sudo rm -rf /var/lib/docker || log_warn "Could not remove /var/lib/docker"
        log_info "Docker completely removed (all images and volumes deleted)!"
    else
        log_info "Docker removed!"
    fi
}

configure_docker() {
    log_info "Configuring Docker..."
    
    local config_file="/etc/docker/daemon.json"
    
    # Create config file if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        log_info "Creating Docker daemon.json..."
        echo '{}' | sudo tee "$config_file" >/dev/null
    fi
    
    # Backup original config
    sudo cp "$config_file" "$config_file.backup" || log_warn "Could not backup config"
    
    # Create new config
    local config='{'
    
    # Storage driver
    if [[ -n "$STORAGE_DRIVER" ]]; then
        log_info "Setting storage driver to $STORAGE_DRIVER..."
        config="$config\"storage-driver\": \"$STORAGE_DRIVER\","
    fi
    
    # Log driver
    if [[ -n "$LOG_DRIVER" ]]; then
        log_info "Setting log driver to $LOG_DRIVER..."
        config="$config\"log-driver\": \"$LOG_DRIVER\","
    fi
    
    # Registry mirrors
    if [[ -n "$REGISTRY_MIRROR" ]]; then
        log_info "Adding registry mirror: $REGISTRY_MIRROR..."
        config="$config\"registry-mirrors\": [\"$REGISTRY_MIRROR\"],"
    fi
    
    # Max concurrent downloads
    if [[ -n "$MAX_CONCURRENT_DOWNLOADS" ]]; then
        log_info "Setting max concurrent downloads to $MAX_CONCURRENT_DOWNLOADS..."
        config="$config\"max-concurrent-downloads\": $MAX_CONCURRENT_DOWNLOADS,"
    fi
    
    # Remove trailing comma and close JSON
    config="${config%,}"
    config="$config}"
    
    # Write config
    echo "$config" | sudo tee "$config_file" >/dev/null || log_error "Failed to write config"
    
    log_info "Restarting Docker to apply changes..."
    sudo systemctl restart docker || log_error "Failed to restart Docker"
    
    log_info "Docker configured successfully!"
    log_info "Backup saved: $config_file.backup"
}

case "$ACTION" in
    install)
        install_docker
        ;;
    
    update)
        update_docker
        ;;
    
    uninstall)
        uninstall_docker
        ;;
    
    config)
        configure_docker
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  docker.sh install                          (install Docker)"
        echo "  docker.sh update                           (update Docker)"
        echo "  docker.sh uninstall,DELETE_IMAGES=yes/no,DELETE_VOLUMES=yes/no"
        echo "  docker.sh config,STORAGE_DRIVER=overlay2,..."
        exit 1
        ;;
esac
