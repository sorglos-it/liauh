#!/bin/bash

# Portainer Main (Server) Management Script
# Install, update, and manage Portainer Docker management UI

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

check_docker() {
    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed! Please install Docker first."
    fi
    
    if ! sudo systemctl is-active --quiet docker; then
        log_error "Docker service is not running! Start Docker first: sudo systemctl start docker"
    fi
}

install_portainer() {
    log_info "Installing Portainer (Main)..."
    
    check_docker
    
    # Use provided ports or defaults
    local edge_port="${EDGE_PORT:-8000}"
    local web_port="${WEB_PORT:-9000}"
    
    log_info "Using Edge Agent port: $edge_port, Web UI port: $web_port"
    
    log_info "Checking if Portainer is already running..."
    if docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
        log_warn "Portainer container already exists. Removing old container..."
        sudo docker stop portainer 2>/dev/null || true
        sudo docker rm portainer 2>/dev/null || true
    fi
    
    log_info "Creating Docker volume for Portainer data..."
    sudo docker volume create portainer_data 2>/dev/null || log_warn "Volume already exists"
    
    log_info "Pulling Portainer image..."
    sudo docker pull portainer/portainer-ce:latest || log_error "Failed to pull Portainer image"
    
    log_info "Starting Portainer container..."
    sudo docker run -d \
        -p ${edge_port}:8000 \
        -p ${web_port}:9000 \
        --name=portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest || log_error "Failed to start Portainer"
    
    log_info "Waiting for Portainer to be ready..."
    sleep 5
    
    if sudo docker ps --format '{{.Names}}' | grep -q "^portainer$"; then
        log_info "Portainer installed and running successfully!"
        log_info "Access Portainer Web UI at: http://localhost:${web_port}"
        log_info "Edge Agent listening on port: $edge_port"
        log_info "Initial setup will ask you to create an admin account"
    else
        log_error "Portainer container failed to start"
    fi
}

update_portainer() {
    log_info "Updating Portainer..."
    
    check_docker
    
    if ! sudo docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
        log_error "Portainer container not found. Run install first."
    fi
    
    # Use provided ports or defaults
    local edge_port="${EDGE_PORT:-8000}"
    local web_port="${WEB_PORT:-9000}"
    
    log_info "Using Edge Agent port: $edge_port, Web UI port: $web_port"
    
    log_info "Stopping Portainer..."
    sudo docker stop portainer || log_error "Failed to stop Portainer"
    
    log_info "Removing old Portainer container..."
    sudo docker rm portainer || log_error "Failed to remove Portainer"
    
    log_info "Pulling latest Portainer image..."
    sudo docker pull portainer/portainer-ce:latest || log_error "Failed to pull latest image"
    
    log_info "Starting Portainer with updated image..."
    sudo docker run -d \
        -p ${edge_port}:8000 \
        -p ${web_port}:9000 \
        --name=portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest || log_error "Failed to start Portainer"
    
    log_info "Waiting for Portainer to be ready..."
    sleep 5
    
    log_info "Portainer updated successfully!"
}

uninstall_portainer() {
    log_warn "Uninstalling Portainer..."
    log_warn "DELETE_DATA: $DELETE_DATA"
    
    check_docker
    
    if ! sudo docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
        log_warn "Portainer container not found"
    else
        log_info "Stopping Portainer..."
        sudo docker stop portainer || log_warn "Failed to stop Portainer"
        
        log_info "Removing Portainer container..."
        sudo docker rm portainer || log_warn "Failed to remove Portainer"
    fi
    
    if [[ "$DELETE_DATA" == "yes" ]]; then
        log_info "Removing Portainer data volume..."
        sudo docker volume rm portainer_data 2>/dev/null || log_warn "Could not remove volume"
        log_info "Portainer completely uninstalled (data deleted)!"
    else
        log_info "Portainer uninstalled (data preserved in portainer_data volume)!"
    fi
}

case "$ACTION" in
    install)
        install_portainer
        ;;
    
    update)
        update_portainer
        ;;
    
    uninstall)
        uninstall_portainer
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  portainer.sh install"
        echo "  portainer.sh update"
        echo "  portainer.sh uninstall,DELETE_DATA=yes/no"
        exit 1
        ;;
esac
