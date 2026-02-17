#!/bin/bash

# Portainer Agent (Client) Management Script
# Install, update, and manage Portainer Agent for edge deployments

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

install_portainer_agent() {
    log_info "Installing Portainer Agent..."
    
    check_docker
    
    # Use provided port or default
    local agent_port="${AGENT_PORT:-9001}"
    
    log_info "Using Agent port: $agent_port"
    
    log_info "Checking if Portainer Agent is already running..."
    if docker ps -a --format '{{.Names}}' | grep -q "^portainer_agent$"; then
        log_warn "Portainer Agent container already exists. Removing old container..."
        sudo docker stop portainer_agent 2>/dev/null || true
        sudo docker rm portainer_agent 2>/dev/null || true
    fi
    
    log_info "Pulling Portainer Agent image..."
    sudo docker pull portainer/agent:latest || log_error "Failed to pull Portainer Agent image"
    
    log_info "Starting Portainer Agent container..."
    sudo docker run -d \
        -p ${agent_port}:9001 \
        --name portainer_agent \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/volumes:/var/lib/docker/volumes \
        portainer/agent:latest || log_error "Failed to start Portainer Agent"
    
    log_info "Waiting for Agent to be ready..."
    sleep 3
    
    if sudo docker ps --format '{{.Names}}' | grep -q "^portainer_agent$"; then
        log_info "Portainer Agent installed and running successfully!"
        log_info "Agent listening on port $agent_port"
        log_info "Connect this agent to your Portainer main via: Environment → Add environment → Agent → http://<this-ip>:${agent_port}"
    else
        log_error "Portainer Agent container failed to start"
    fi
}

update_portainer_agent() {
    log_info "Updating Portainer Agent..."
    
    check_docker
    
    if ! sudo docker ps -a --format '{{.Names}}' | grep -q "^portainer_agent$"; then
        log_error "Portainer Agent container not found. Run install first."
    fi
    
    # Use provided port or default
    local agent_port="${AGENT_PORT:-9001}"
    
    log_info "Using Agent port: $agent_port"
    
    log_info "Stopping Portainer Agent..."
    sudo docker stop portainer_agent || log_error "Failed to stop Agent"
    
    log_info "Removing old Portainer Agent container..."
    sudo docker rm portainer_agent || log_error "Failed to remove Agent"
    
    log_info "Pulling latest Portainer Agent image..."
    sudo docker pull portainer/agent:latest || log_error "Failed to pull latest image"
    
    log_info "Starting Portainer Agent with updated image..."
    sudo docker run -d \
        -p ${agent_port}:9001 \
        --name portainer_agent \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/volumes:/var/lib/docker/volumes \
        portainer/agent:latest || log_error "Failed to start Agent"
    
    log_info "Waiting for Agent to be ready..."
    sleep 3
    
    log_info "Portainer Agent updated successfully!"
}

uninstall_portainer_agent() {
    log_warn "Uninstalling Portainer Agent..."
    log_warn "DELETE_DATA: $DELETE_DATA"
    
    check_docker
    
    if ! sudo docker ps -a --format '{{.Names}}' | grep -q "^portainer_agent$"; then
        log_warn "Portainer Agent container not found"
    else
        log_info "Stopping Portainer Agent..."
        sudo docker stop portainer_agent || log_warn "Failed to stop Agent"
        
        log_info "Removing Portainer Agent container..."
        sudo docker rm portainer_agent || log_warn "Failed to remove Agent"
    fi
    
    if [[ "$DELETE_DATA" == "yes" ]]; then
        log_info "Note: Agent doesn't use persistent data volumes"
        log_info "Portainer Agent completely uninstalled!"
    else
        log_info "Portainer Agent uninstalled!"
    fi
}

case "$ACTION" in
    install)
        install_portainer_agent
        ;;
    
    update)
        update_portainer_agent
        ;;
    
    uninstall)
        uninstall_portainer_agent
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  portainer-client.sh install"
        echo "  portainer-client.sh update"
        echo "  portainer-client.sh uninstall,DELETE_DATA=yes/no"
        exit 1
        ;;
esac
