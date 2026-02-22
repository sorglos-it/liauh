#!/bin/bash

# ULH Bootstrap Library - Common initialization and utilities for all scripts
# Source this file at the start of each script: source "$(dirname "$0")/../lib/bootstrap.sh"

# Load colors from centralized library
source "${BASH_SOURCE%/*}/colors.sh"

# ============================================================
# PARAMETER PARSING
# ============================================================

# Parse parameters from ACTION,VAR1=val1,VAR2=val2 format
# Extracts ACTION and sets environment variables from key=value pairs
# Usage in script: parse_parameters "$1"
parse_parameters() {
    local full_params="$1"
    
    # Extract action (first part before comma)
    ACTION="${full_params%%,*}"
    
    # Extract remaining parameters
    local params_rest="${full_params#*,}"
    
    # Parse key=value pairs and export as environment variables
    if [[ -n "$params_rest" && "$params_rest" != "$full_params" ]]; then
        while IFS='=' read -r key val; do
            [[ -n "$key" ]] && export "$key=$val"
        done <<< "${params_rest//,/$'\n'}"
    fi
}

# ============================================================
# LOGGING
# ============================================================

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

log_section() {
    printf "\n${BLUE}▶${NC} %s\n" "$1"
}

# ============================================================
# OS DETECTION & PACKAGE MANAGER
# ============================================================

detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_DISTRO="${ID,,}"
    else
        log_error "Cannot detect OS"
    fi
    
    case "$OS_DISTRO" in
        ubuntu|debian|raspbian|linuxmint|pop)
            PKG_TYPE="deb"
            PKG_UPDATE="apt-get update"
            PKG_INSTALL="apt-get install -y"
            PKG_UNINSTALL="apt-get remove -y"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_TYPE="rpm"
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            ;;
        arch|archarm|manjaro|endeavouros)
            PKG_TYPE="pacman"
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            ;;
        opensuse*|sles)
            PKG_TYPE="zypper"
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            ;;
        alpine)
            PKG_TYPE="apk"
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            ;;
        proxmox)
            PKG_TYPE="deb"
            PKG_UPDATE="apt-get update"
            PKG_INSTALL="apt-get install -y"
            PKG_UNINSTALL="apt-get remove -y"
            ;;
        *)
            log_error "Unsupported distribution: $OS_DISTRO"
            ;;
    esac
}

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if OS is specific distro (case-insensitive)
is_os() {
    [[ "${OS_DISTRO}" == "$1" ]]
}

# Check if OS family matches
is_os_family() {
    case "$1" in
        debian)
            [[ "$PKG_TYPE" == "deb" ]]
            ;;
        redhat)
            [[ "$PKG_TYPE" == "rpm" ]]
            ;;
        arch)
            [[ "$PKG_TYPE" == "pacman" ]]
            ;;
        suse)
            [[ "$PKG_TYPE" == "zypper" ]]
            ;;
        alpine)
            [[ "$PKG_TYPE" == "apk" ]]
            ;;
        *)
            return 1
            ;;
    esac
}
