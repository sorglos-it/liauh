#!/bin/bash

# MariaDB Management Script
# Install, update, uninstall, and configure MariaDB

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
    else
        log_error "Could not detect package manager (apt, dnf, or yum)"
    fi
}

install_mariadb() {
    log_info "Installing MariaDB..."
    
    local pm=$(detect_package_manager)
    
    log_info "Step 1: Updating package manager..."
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1 || log_error "Failed to update package lists"
            ;;
        dnf)
            sudo dnf check-update >/dev/null 2>&1 || true
            ;;
        yum)
            sudo yum check-update >/dev/null 2>&1 || true
            ;;
    esac
    
    log_info "Step 2: Installing MariaDB server..."
    case "$pm" in
        apt)
            sudo apt-get install -y mariadb-server || log_error "Failed to install mariadb-server"
            ;;
        dnf|yum)
            sudo $pm install -y mariadb-server || log_error "Failed to install mariadb-server"
            ;;
    esac
    
    log_info "Step 3: Starting MariaDB service..."
    sudo systemctl start mariadb || log_error "Failed to start MariaDB"
    sudo systemctl enable mariadb || log_error "Failed to enable MariaDB"
    
    log_info "Step 4: Securing MariaDB installation..."
    log_warn "Setting root password and basic security..."
    
    if [[ -n "$ROOT_PASSWORD" ]]; then
        sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASSWORD';" || log_warn "Failed to set root password"
    else
        log_warn "No root password provided - MariaDB running with empty password"
    fi
    
    # Remove anonymous users
    sudo mysql -e "DELETE FROM mysql.user WHERE User='';" || true
    
    # Disable remote root login
    sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" || true
    
    # Remove test database
    sudo mysql -e "DROP DATABASE IF EXISTS test;" || true
    
    log_info "MariaDB installed and configured successfully!"
    log_info "Root password: ${ROOT_PASSWORD:-(empty - insecure!)}"
}

update_mariadb() {
    log_info "Updating MariaDB..."
    
    local pm=$(detect_package_manager)
    
    log_info "Updating package manager..."
    case "$pm" in
        apt)
            sudo apt-get update >/dev/null 2>&1 || log_error "Failed to update package lists"
            log_info "Upgrading MariaDB..."
            sudo apt-get upgrade -y mariadb-server || log_error "Failed to upgrade MariaDB"
            ;;
        dnf|yum)
            log_info "Upgrading MariaDB..."
            sudo $pm upgrade -y mariadb-server || log_error "Failed to upgrade MariaDB"
            ;;
    esac
    
    log_info "Restarting MariaDB service..."
    sudo systemctl restart mariadb || log_error "Failed to restart MariaDB"
    
    log_info "MariaDB updated successfully!"
}

uninstall_mariadb() {
    log_warn "Uninstalling MariaDB..."
    log_warn "DELETE_DATA setting: $DELETE_DATA"
    log_warn "DELETE_CONFIG setting: $DELETE_CONFIG"
    
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt)
            if [[ "$DELETE_DATA" == "yes" ]]; then
                log_error "Removing MariaDB with purge (removes config)..."
                sudo apt-get purge -y mariadb-server mariadb-client || log_error "Failed to uninstall MariaDB"
            else
                log_info "Removing MariaDB but keeping packages..."
                sudo apt-get remove -y mariadb-server mariadb-client || log_error "Failed to remove MariaDB"
            fi
            ;;
        dnf|yum)
            log_info "Removing MariaDB..."
            sudo $pm remove -y mariadb-server mariadb-client || log_error "Failed to remove MariaDB"
            ;;
    esac
    
    # Remove data
    if [[ "$DELETE_DATA" == "yes" ]]; then
        log_info "Removing databases (/var/lib/mysql)..."
        sudo rm -rf /var/lib/mysql || log_warn "Could not remove /var/lib/mysql"
    fi
    
    # Remove config
    if [[ "$DELETE_CONFIG" == "yes" ]]; then
        log_info "Removing configuration files..."
        sudo rm -rf /etc/mysql* /etc/my.cnf* || log_warn "Could not remove config files"
    fi
    
    if [[ "$DELETE_DATA" == "yes" ]]; then
        log_info "MariaDB completely removed (data and config deleted)!"
    elif [[ "$DELETE_CONFIG" == "yes" ]]; then
        log_info "MariaDB removed! Data preserved in /var/lib/mysql"
    else
        log_info "MariaDB removed! Data and config preserved."
    fi
}

configure_mariadb() {
    log_info "Configuring MariaDB..."
    
    local pm=$(detect_package_manager)
    local config_file
    
    # Detect config file location based on package manager
    if [[ "$pm" == "apt" ]]; then
        config_file="/etc/mysql/mariadb.conf.d/50-server.cnf"
    else
        config_file="/etc/my.cnf.d/server.cnf"
    fi
    
    if [[ ! -f "$config_file" ]]; then
        log_error "MariaDB config file not found: $config_file"
    fi
    
    # Backup original config
    sudo cp "$config_file" "$config_file.backup" || log_warn "Could not backup config"
    
    # Set max connections
    if [[ -n "$MAX_CONNECTIONS" ]]; then
        log_info "Setting max_connections to $MAX_CONNECTIONS..."
        sudo sed -i "/\[mysqld\]/a max_connections = $MAX_CONNECTIONS" "$config_file" || log_warn "Failed to set max_connections"
    fi
    
    # Set innodb buffer pool
    if [[ -n "$INNODB_BUFFER" ]]; then
        log_info "Setting innodb_buffer_pool_size to $INNODB_BUFFER..."
        sudo sed -i "/\[mysqld\]/a innodb_buffer_pool_size = $INNODB_BUFFER" "$config_file" || log_warn "Failed to set innodb_buffer_pool_size"
    fi
    
    # Set bind address
    if [[ -n "$BIND_ADDRESS" ]]; then
        log_info "Setting bind-address to $BIND_ADDRESS..."
        sudo sed -i "s/^bind-address.*/bind-address = $BIND_ADDRESS/" "$config_file" || log_warn "Failed to set bind-address"
    fi
    
    # Set character set
    if [[ -n "$CHARSET" ]]; then
        log_info "Setting default character set to $CHARSET..."
        sudo sed -i "/\[mysqld\]/a character-set-server = $CHARSET" "$config_file" || log_warn "Failed to set character set"
    fi
    
    log_info "Restarting MariaDB to apply changes..."
    sudo systemctl restart mariadb || log_error "Failed to restart MariaDB"
    
    log_info "MariaDB configuration updated!"
    log_info "Backup saved: $config_file.backup"
}

case "$ACTION" in
    install)
        install_mariadb
        ;;
    
    update)
        update_mariadb
        ;;
    
    uninstall)
        uninstall_mariadb
        ;;
    
    config)
        configure_mariadb
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  mariadb.sh install"
        echo "  mariadb.sh update"
        echo "  mariadb.sh uninstall,DELETE_DATA=yes/no"
        echo "  mariadb.sh config,MAX_CONNECTIONS=100,..."
        exit 1
        ;;
esac
