#!/bin/bash

# git - Version control system

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure git for all Linux distributions

set -e


# Check if we need sudo


