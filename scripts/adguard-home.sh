#!/bin/bash

# adguard-home - DNS ad-blocking with advanced filtering

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure AdGuard Home for all Linux distributions

set -e


# Check if we need sudo


