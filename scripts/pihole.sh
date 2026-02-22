#!/bin/bash

# pihole - DNS ad-blocking and network filtering

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure Pi-hole for all Linux distributions

set -e

# Check if we need sudo

