#!/bin/bash

# cifs-utils - Mount and manage SMB/CIFS network shares

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install CIFS utilities to mount and manage SMB file shares from Windows and Samba servers

set -e


# Check if we need sudo


