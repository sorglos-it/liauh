#!/bin/bash
set -e
FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"
[[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]] && while IFS='=' read -r key val; do [[ -n "$key" ]] && export "$key=$val"; done <<< "${PARAMS_REST//,/$'\n'}"
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
log_info() { printf "${GREEN}✓${NC} %s\n" "$1"; }; log_error() { printf "${RED}✗${NC} %s\n" "$1"; exit 1; }
detect_os() { source /etc/os-release || log_error "Cannot detect OS"; [[ "${ID,,}" == "debian" ]] || log_error "This script is for Debian only"; }
case "$ACTION" in
  update) log_info "Updating Debian..."; detect_os; sudo apt-get update || true; sudo apt-get upgrade -y || log_error "Failed"; sudo apt-get autoremove -y || true; log_info "Debian updated!" ;;
  dist-upgrade) log_info "Distribution upgrade..."; detect_os; sudo apt-get update || true; sudo apt-get dist-upgrade -y || log_error "Failed"; log_info "Debian dist-upgrade complete!" ;;
  *) log_error "Unknown action: $ACTION" ;;
esac
