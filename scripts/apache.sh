#!/bin/bash

# Apache Web Server Management Script
# Install, update, uninstall, and configure Apache

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

install_apache() {
    log_info "Installing Apache2..."
    
    local pm=$(detect_package_manager)
    
    log_info "Step 1: Updating package manager..."
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1 || log_error "Failed to update package lists"
            ;;
        *) :;;
    esac
    
    log_info "Step 2: Installing Apache..."
    case "$pm" in
        apt)
            sudo apt-get install -y apache2 || log_error "Failed to install apache2"
            ;;
        dnf|yum)
            sudo $pm install -y httpd || log_error "Failed to install httpd"
            ;;
        pacman)
            sudo pacman -S --noconfirm apache || log_error "Failed to install apache"
            ;;
        zypper)
            sudo zypper install -y apache2 || log_error "Failed to install apache2"
            ;;
        apk)
            sudo apk add apache2 || log_error "Failed to install apache2"
            ;;
    esac
    
    log_info "Step 3: Enabling and starting Apache service..."
    local svc=$(get_service_name)
    sudo systemctl start "$svc" || log_error "Failed to start Apache"
    sudo systemctl enable "$svc" || log_error "Failed to enable Apache"
    
    log_info "Apache installed and started successfully!"
}

update_apache() {
    log_info "Updating Apache..."
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get upgrade -y apache2 || log_error "Failed to update apache2"
            ;;
        dnf)
            sudo dnf upgrade -y httpd || log_error "Failed to upgrade httpd"
            ;;
        yum)
            sudo yum upgrade -y httpd || log_error "Failed to upgrade httpd"
            ;;
        pacman)
            sudo pacman -S --noconfirm apache || log_error "Failed to update apache"
            ;;
        zypper)
            sudo zypper update -y apache2 || log_error "Failed to update apache2"
            ;;
        apk)
            sudo apk update
            sudo apk upgrade apache2 || log_error "Failed to upgrade apache2"
            ;;
    esac
    
    log_info "Restarting Apache..."
    local svc=$(get_service_name)
    sudo systemctl restart "$svc" || log_error "Failed to restart Apache"
    
    log_info "Apache updated successfully!"
}

uninstall_apache() {
    log_warn "Uninstalling Apache..."
    log_warn "DELETE_CONFIG: $DELETE_CONFIG"
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            if [[ "$DELETE_CONFIG" == "yes" ]]; then
                sudo apt-get purge -y apache2 || log_error "Failed to uninstall apache2"
            else
                sudo apt-get remove -y apache2 || log_error "Failed to remove apache2"
            fi
            ;;
        dnf|yum)
            sudo $pm remove -y httpd || log_error "Failed to remove httpd"
            ;;
        pacman)
            sudo pacman -R --noconfirm apache || log_error "Failed to remove apache"
            ;;
        zypper)
            sudo zypper remove -y apache2 || log_error "Failed to remove apache2"
            ;;
        apk)
            sudo apk del apache2 || log_error "Failed to remove apache2"
            ;;
    esac
    
    if [[ "$DELETE_CONFIG" == "yes" ]]; then
        log_info "Removing Apache configuration files..."
        sudo rm -rf /etc/apache2* /etc/httpd* || log_warn "Could not remove config files"
    fi
    
    log_info "Apache uninstalled successfully!"
}

get_service_name() {
    local pm=$(detect_package_manager)
    if [[ "$pm" == "dnf" || "$pm" == "yum" || "$pm" == "apk" ]]; then
        echo "httpd"
    else
        echo "apache2"
    fi
}

get_config_dir() {
    local pm=$(detect_package_manager)
    if [[ "$pm" == "dnf" || "$pm" == "yum" || "$pm" == "apk" ]]; then
        echo "/etc/httpd"
    else
        echo "/etc/apache2"
    fi
}

config_vhosts() {
    log_info "Configuring Virtual Hosts..."
    
    [[ -z "$VHOST_NAME" ]] && log_error "VHOST_NAME not set"
    [[ -z "$VHOST_ROOT" ]] && log_error "VHOST_ROOT not set"
    
    local config_dir=$(get_config_dir)
    local vhost_file="$config_dir/sites-available/${VHOST_NAME}.conf"
    
    if [[ -d "$config_dir/sites-available" ]]; then
        # Debian/Ubuntu style
        log_info "Creating vhost: $VHOST_NAME"
        log_info "Root directory: $VHOST_ROOT"
        
        local vhost_conf="<VirtualHost *:80>
    ServerName $VHOST_NAME
    ServerAlias www.$VHOST_NAME
    DocumentRoot $VHOST_ROOT
    
    <Directory $VHOST_ROOT>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${VHOST_NAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${VHOST_NAME}_access.log combined
</VirtualHost>"
        
        echo "$vhost_conf" | sudo tee "$vhost_file" >/dev/null || log_error "Failed to create vhost config"
        
        # Enable vhost
        sudo a2ensite "${VHOST_NAME}.conf" 2>/dev/null || log_warn "Could not enable vhost (a2ensite not available)"
    else
        log_error "Virtual hosts configuration not supported on this system"
    fi
    
    log_info "Testing Apache configuration..."
    sudo apache2ctl configtest 2>/dev/null || sudo httpd -t 2>/dev/null || log_warn "Could not verify config"
    
    log_info "Restarting Apache..."
    local svc=$(get_service_name)
    sudo systemctl restart "$svc" || log_error "Failed to restart Apache"
    
    log_info "Virtual host configured successfully!"
}

config_default() {
    log_info "Configuring default Apache settings..."
    
    local config_dir=$(get_config_dir)
    local config_file
    
    if [[ -f "$config_dir/apache2.conf" ]]; then
        config_file="$config_dir/apache2.conf"
    elif [[ -f "$config_dir/httpd.conf" ]]; then
        config_file="$config_dir/httpd.conf"
    else
        log_error "Apache config file not found"
    fi
    
    log_info "Backing up Apache config..."
    sudo cp "$config_file" "$config_file.backup" || log_warn "Could not backup config"
    
    # Set ServerAdmin
    if [[ -n "$SERVER_ADMIN" ]]; then
        log_info "Setting ServerAdmin to $SERVER_ADMIN..."
        sudo sed -i "s/^ServerAdmin.*/ServerAdmin $SERVER_ADMIN/" "$config_file" || log_warn "Failed to set ServerAdmin"
    fi
    
    # Enable modules
    if [[ -n "$ENABLE_MODULES" && -d "$config_dir/mods-available" ]]; then
        log_info "Enabling modules: $ENABLE_MODULES..."
        for mod in ${ENABLE_MODULES//,/ }; do
            sudo a2enmod "$mod" 2>/dev/null || log_warn "Could not enable module: $mod"
        done
    fi
    
    log_info "Testing Apache configuration..."
    sudo apache2ctl configtest 2>/dev/null || sudo httpd -t 2>/dev/null || log_warn "Could not verify config"
    
    log_info "Restarting Apache..."
    local svc=$(get_service_name)
    sudo systemctl restart "$svc" || log_error "Failed to restart Apache"
    
    log_info "Default configuration updated successfully!"
    log_info "Backup saved: $config_file.backup"
}

config_general() {
    log_info "Configuring Apache performance and logging..."
    
    local config_dir=$(get_config_dir)
    local mpm_file
    
    # Find MPM config
    if [[ -f "$config_dir/mods-available/mpm_prefork.conf" ]]; then
        mpm_file="$config_dir/mods-available/mpm_prefork.conf"
    elif [[ -f "$config_dir/conf.modules.d/00-mpm.conf" ]]; then
        mpm_file="$config_dir/conf.modules.d/00-mpm.conf"
    fi
    
    # Set max requests
    if [[ -n "$MAX_REQUESTS" && -n "$mpm_file" ]]; then
        log_info "Setting MaxRequestWorkers to $MAX_REQUESTS..."
        sudo sed -i "s/MaxRequestWorkers.*/MaxRequestWorkers $MAX_REQUESTS/" "$mpm_file" || log_warn "Failed to set MaxRequestWorkers"
    fi
    
    # Set error log level
    if [[ -n "$LOG_LEVEL" ]]; then
        local config_dir=$(get_config_dir)
        local main_conf="$config_dir/apache2.conf"
        [[ ! -f "$main_conf" ]] && main_conf="$config_dir/httpd.conf"
        
        log_info "Setting LogLevel to $LOG_LEVEL..."
        sudo sed -i "s/^LogLevel.*/LogLevel $LOG_LEVEL/" "$main_conf" || log_warn "Failed to set LogLevel"
    fi
    
    log_info "Testing Apache configuration..."
    sudo apache2ctl configtest 2>/dev/null || sudo httpd -t 2>/dev/null || log_warn "Could not verify config"
    
    log_info "Restarting Apache..."
    local svc=$(get_service_name)
    sudo systemctl restart "$svc" || log_error "Failed to restart Apache"
    
    log_info "Apache configuration updated successfully!"
}

case "$ACTION" in
    install)
        install_apache
        ;;
    
    update)
        update_apache
        ;;
    
    uninstall)
        uninstall_apache
        ;;
    
    vhosts)
        config_vhosts
        ;;
    
    default)
        config_default
        ;;
    
    config)
        config_general
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  apache.sh install"
        echo "  apache.sh update"
        echo "  apache.sh uninstall,DELETE_CONFIG=yes/no"
        echo "  apache.sh vhosts,VHOST_NAME=example.com,VHOST_ROOT=/var/www/example"
        echo "  apache.sh default,SERVER_ADMIN=admin@example.com,ENABLE_MODULES=rewrite,ssl"
        echo "  apache.sh config,MAX_REQUESTS=256,LOG_LEVEL=warn"
        exit 1
        ;;
esac
