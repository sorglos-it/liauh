#!/bin/bash

# vim - Vi IMproved text editor

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure vim on all Linux distributions

set -e


# Check if we need sudo


# ============================================================================
# Parameter Parsing
# ============================================================================
