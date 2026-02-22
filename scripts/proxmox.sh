#!/bin/bash

# proxmox - Guest agent and container management for Proxmox hosts

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Manages qemu-guest-agent (for guests) and VM/LXC container operations

set -e


# Check if we need sudo


# Parse action and parameters
