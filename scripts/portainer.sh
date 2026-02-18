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

detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    OS_DISTRO="${ID,,}"
    case "$OS_DISTRO" in
        ubuntu|debian|raspbian|linuxmint|pop) PKG_UPDATE="apt-get update"; PKG_INSTALL="apt-get install -y"; PKG_UNINSTALL="apt-get remove -y" ;;
        fedora|rhel|centos|rocky|alma) PKG_UPDATE="dnf check-update || true"; PKG_INSTALL="dnf install -y"; PKG_UNINSTALL="dnf remove -y" ;;
        arch|manjaro|endeavouros) PKG_UPDATE="pacman -Sy"; PKG_INSTALL="pacman -S --noconfirm"; PKG_UNINSTALL="pacman -R --noconfirm" ;;
        opensuse*|sles) PKG_UPDATE="zypper refresh"; PKG_INSTALL="zypper install -y"; PKG_UNINSTALL="zypper remove -y" ;;
        alpine) PKG_UPDATE="apk update"; PKG_INSTALL="apk add"; PKG_UNINSTALL="apk del" ;;
        *) log_error "Unsupported distribution: $OS_DISTRO" ;;
    esac
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
        install_portainer
        ;;
    
    update)
        update_portainer
        ;;
    
    uninstall)
        uninstall_portainer
        ;;
        
    client-install)
        install_portainer_agent
        ;;
    
    client-update)
        update_portainer_agent
        ;;
    
    client-uninstall)
        uninstall_portainer_agent
        ;;
    
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  portainer.sh install"
        echo "  portainer.sh update"
        echo "  portainer.sh uninstall,DELETE_DATA=yes/no"
        echo "  portainer.sh client-install"
        echo "  portainer.sh client-update"
        echo "  portainer.sh client-uninstall,DELETE_DATA=yes/no"
        exit 1
        ;;
        


esac
