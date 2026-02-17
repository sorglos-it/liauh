#!/bin/bash

# PHP Management Script
# Install, update, uninstall, and configure PHP (+ Composer option)

set -e

FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { printf "${GREEN}✓${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
log_error() { printf "${RED}✗${NC} %s\n" "$1"; exit 1; }

detect_package_manager() {
    if command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v yum &>/dev/null; then echo "yum"
    elif command -v pacman &>/dev/null; then echo "pacman"
    elif command -v zypper &>/dev/null; then echo "zypper"
    elif command -v apk &>/dev/null; then echo "apk"
    else log_error "Could not detect package manager"; fi
}

install_php() {
    log_info "Installing PHP..."
    local pm=$(detect_package_manager)
    local install_composer="${COMPOSER:-no}"
    
    case "$pm" in
        apt) sudo apt-get update >/dev/null 2>&1; sudo apt-get install -y php php-cli php-fpm || log_error "Failed to install PHP" ;;
        dnf) sudo dnf install -y php php-cli php-fpm || log_error "Failed to install PHP" ;;
        yum) sudo yum install -y php php-cli php-fpm || log_error "Failed to install PHP" ;;
        pacman) sudo pacman -S --noconfirm php || log_error "Failed to install PHP" ;;
        zypper) sudo zypper install -y php php-cli || log_error "Failed to install PHP" ;;
        apk) sudo apk update >/dev/null 2>&1; sudo apk add php php-cli || log_error "Failed to install PHP" ;;
    esac
    
    log_info "PHP installed successfully!"
    php --version
    
    if [[ "$install_composer" == "yes" ]]; then
        log_info "Installing Composer..."
        curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer || log_error "Failed to install Composer"
        composer --version
    fi
}

update_php() {
    log_info "Updating PHP..."
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt) sudo apt-get update >/dev/null 2>&1; sudo apt-get upgrade -y php php-cli php-fpm || log_error "Failed to update PHP" ;;
        dnf) sudo dnf upgrade -y php php-cli php-fpm || log_error "Failed to update PHP" ;;
        yum) sudo yum upgrade -y php php-cli php-fpm || log_error "Failed to update PHP" ;;
        pacman) sudo pacman -S --noconfirm php || log_error "Failed to update PHP" ;;
        zypper) sudo zypper update -y php php-cli || log_error "Failed to update PHP" ;;
        apk) sudo apk update >/dev/null 2>&1; sudo apk upgrade php php-cli || log_error "Failed to update PHP" ;;
    esac
    
    log_info "PHP updated successfully!"
    php --version
}

uninstall_php() {
    log_info "Uninstalling PHP..."
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt) sudo apt-get remove -y php php-cli php-fpm || log_error "Failed to uninstall PHP" ;;
        dnf|yum) sudo $pm remove -y php php-cli php-fpm || log_error "Failed to uninstall PHP" ;;
        pacman) sudo pacman -R --noconfirm php || log_error "Failed to uninstall PHP" ;;
        zypper) sudo zypper remove -y php php-cli || log_error "Failed to uninstall PHP" ;;
        apk) sudo apk del php php-cli || log_error "Failed to uninstall PHP" ;;
    esac
    
    log_info "PHP uninstalled successfully!"
}

configure_php() {
    log_info "Configuring PHP..."
    local php_ini="${PHP_INI_PATH:-/etc/php/php.ini}"
    
    if [[ -n "$MEMORY_LIMIT" ]]; then
        log_info "Setting memory_limit to: $MEMORY_LIMIT..."
        sudo sed -i "s/memory_limit.*/memory_limit = $MEMORY_LIMIT/" "$php_ini" || log_warn "Failed to set memory_limit"
    fi
    
    if [[ -n "$MAX_EXECUTION_TIME" ]]; then
        log_info "Setting max_execution_time to: $MAX_EXECUTION_TIME..."
        sudo sed -i "s/max_execution_time.*/max_execution_time = $MAX_EXECUTION_TIME/" "$php_ini" || log_warn "Failed to set max_execution_time"
    fi
    
    log_info "PHP configuration updated!"
}

case "$ACTION" in
    install) install_php ;;
    update) update_php ;;
    uninstall) uninstall_php ;;
    config) configure_php ;;
    *) log_error "Unknown action: $ACTION"
       echo "Usage: php.sh install,COMPOSER=yes|update|uninstall|config,MEMORY_LIMIT=256M,MAX_EXECUTION_TIME=30" ;;
esac
