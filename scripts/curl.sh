#!/bin/bash

# curl - HTTP requests utility

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure curl for all Linux distributions

set -e


# Check if we need sudo


