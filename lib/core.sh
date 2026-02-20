#!/bin/bash
# ulh - Core Library: Colors, OS detection, debug logging, utilities

DEBUG=${DEBUG:-false}

# Debug logging - only output if DEBUG=true
debug() {
    [[ "$DEBUG" == true ]] && echo "DEBUG: $*" >&2
}

# ============================================================================
# ANSI Color Codes for Terminal Output
# ============================================================================

export COLOR_RESET=$'\033[0m'
export COLOR_BOLD=$'\033[1m'
export COLOR_DIM=$'\033[2m'
export COLOR_UNDERLINE=$'\033[4m'

export COLOR_BLACK=$'\033[0;30m'
export COLOR_RED=$'\033[0;31m'
export COLOR_GREEN=$'\033[0;32m'
export COLOR_YELLOW=$'\033[0;33m'
export COLOR_BLUE=$'\033[0;34m'
export COLOR_MAGENTA=$'\033[0;35m'
export COLOR_CYAN=$'\033[0;36m'
export COLOR_WHITE=$'\033[0;37m'

export COLOR_BOLD_RED=$'\033[1;31m'
export COLOR_BOLD_GREEN=$'\033[1;32m'
export COLOR_BOLD_YELLOW=$'\033[1;33m'
export COLOR_BOLD_BLUE=$'\033[1;34m'
export COLOR_BOLD_CYAN=$'\033[1;36m'
export COLOR_BOLD_WHITE=$'\033[1;37m'

export COLOR_BG_RED=$'\033[41m'
export COLOR_BG_GREEN=$'\033[42m'
export COLOR_BG_YELLOW=$'\033[43m'

# Shorter aliases
C_RESET="$COLOR_RESET"
C_RED="$COLOR_RED"
C_GREEN="$COLOR_GREEN"
C_YELLOW="$COLOR_YELLOW"
C_CYAN="$COLOR_CYAN"
C_BOLD="$COLOR_BOLD"
C_BOLD_CYAN="$COLOR_BOLD_CYAN"
C_BOLD_WHITE="$COLOR_BOLD_WHITE"

# ============================================================================
# Output Functions - All write to stderr to keep stdout clean
# ============================================================================

msg()     { printf "%b\n" "$*" >&2; }
msg_ok()  { msg "${C_GREEN}✓ $*${C_RESET}"; }
msg_err() { msg "${C_RED}✗ $*${C_RESET}"; }
msg_warn(){ msg "${C_YELLOW}⚠ $*${C_RESET}"; }
msg_info(){ msg "${C_CYAN}ℹ $*${C_RESET}"; }
die()     { msg_err "$*"; exit 1; }

# ============================================================================
# Formatting Functions
# ============================================================================

header() {
    local text="$*" w=60 pad=$(( (60 - ${#1} - 2) / 2 ))
    echo "" >&2
    printf "%b" "$C_BOLD_CYAN" >&2
    printf '═%.0s' $(seq 1 $w) >&2; echo "" >&2
    printf "%*s%s%*s\n" $pad "" "$text" $pad "" >&2
    printf '═%.0s' $(seq 1 $w) >&2
    printf "%b\n\n" "$C_RESET" >&2
}

separator() { printf "%78s\n" | tr ' ' '-'; }

# ============================================================================
# Operating System Detection
# ============================================================================

declare -g OS_FAMILY="" OS_DISTRO="" OS_VERSION=""

detect_os() {
    [[ "$(uname -s)" != "Linux" ]] && { msg_err "Linux only"; return 1; }
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_DISTRO="${ID,,}"
        OS_VERSION="${VERSION_ID:-unknown}"
        
        case "$OS_DISTRO" in
            ubuntu|debian|raspbian|linuxmint|pop) OS_FAMILY="debian" ;;
            fedora|rhel|centos|rocky|alma)        OS_FAMILY="redhat" ;;
            arch|manjaro|endeavouros)              OS_FAMILY="arch" ;;
            opensuse*|sles)                        OS_FAMILY="suse" ;;
            alpine)                                OS_FAMILY="alpine" ;;
            *)                                     OS_FAMILY="unknown" ;;
        esac
    elif [[ -f /etc/redhat-release ]]; then
        OS_FAMILY="redhat"; OS_DISTRO="redhat"
    elif [[ -f /etc/debian_version ]]; then
        OS_FAMILY="debian"; OS_DISTRO="debian"
    else
        OS_FAMILY="unknown"; OS_DISTRO="unknown"
    fi

    export OS_FAMILY OS_DISTRO OS_VERSION
    debug "OS: $OS_DISTRO ($OS_FAMILY) $OS_VERSION"
    return 0
}

show_os_info() {
    echo "OS: ${OS_DISTRO} (${OS_FAMILY}) ${OS_VERSION}"
}

# ============================================================================
# OS Convenience Functions
# ============================================================================

is_debian_based() { [[ "$OS_FAMILY" == "debian" ]]; }
is_redhat_based() { [[ "$OS_FAMILY" == "redhat" ]]; }
is_arch_based()   { [[ "$OS_FAMILY" == "arch" ]]; }
is_suse_based()   { [[ "$OS_FAMILY" == "suse" ]]; }
is_alpine()       { [[ "$OS_FAMILY" == "alpine" ]]; }

get_pkg_manager() {
    case "$OS_FAMILY" in
        debian)  echo "apt" ;;
        redhat)  command -v dnf &>/dev/null && echo "dnf" || echo "yum" ;;
        arch)    echo "pacman" ;;
        suse)    echo "zypper" ;;
        alpine)  echo "apk" ;;
        *)       echo "unknown" ;;
    esac
}

check_sudo() {
    [[ $EUID -eq 0 ]] && return 0
    command -v sudo &>/dev/null && sudo -n true 2>/dev/null
}

has_sudo_access() { check_sudo; }
