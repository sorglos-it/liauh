#!/bin/bash

# htop - Interactive process viewer

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure htop on all Linux distributions

set -e


# Check if we need sudo


# Parse action and parameters
