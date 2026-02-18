#!/bin/bash
set -e
FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"
[[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]] && while IFS='=' read -r key val; do [[ -n "$key" ]] && export "$key=$val"; done <<< "${PARAMS_REST//,/$'\n'}"
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
log_info() { printf "${GREEN}✓${NC} %s\n" "$1"; }; log_error() { printf "${RED}✗${NC} %s\n" "$1"; exit 1; }
detect_os() { source /etc/os-release || log_error "Cannot detect OS"; [[ "${ID,,}" == "arch" ]] || log_error "This script is for Arch (PiKVM v3) only"; }
case "$ACTION" in
  update) log_info "Updating PiKVM v3..."; detect_os; sudo pacman -Syu --noconfirm || log_error "Failed"; log_info "PiKVM v3 updated!" ;;
  mount-iso) log_info "Mounting ISO directory..."; detect_os; sudo mount -o remount,rw /mnt/msd || log_error "Failed"; log_info "ISO directory mounted (rw)!" ;;
  dismount-iso) log_info "Dismounting ISO directory..."; detect_os; sudo mount -o remount,ro /mnt/msd || log_error "Failed"; log_info "ISO directory dismounted (ro)!" ;;
  oled-enable) log_info "Enabling OLED..."; detect_os; sudo systemctl enable --now pikvm-oled || log_error "Failed"; log_info "OLED enabled!" ;;
  vnc-enable) log_info "Enabling VNC..."; detect_os; sudo systemctl enable --now vncserver-x11-serviced || log_error "Failed"; log_info "VNC enabled!" ;;
  *) log_error "Unknown action: $ACTION" ;;
esac
