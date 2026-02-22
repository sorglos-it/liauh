#!/bin/bash

# portainer - Portainer Docker Management UI

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, and manage Portainer Docker management platform

set -e


# Check if we need sudo


