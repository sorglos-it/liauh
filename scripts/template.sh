#!/bin/bash
# ============================================================================
# LIAUH Script Template
# Use this file as a starting point for new scripts
# ============================================================================

# LIAUH passes parameters as comma-separated string:
# action,VAR1=val1,VAR2=val2,...
# Example: install,DOMAIN=example.com,SSL=yes,EMAIL=admin@test.com

FULL_PARAMS="$1"

# Extract action (everything before first comma)
ACTION="${FULL_PARAMS%%,*}"

# Extract remaining parameters (everything after first comma)
PARAMS_REST="${FULL_PARAMS#*,}"

# Parse variable assignments and export them
# Convert commas to newlines, then parse each line
if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        if [[ -n "$key" ]]; then
            export "$key=$val"
        fi
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_success() {
    echo "[SUCCESS] $*"
}

# ============================================================================
# Main Script Logic
# ============================================================================

# Variables from LIAUH prompts are now available as environment variables
# Examples: $DOMAIN, $SSL_ENABLED, $PORT, etc.

main() {
    case "$ACTION" in
        install)
            handle_install
            ;;
        remove)
            handle_remove
            ;;
        update)
            handle_update
            ;;
        config)
            handle_config
            ;;
        *)
            log_error "Unknown action: $ACTION"
            exit 1
            ;;
    esac
}

# Handle install action
handle_install() {
    log_info "Starting installation..."
    
    # Access variables from prompts
    # echo "Domain: $DOMAIN"
    # echo "Port: $PORT"
    
    # Your installation logic here
    
    log_success "Installation complete"
}

# Handle remove action
handle_remove() {
    log_info "Starting removal..."
    
    # Your removal logic here
    
    log_success "Removal complete"
}

# Handle update action
handle_update() {
    log_info "Starting update..."
    
    # Your update logic here
    
    log_success "Update complete"
}

# Handle config action
handle_config() {
    log_info "Starting configuration..."
    
    # Your configuration logic here
    
    log_success "Configuration complete"
}

# ============================================================================
# Entry Point
# ============================================================================

main
exit $?
