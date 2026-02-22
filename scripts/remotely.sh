#!/bin/bash

# remotely - Remote desktop and support software

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install and manage Remotely - open-source remote desktop and remote support tool

set -e


# Check if we need sudo


# Parse action and parameters
