#!/bin/bash

# Nginx Web Server Management Script
# Install, update, uninstall, and configure Nginx

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
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v apk &>/dev/null; then
        echo "apk"
    else
        log_error "Could not detect package manager"
    fi
}

install_nginx() {
    log_info "Installing Nginx..."
    
    local pm=$(detect_package_manager)
    
    log_info "Step 1: Updating package manager..."
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1 || log_error "Failed to update package lists"
            ;;
        *) :;;
    esac
    
    log_info "Step 2: Installing Nginx..."
    case "$pm" in
        apt)
            sudo apt-get install -y nginx || log_error "Failed to install nginx"
            ;;
        dnf|yum)
            sudo $pm install -y nginx || log_error "Failed to install nginx"
            ;;
        pacman)
            sudo pacman -S --noconfirm nginx || log_error "Failed to install nginx"
            ;;
        zypper)
            sudo zypper install -y nginx || log_error "Failed to install nginx"
            ;;
        apk)
            sudo apk add nginx || log_error "Failed to install nginx"
            ;;
    esac
    
    log_info "Step 3: Enabling and starting Nginx service..."
    sudo systemctl start nginx || log_error "Failed to start Nginx"
    sudo systemctl enable nginx || log_error "Failed to enable Nginx"
    
    log_info "Nginx installed and started successfully!"
}

update_nginx() {
    log_info "Updating Nginx..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get upgrade -y nginx || log_error "Failed to update nginx"
            ;;
        dnf)
            sudo dnf upgrade -y nginx || log_error "Failed to upgrade nginx"
            ;;
        yum)
            sudo yum upgrade -y nginx || log_error "Failed to upgrade nginx"
            ;;
        pacman)
            sudo pacman -S --noconfirm nginx || log_error "Failed to update nginx"
            ;;
        zypper)
            sudo zypper update -y nginx || log_error "Failed to update nginx"
            ;;
        apk)
            sudo apk update
            sudo apk upgrade nginx || log_error "Failed to upgrade nginx"
            ;;
    esac
    
    log_info "Restarting Nginx..."
    sudo systemctl restart nginx || log_error "Failed to restart Nginx"
    
    log_info "Nginx updated successfully!"
}

uninstall_nginx() {
    log_warn "Uninstalling Nginx..."
    log_warn "DELETE_CONFIG: $DELETE_CONFIG"
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            if [[ "$DELETE_CONFIG" == "yes" ]]; then
                sudo apt-get purge -y nginx || log_error "Failed to uninstall nginx"
            else
                sudo apt-get remove -y nginx || log_error "Failed to remove nginx"
            fi
            ;;
        dnf|yum)
            sudo $pm remove -y nginx || log_error "Failed to remove nginx"
            ;;
        pacman)
            sudo pacman -R --noconfirm nginx || log_error "Failed to remove nginx"
            ;;
        zypper)
            sudo zypper remove -y nginx || log_error "Failed to remove nginx"
            ;;
        apk)
            sudo apk del nginx || log_error "Failed to remove nginx"
            ;;
    esac
    
    if [[ "$DELETE_CONFIG" == "yes" ]]; then
        log_info "Removing Nginx configuration files..."
        sudo rm -rf /etc/nginx || log_warn "Could not remove /etc/nginx"
    fi
    
    log_info "Nginx uninstalled successfully!"
}

config_vhosts() {
    log_info "Configuring Nginx Virtual Server Block..."
    
    [[ -z "$SERVER_NAME" ]] && log_error "SERVER_NAME not set"
    [[ -z "$ROOT_PATH" ]] && log_error "ROOT_PATH not set"
    
    local config_dir="/etc/nginx"
    local vhost_file="$config_dir/sites-available/${SERVER_NAME}.conf"
    
    log_info "Creating server block: $SERVER_NAME"
    log_info "Root directory: $ROOT_PATH"
    
    # Create sites-available directory if it doesn't exist
    sudo mkdir -p "$config_dir/sites-available" "$config_dir/sites-enabled" || log_warn "Could not create directories"
    
    local vhost_conf="server {
    listen 80;
    listen [::]:80;
    
    server_name $SERVER_NAME www.$SERVER_NAME;
    root $ROOT_PATH;
    
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    error_log \$logs/${SERVER_NAME}_error.log;
    access_log \$logs/${SERVER_NAME}_access.log;
}"
    
    echo "$vhost_conf" | sudo tee "$vhost_file" >/dev/null || log_error "Failed to create server block config"
    
    # Create symlink in sites-enabled
    sudo ln -sf "$vhost_file" "$config_dir/sites-enabled/${SERVER_NAME}.conf" 2>/dev/null || log_warn "Could not create symlink"
    
    log_info "Testing Nginx configuration..."
    sudo nginx -t || log_error "Nginx configuration test failed"
    
    log_info "Reloading Nginx..."
    sudo systemctl reload nginx || log_error "Failed to reload Nginx"
    
    log_info "Virtual server block configured successfully!"
}

config_default() {
    log_info "Configuring Nginx default settings..."
    
    local config_file="/etc/nginx/nginx.conf"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Nginx config file not found: $config_file"
    fi
    
    log_info "Backing up Nginx config..."
    sudo cp "$config_file" "$config_file.backup" || log_warn "Could not backup config"
    
    # Enable gzip compression
    if [[ "$ENABLE_GZIP" == "yes" ]]; then
        log_info "Enabling gzip compression..."
        sudo sed -i 's/\s*#gzip on;/gzip on;/' "$config_file" || log_warn "Failed to enable gzip"
    fi
    
    # Set client max body size
    if [[ -n "$CLIENT_MAX_BODY" ]]; then
        log_info "Setting client_max_body_size to $CLIENT_MAX_BODY..."
        if grep -q "client_max_body_size" "$config_file"; then
            sudo sed -i "s/client_max_body_size.*/client_max_body_size $CLIENT_MAX_BODY;/" "$config_file"
        else
            sudo sed -i '/http {/a \    client_max_body_size '"$CLIENT_MAX_BODY"';' "$config_file"
        fi || log_warn "Failed to set client_max_body_size"
    fi
    
    # Set server tokens
    if [[ "$HIDE_VERSION" == "yes" ]]; then
        log_info "Hiding Nginx version..."
        if grep -q "server_tokens" "$config_file"; then
            sudo sed -i "s/server_tokens.*/server_tokens off;/" "$config_file"
        else
            sudo sed -i '/http {/a \    server_tokens off;' "$config_file"
        fi || log_warn "Failed to hide server version"
    fi
    
    log_info "Testing Nginx configuration..."
    sudo nginx -t || log_error "Nginx configuration test failed"
    
    log_info "Reloading Nginx..."
    sudo systemctl reload nginx || log_error "Failed to reload Nginx"
    
    log_info "Default configuration updated successfully!"
    log_info "Backup saved: $config_file.backup"
}

config_performance() {
    log_info "Configuring Nginx performance and logging..."
    
    local config_file="/etc/nginx/nginx.conf"
    
    log_info "Backing up Nginx config..."
    sudo cp "$config_file" "$config_file.backup" || log_warn "Could not backup config"
    
    # Set worker processes
    if [[ -n "$WORKER_PROCESSES" ]]; then
        log_info "Setting worker_processes to $WORKER_PROCESSES..."
        sudo sed -i "s/^worker_processes.*/worker_processes $WORKER_PROCESSES;/" "$config_file" || log_warn "Failed to set worker_processes"
    fi
    
    # Set worker connections
    if [[ -n "$WORKER_CONNECTIONS" ]]; then
        log_info "Setting worker_connections to $WORKER_CONNECTIONS..."
        if grep -q "worker_connections" "$config_file"; then
            sudo sed -i "s/worker_connections.*/worker_connections $WORKER_CONNECTIONS;/" "$config_file"
        else
            sudo sed -i '/events {/a \    worker_connections '"$WORKER_CONNECTIONS"';' "$config_file"
        fi || log_warn "Failed to set worker_connections"
    fi
    
    # Set access log level
    if [[ -n "$LOG_LEVEL" ]]; then
        log_info "Setting error_log level to $LOG_LEVEL..."
        sudo sed -i "s/^error_log.*/error_log \/var\/log\/nginx\/error.log $LOG_LEVEL;/" "$config_file" || log_warn "Failed to set error_log level"
    fi
    
    log_info "Testing Nginx configuration..."
    sudo nginx -t || log_error "Nginx configuration test failed"
    
    log_info "Reloading Nginx..."
    sudo systemctl reload nginx || log_error "Failed to reload Nginx"
    
    log_info "Performance configuration updated successfully!"
    log_info "Backup saved: $config_file.backup"
}

case "$ACTION" in
    install)
        install_nginx
        ;;
    
    update)
        update_nginx
        ;;
    
    uninstall)
        uninstall_nginx
        ;;
    
    vhosts)
        config_vhosts
        ;;
    
    default)
        config_default
        ;;
    
    config)
        config_performance
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  nginx.sh install"
        echo "  nginx.sh update"
        echo "  nginx.sh uninstall,DELETE_CONFIG=yes/no"
        echo "  nginx.sh vhosts,SERVER_NAME=example.com,ROOT_PATH=/var/www/example"
        echo "  nginx.sh default,ENABLE_GZIP=yes,CLIENT_MAX_BODY=100M,HIDE_VERSION=yes"
        echo "  nginx.sh config,WORKER_PROCESSES=4,WORKER_CONNECTIONS=1024,LOG_LEVEL=warn"
        exit 1
        ;;
esac
