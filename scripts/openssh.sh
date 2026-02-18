#!/bin/bash

# openssh - Secure Shell remote access
# Install, update, uninstall, and configure OpenSSH on all Linux distributions

set -e

# Parse action from first parameter
ACTION="${1%%,*}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Log informational messages with green checkmark
log_info() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

# Log warning messages with yellow exclamation
log_warn() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

# Log error messages with red X and exit
log_error() {
    printf "${RED}✗${NC} %s\n" "$1"
    exit 1
}

# Detect operating system and set appropriate package manager commands
detect_os() {
    source /etc/os-release || log_error "Cannot detect OS"
    
    case "${ID,,}" in
        ubuntu|debian|raspbian|linuxmint|pop)
            PKG_UPDATE="apt-get update"
            PKG_INSTALL="apt-get install -y"
            PKG_UNINSTALL="apt-get remove -y"
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PKG_UNINSTALL="dnf remove -y"
            ;;
        arch|manjaro|endeavouros)
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_UNINSTALL="pacman -R --noconfirm"
            ;;
        opensuse*|sles)
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            PKG_UNINSTALL="zypper remove -y"
            ;;
        alpine)
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_UNINSTALL="apk del"
            ;;
        *)
            log_error "Unsupported distribution"
            ;;
    esac
}

# Install OpenSSH server
install_openssh() {
    log_info "Installing openssh-server..."
    detect_os
    
    sudo $PKG_UPDATE || true
    sudo $PKG_INSTALL openssh-server || log_error "Failed"
    
    # Enable SSH service (handle both 'ssh' and 'sshd' service names)
    sudo systemctl enable ssh || sudo systemctl enable sshd
    
    log_info "openssh-server installed and enabled!"
}

# Update OpenSSH server
update_openssh() {
    log_info "Updating openssh-server..."
    detect_os
    
    sudo $PKG_UPDATE || true
    sudo $PKG_INSTALL openssh-server || log_error "Failed"
    
    log_info "openssh-server updated!"
}

# Uninstall OpenSSH server
uninstall_openssh() {
    log_info "Uninstalling openssh-server..."
    detect_os
    
    # Disable SSH service (handle both 'ssh' and 'sshd' service names)
    sudo systemctl disable sshd || sudo systemctl disable ssh
    sudo $PKG_UNINSTALL openssh-server || log_error "Failed"
    
    log_info "openssh-server uninstalled!"
}

# Configure OpenSSH server interactively with comprehensive options
configure_openssh() {
    log_info "Configuring OpenSSH server (comprehensive configuration)..."
    
    # Ensure sshd_config.d directory exists
    sudo mkdir -p /etc/ssh/sshd_config.d || log_error "Failed to create /etc/ssh/sshd_config.d"
    
    # Create backup of current config
    BACKUP_FILE="/etc/ssh/sshd_config.d/liauh.conf.backup.$(date +%s)"
    if [[ -f /etc/ssh/sshd_config.d/liauh.conf ]]; then
        sudo cp /etc/ssh/sshd_config.d/liauh.conf "$BACKUP_FILE" || log_warn "Failed to backup existing config"
        log_info "Backed up previous config to $BACKUP_FILE"
    fi
    
    echo "========================================"
    echo "NETWORK & CONNECTIVITY OPTIONS"
    echo "========================================"
    read -p "[NETWORK] SSH listening port (default: 22): " SSH_PORT
    SSH_PORT="${SSH_PORT:-22}"
    
    read -p "[NETWORK] Listen on IPv4 address (default: 0.0.0.0): " LISTEN_IPv4
    LISTEN_IPv4="${LISTEN_IPv4:-0.0.0.0}"
    
    read -p "[NETWORK] Listen on IPv6 address (default: ::, empty to skip): " LISTEN_IPv6
    LISTEN_IPv6="${LISTEN_IPv6:-::}"
    
    read -p "[NETWORK] SSH Protocol version (default: 2): " SSH_PROTOCOL
    SSH_PROTOCOL="${SSH_PROTOCOL:-2}"
    
    read -p "[NETWORK] TCP Keep Alive? (yes/no, default: yes): " TCP_KEEPALIVE
    TCP_KEEPALIVE="${TCP_KEEPALIVE:-yes}"
    
    read -p "[NETWORK] Address Family (any/inet/inet6, default: any): " ADDRESS_FAMILY
    ADDRESS_FAMILY="${ADDRESS_FAMILY:-any}"
    
    echo ""
    echo "========================================"
    echo "AUTHENTICATION OPTIONS"
    echo "========================================"
    read -p "[AUTH] Password Authentication? (yes/no, default: yes): " PASS_AUTH
    PASS_AUTH="${PASS_AUTH:-yes}"
    
    read -p "[AUTH] Public Key Authentication? (yes/no, default: yes): " PUBKEY_AUTH
    PUBKEY_AUTH="${PUBKEY_AUTH:-yes}"
    
    read -p "[AUTH] Kerberos Authentication? (yes/no, default: no): " KERBEROS_AUTH
    KERBEROS_AUTH="${KERBEROS_AUTH:-no}"
    
    read -p "[AUTH] GSSAPI Authentication? (yes/no, default: no): " GSSAPI_AUTH
    GSSAPI_AUTH="${GSSAPI_AUTH:-no}"
    
    read -p "[AUTH] Use PAM? (yes/no, default: yes): " USE_PAM
    USE_PAM="${USE_PAM:-yes}"
    
    read -p "[AUTH] Authentication methods (empty for default): " AUTH_METHODS
    
    read -p "[AUTH] Max authentication attempts (default: 6): " MAX_AUTH_TRIES
    MAX_AUTH_TRIES="${MAX_AUTH_TRIES:-6}"
    
    echo ""
    echo "========================================"
    echo "ROOT LOGIN & USER RESTRICTIONS"
    echo "========================================"
    read -p "[USERS] Permit Root Login (yes/no/prohibit-password/without-password, default: prohibit-password): " PERMIT_ROOT
    PERMIT_ROOT="${PERMIT_ROOT:-prohibit-password}"
    
    read -p "[USERS] Allow Users (comma-separated, empty for none): " ALLOW_USERS
    
    read -p "[USERS] Allow Groups (comma-separated, empty for none): " ALLOW_GROUPS
    
    read -p "[USERS] Deny Users (comma-separated, empty for none): " DENY_USERS
    
    read -p "[USERS] Deny Groups (comma-separated, empty for none): " DENY_GROUPS
    
    echo ""
    echo "========================================"
    echo "SECURITY OPTIONS"
    echo "========================================"
    read -p "[SECURITY] Strict Modes? (yes/no, default: yes): " STRICT_MODES
    STRICT_MODES="${STRICT_MODES:-yes}"
    
    read -p "[SECURITY] Permit User Environment? (yes/no, default: no): " PERMIT_USER_ENV
    PERMIT_USER_ENV="${PERMIT_USER_ENV:-no}"
    
    read -p "[SECURITY] Permit Empty Passwords? (yes/no, default: no): " PERMIT_EMPTY_PASS
    PERMIT_EMPTY_PASS="${PERMIT_EMPTY_PASS:-no}"
    
    read -p "[SECURITY] Permit Tunnel? (yes/no, default: no): " PERMIT_TUNNEL
    PERMIT_TUNNEL="${PERMIT_TUNNEL:-no}"
    
    read -p "[SECURITY] Compression (yes/no/delayed, default: delayed): " COMPRESSION
    COMPRESSION="${COMPRESSION:-delayed}"
    
    read -p "[SECURITY] Client Alive Interval seconds (0=disabled, default: 300): " CLIENT_ALIVE_INTERVAL
    CLIENT_ALIVE_INTERVAL="${CLIENT_ALIVE_INTERVAL:-300}"
    
    read -p "[SECURITY] Client Alive Count Max (default: 3): " CLIENT_ALIVE_COUNTMAX
    CLIENT_ALIVE_COUNTMAX="${CLIENT_ALIVE_COUNTMAX:-3}"
    
    read -p "[SECURITY] Login Grace Time seconds (default: 120): " LOGIN_GRACE_TIME
    LOGIN_GRACE_TIME="${LOGIN_GRACE_TIME:-120}"
    
    echo ""
    echo "========================================"
    echo "X11 & FORWARDING OPTIONS"
    echo "========================================"
    read -p "[FORWARDING] X11 Forwarding? (yes/no, default: no): " X11_FORWARDING
    X11_FORWARDING="${X11_FORWARDING:-no}"
    
    read -p "[FORWARDING] X11 Use Localhost? (yes/no, default: yes): " X11_USE_LOCALHOST
    X11_USE_LOCALHOST="${X11_USE_LOCALHOST:-yes}"
    
    read -p "[FORWARDING] Allow Agent Forwarding? (yes/no, default: yes): " ALLOW_AGENT_FORWARD
    ALLOW_AGENT_FORWARD="${ALLOW_AGENT_FORWARD:-yes}"
    
    read -p "[FORWARDING] Allow TCP Forwarding (yes/no/local/remote, default: yes): " ALLOW_TCP_FORWARD
    ALLOW_TCP_FORWARD="${ALLOW_TCP_FORWARD:-yes}"
    
    read -p "[FORWARDING] Gateway Ports? (yes/no, default: no): " GATEWAY_PORTS
    GATEWAY_PORTS="${GATEWAY_PORTS:-no}"
    
    echo ""
    echo "========================================"
    echo "LOGGING & DISPLAY OPTIONS"
    echo "========================================"
    read -p "[LOGGING] Print MOTD? (yes/no, default: yes): " PRINT_MOTD
    PRINT_MOTD="${PRINT_MOTD:-yes}"
    
    read -p "[LOGGING] Print Last Log? (yes/no, default: yes): " PRINT_LASTLOG
    PRINT_LASTLOG="${PRINT_LASTLOG:-yes}"
    
    read -p "[LOGGING] Log Level (QUIET/FATAL/ERROR/INFO/VERBOSE/DEBUG, default: INFO): " LOG_LEVEL
    LOG_LEVEL="${LOG_LEVEL:-INFO}"
    
    read -p "[LOGGING] Banner file path (empty for none, e.g., /etc/ssh/banner): " BANNER
    
    read -p "[LOGGING] Syslog Facility (AUTH/AUTHPRIV/DAEMON/LOCAL0-7, default: AUTH): " SYSLOG_FACILITY
    SYSLOG_FACILITY="${SYSLOG_FACILITY:-AUTH}"
    
    echo ""
    echo "========================================"
    echo "KEYS & CRYPTOGRAPHY OPTIONS"
    echo "========================================"
    read -p "[CRYPTO] Host Key Algorithms (comma-separated, empty for defaults): " HOST_KEY_ALGORITHMS
    
    read -p "[CRYPTO] Ciphers (comma-separated, empty for defaults): " CIPHERS
    
    read -p "[CRYPTO] MACs (comma-separated, empty for defaults): " MACS
    
    read -p "[CRYPTO] Key Exchange Algorithms (comma-separated, empty for defaults): " KEY_EXCHANGE_ALGOS
    
    read -p "[CRYPTO] Rekey Limit (e.g., '1G 1h', empty for defaults): " REKEY_LIMIT
    
    read -p "[CRYPTO] Authorized Keys File (default: .ssh/authorized_keys): " AUTHORIZED_KEYS_FILE
    AUTHORIZED_KEYS_FILE="${AUTHORIZED_KEYS_FILE:-.ssh/authorized_keys}"
    
    echo ""
    echo "========================================"
    echo "SUBSYSTEM OPTIONS"
    echo "========================================"
    read -p "[SUBSYSTEM] SFTP subsystem path (default: /usr/lib/openssh/sftp-server): " SFTP_SUBSYSTEM
    SFTP_SUBSYSTEM="${SFTP_SUBSYSTEM:-/usr/lib/openssh/sftp-server}"
    
    # Generate configuration content with all options
    CONFIG_CONTENT="# OpenSSH SSH daemon configuration
# Generated by liauh - Do not edit manually
# Use: liauh openssh config
# Backup: $BACKUP_FILE
# Date: $(date)

# ========== NETWORK & CONNECTIVITY ==========
Port $SSH_PORT
ListenAddress $LISTEN_IPv4"
    
    if [[ -n "$LISTEN_IPv6" ]]; then
        CONFIG_CONTENT+="
ListenAddress $LISTEN_IPv6"
    fi
    
    CONFIG_CONTENT+="
Protocol $SSH_PROTOCOL
AddressFamily $ADDRESS_FAMILY
TCPKeepAlive $TCP_KEEPALIVE

# ========== AUTHENTICATION ==========
PasswordAuthentication $PASS_AUTH
PubkeyAuthentication $PUBKEY_AUTH
KerberosAuthentication $KERBEROS_AUTH
GSSAPIAuthentication $GSSAPI_AUTH
UsePAM $USE_PAM
MaxAuthTries $MAX_AUTH_TRIES"
    
    if [[ -n "$AUTH_METHODS" ]]; then
        CONFIG_CONTENT+="
AuthenticationMethods $AUTH_METHODS"
    fi
    
    CONFIG_CONTENT+="

# ========== ROOT LOGIN & USER RESTRICTIONS ==========
PermitRootLogin $PERMIT_ROOT"
    
    if [[ -n "$ALLOW_USERS" ]]; then
        CONFIG_CONTENT+="
AllowUsers $ALLOW_USERS"
    fi
    
    if [[ -n "$ALLOW_GROUPS" ]]; then
        CONFIG_CONTENT+="
AllowGroups $ALLOW_GROUPS"
    fi
    
    if [[ -n "$DENY_USERS" ]]; then
        CONFIG_CONTENT+="
DenyUsers $DENY_USERS"
    fi
    
    if [[ -n "$DENY_GROUPS" ]]; then
        CONFIG_CONTENT+="
DenyGroups $DENY_GROUPS"
    fi
    
    CONFIG_CONTENT+="

# ========== SECURITY ==========
StrictModes $STRICT_MODES
PermitUserEnvironment $PERMIT_USER_ENV
PermitEmptyPasswords $PERMIT_EMPTY_PASS
PermitTunnel $PERMIT_TUNNEL
Compression $COMPRESSION
ClientAliveInterval $CLIENT_ALIVE_INTERVAL
ClientAliveCountMax $CLIENT_ALIVE_COUNTMAX
LoginGraceTime $LOGIN_GRACE_TIME

# ========== X11 & FORWARDING ==========
X11Forwarding $X11_FORWARDING
X11UseLocalhost $X11_USE_LOCALHOST
AllowAgentForwarding $ALLOW_AGENT_FORWARD
AllowTcpForwarding $ALLOW_TCP_FORWARD
GatewayPorts $GATEWAY_PORTS

# ========== LOGGING & DISPLAY ==========
PrintMotd $PRINT_MOTD
PrintLastLog $PRINT_LASTLOG
LogLevel $LOG_LEVEL
SyslogFacility $SYSLOG_FACILITY"
    
    if [[ -n "$BANNER" ]]; then
        CONFIG_CONTENT+="
Banner $BANNER"
    fi
    
    CONFIG_CONTENT+="

# ========== KEYS & CRYPTOGRAPHY ==========
AuthorizedKeysFile $AUTHORIZED_KEYS_FILE"
    
    if [[ -n "$HOST_KEY_ALGORITHMS" ]]; then
        CONFIG_CONTENT+="
HostKeyAlgorithms $HOST_KEY_ALGORITHMS"
    fi
    
    if [[ -n "$CIPHERS" ]]; then
        CONFIG_CONTENT+="
Ciphers $CIPHERS"
    fi
    
    if [[ -n "$MACS" ]]; then
        CONFIG_CONTENT+="
MACs $MACS"
    fi
    
    if [[ -n "$KEY_EXCHANGE_ALGOS" ]]; then
        CONFIG_CONTENT+="
KeyExchangeAlgorithms $KEY_EXCHANGE_ALGOS"
    fi
    
    if [[ -n "$REKEY_LIMIT" ]]; then
        CONFIG_CONTENT+="
RekeyLimit $REKEY_LIMIT"
    fi
    
    CONFIG_CONTENT+="

# ========== SUBSYSTEM ==========
Subsystem sftp $SFTP_SUBSYSTEM
"
    
    # Write configuration to temporary file first
    TEMP_CONFIG="/tmp/liauh-sshd-config.$$.conf"
    echo "$CONFIG_CONTENT" > "$TEMP_CONFIG"
    
    # Copy to final location
    sudo cp "$TEMP_CONFIG" /etc/ssh/sshd_config.d/liauh.conf || log_error "Failed to write config to /etc/ssh/sshd_config.d/liauh.conf"
    
    # Cleanup temp file
    rm -f "$TEMP_CONFIG"
    
    log_info "Configuration written to /etc/ssh/sshd_config.d/liauh.conf"
    
    # Validate SSH configuration
    if ! sudo sshd -t 2>&1 | tee /tmp/sshd-validation.log; then
        log_error "SSH configuration validation failed. See /tmp/sshd-validation.log for details"
    fi
    
    log_info "SSH configuration validation passed"
    
    # Restart SSH service
    log_info "Restarting SSH service..."
    if sudo systemctl restart sshd 2>/dev/null || sudo systemctl restart ssh 2>/dev/null; then
        log_info "SSH service restarted successfully"
    else
        log_error "Failed to restart SSH service"
    fi
    
    log_info "OpenSSH server configured successfully!"
}

# Fix Xauthority file permissions and generate trust (for X11 forwarding)
fix_xauthority() {
    log_info "Fixing X11 Xauthority configuration..."
    
    # Create .Xauthority file if it doesn't exist
    sudo touch /root/.Xauthority
    
    # Set proper ownership
    sudo chown root:root /root/.Xauthority
    
    # Set restrictive permissions (600 = rw-------)
    sudo chmod 600 /root/.Xauthority
    
    # Generate trusted X11 authority for display :0
    sudo xauth generate :0 . trusted || log_warn "xauth generate completed with warnings"
    
    log_info "X11 Xauthority fixed successfully!"
}

# Route to appropriate action
case "$ACTION" in
    install)
        install_openssh
        ;;
    update)
        update_openssh
        ;;
    uninstall)
        uninstall_openssh
        ;;
    config)
        configure_openssh
        ;;
    fix-xauthority)
        fix_xauthority
        ;;
    *)
        log_error "Unknown action: $ACTION"
        ;;
esac
