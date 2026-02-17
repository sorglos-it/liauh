#!/bin/bash

# Perl Management Script
# Install, update, uninstall, and configure Perl (+ CPAN support)

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

install_perl() {
    log_info "Installing Perl..."
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt) sudo apt-get update >/dev/null 2>&1; sudo apt-get install -y perl perl-modules cpanminus || log_error "Failed to install Perl" ;;
        dnf) sudo dnf install -y perl perl-CPAN perl-App-cpanminus || log_error "Failed to install Perl" ;;
        yum) sudo yum install -y perl perl-CPAN perl-App-cpanminus || log_error "Failed to install Perl" ;;
        pacman) sudo pacman -S --noconfirm perl || log_error "Failed to install Perl" ;;
        zypper) sudo zypper install -y perl perl-Module-Build || log_error "Failed to install Perl" ;;
        apk) sudo apk update >/dev/null 2>&1; sudo apk add perl || log_error "Failed to install Perl" ;;
    esac
    
    log_info "Perl installed successfully!"
    perl -v | grep "This is perl"
}

update_perl() {
    log_info "Updating Perl..."
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt) sudo apt-get update >/dev/null 2>&1; sudo apt-get upgrade -y perl perl-modules cpanminus || log_error "Failed to update Perl" ;;
        dnf) sudo dnf upgrade -y perl perl-CPAN perl-App-cpanminus || log_error "Failed to update Perl" ;;
        yum) sudo yum upgrade -y perl perl-CPAN perl-App-cpanminus || log_error "Failed to update Perl" ;;
        pacman) sudo pacman -S --noconfirm perl || log_error "Failed to update Perl" ;;
        zypper) sudo zypper update -y perl perl-Module-Build || log_error "Failed to update Perl" ;;
        apk) sudo apk update >/dev/null 2>&1; sudo apk upgrade perl || log_error "Failed to update Perl" ;;
    esac
    
    log_info "Perl updated successfully!"
}

uninstall_perl() {
    log_info "Uninstalling Perl..."
    local pm=$(detect_package_manager)
    
    case "$pm" in
        apt) sudo apt-get remove -y perl perl-modules cpanminus || log_error "Failed to uninstall Perl" ;;
        dnf|yum) sudo $pm remove -y perl perl-CPAN perl-App-cpanminus || log_error "Failed to uninstall Perl" ;;
        pacman) sudo pacman -R --noconfirm perl || log_error "Failed to uninstall Perl" ;;
        zypper) sudo zypper remove -y perl perl-Module-Build || log_error "Failed to uninstall Perl" ;;
        apk) sudo apk del perl || log_error "Failed to uninstall Perl" ;;
    esac
    
    log_info "Perl uninstalled successfully!"
}

install_cpan_module() {
    [[ -z "$MODULE" ]] && log_error "MODULE not set"
    
    log_info "Installing CPAN module: $MODULE..."
    
    if command -v cpanm &>/dev/null; then
        cpanm "$MODULE" || log_error "Failed to install $MODULE"
    else
        cpan "$MODULE" || log_error "Failed to install $MODULE"
    fi
    
    log_info "Module $MODULE installed successfully!"
}

configure_perl() {
    log_info "Configuring Perl..."
    
    if [[ -n "$PERL5LIB" ]]; then
        log_info "Setting PERL5LIB to: $PERL5LIB..."
        mkdir -p "$PERL5LIB"
        echo "export PERL5LIB=$PERL5LIB" >> ~/.bashrc || log_warn "Failed to set PERL5LIB"
    fi
    
    log_info "Perl configuration updated!"
    perl -v | grep "This is perl"
}

case "$ACTION" in
    install) install_perl ;;
    update) update_perl ;;
    uninstall) uninstall_perl ;;
    cpan-module) install_cpan_module ;;
    config) configure_perl ;;
    *) log_error "Unknown action: $ACTION"
       echo "Usage: perl.sh install|update|uninstall|cpan-module,MODULE=LWP::UserAgent|config,PERL5LIB=~/perl5" ;;
esac
