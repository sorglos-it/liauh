#!/bin/bash

# samba - Network file sharing with Samba/SMB

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure Samba for all Linux distributions

set -e


# Check if we need sudo


