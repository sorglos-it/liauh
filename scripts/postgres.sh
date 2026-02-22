#!/bin/bash

# postgres - PostgreSQL relational database

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure PostgreSQL for all distributions

set -e


# Check if we need sudo


