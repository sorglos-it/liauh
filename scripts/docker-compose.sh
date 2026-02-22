#!/bin/bash

# docker-compose - Multi-container orchestration with Docker Compose

source "$(dirname "$0")/../lib/bootstrap.sh"

parse_parameters "$1"
detect_os

# Install, update, uninstall, and configure Docker Compose for all Linux distributions

set -e


# Check if we need sudo


