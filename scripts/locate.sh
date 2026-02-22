#!/bin/bash

# locate - Fast file search using indexed database

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure locate for all Linux distributions

set -e


# Check if we need sudo


