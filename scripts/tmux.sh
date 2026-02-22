#!/bin/bash

# tmux - Terminal multiplexer

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure tmux on all Linux distributions

set -e


# Check if we need sudo


# Parse action from first parameter
