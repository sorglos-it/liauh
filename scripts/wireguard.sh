#!/bin/bash

# wireguard - VPN tunnel management

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure WireGuard VPN on all Linux distributions

set -e


# Check if we need sudo


# Parse action and parameters
