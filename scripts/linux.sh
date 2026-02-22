#!/bin/bash

# linux - Linux System Configuration Script

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Manage network, DNS, hostname, users, and groups on Linux systems

set -e


# Check if we need sudo


