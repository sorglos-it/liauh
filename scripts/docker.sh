#!/bin/bash

# docker - Container platform

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure Docker on all Linux distributions

set -e


# Check if we need sudo


# Parse action and parameters
