#!/bin/bash

# mysql - MySQL relational database

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure MySQL for all distributions

set -e


# Check if we need sudo


