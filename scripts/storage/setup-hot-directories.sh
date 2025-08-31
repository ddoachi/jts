#!/bin/bash
# ============================================================================
# Hot Storage (NVMe) Directory Setup Script
# ============================================================================
# Generated from: specs/1000/1001/1011.md
# Context: specs/1000/1001/1011.context.md
# Created: 2025-08-24
# Purpose: Set up foundational directory structure for hot storage
#
# This script sets up the foundational directory structure for JTS hot storage
# on NVMe SSD with proper permissions and service user configuration.
#
# Usage: sudo ./scripts/setup-hot-directories.sh
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

log "Starting JTS Hot Storage Directory Setup"
echo "========================================"

# Step 1: Pre-Implementation Verification
log "Step 1: Verifying system prerequisites..."

# Check disk space
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
if [[ $AVAILABLE_SPACE -lt 1000000 ]]; then  # Less than ~1GB in KB
    warning "Low disk space detected. Available: $(df -h / | tail -1 | awk '{print $4}')"
else
    success "Sufficient disk space available: $(df -h / | tail -1 | awk '{print $4}')"
fi

# Step 2: Create Service Users
log "Step 2: Creating database service users..."

USERS=("postgres" "clickhouse" "kafka" "mongodb" "redis")
for user in "${USERS[@]}"; do
    if id "$user" &>/dev/null; then
        success "User $user already exists"
    else
        if useradd -r -s /bin/false "$user"; then
            success "Created system user: $user"
        else
            error "Failed to create user: $user"
            exit 1
        fi
    fi
done

# Verify docker group exists
if getent group docker > /dev/null; then
    success "Docker group exists"
else
    warning "Docker group doesn't exist - creating it"
    groupadd docker
fi

# Step 3: Create Base Directory Structure
log "Step 3: Creating base directory structure..."

BASE_DIR="/data/jts/hot"
if mkdir -p "$BASE_DIR"; then
    success "Created base directory: $BASE_DIR"
else
    error "Failed to create base directory: $BASE_DIR"
    exit 1
fi

# Create service directories
SERVICE_DIRS=("postgresql" "clickhouse" "kafka" "mongodb" "redis" "docker" "backup")
for service in "${SERVICE_DIRS[@]}"; do
    if mkdir -p "$BASE_DIR/$service"; then
        success "Created service directory: $service"
    else
        error "Failed to create service directory: $service"
        exit 1
    fi
done

# Step 4: Create Organized Subdirectories
log "Step 4: Creating organized subdirectories for each service..."

# PostgreSQL subdirectories
mkdir -p "$BASE_DIR/postgresql"/{data,logs,config}
success "Created PostgreSQL subdirectories: data, logs, config"

# ClickHouse subdirectories  
mkdir -p "$BASE_DIR/clickhouse"/{data,logs,tmp}
success "Created ClickHouse subdirectories: data, logs, tmp"

# Kafka subdirectories
mkdir -p "$BASE_DIR/kafka"/{data,logs}
success "Created Kafka subdirectories: data, logs"

# MongoDB subdirectories
mkdir -p "$BASE_DIR/mongodb"/{data,logs,config}
success "Created MongoDB subdirectories: data, logs, config"

# Redis subdirectories
mkdir -p "$BASE_DIR/redis"/{data,logs}
success "Created Redis subdirectories: data, logs"

# Docker subdirectories
mkdir -p "$BASE_DIR/docker"/{volumes,containers,tmp}
success "Created Docker subdirectories: volumes, containers, tmp"

# Backup subdirectories
mkdir -p "$BASE_DIR/backup"/{daily,snapshots,staging}
success "Created Backup subdirectories: daily, snapshots, staging"

# Step 5: Configure Ownership and Permissions
log "Step 5: Configuring ownership and permissions..."

# Set ownership for each service
chown -R postgres:postgres "$BASE_DIR/postgresql/"
success "Set ownership for PostgreSQL directory"

chown -R clickhouse:clickhouse "$BASE_DIR/clickhouse/"
success "Set ownership for ClickHouse directory"

chown -R kafka:kafka "$BASE_DIR/kafka/"
success "Set ownership for Kafka directory"

chown -R mongodb:mongodb "$BASE_DIR/mongodb/"
success "Set ownership for MongoDB directory"

chown -R redis:redis "$BASE_DIR/redis/"
success "Set ownership for Redis directory"

chown -R root:docker "$BASE_DIR/docker/"
success "Set ownership for Docker directory"

chown -R root:root "$BASE_DIR/backup/"
success "Set ownership for Backup directory"

# Set permissions
chmod 750 "$BASE_DIR"/{postgresql,clickhouse,kafka,mongodb,redis}/
chmod 755 "$BASE_DIR"/{docker,backup}/
chmod 755 "$BASE_DIR"
success "Configured directory permissions"

# Step 6: Validate Installation
log "Step 6: Validating installation..."

# Test write access for each service user
TEMP_FILES=()

# Map users to their corresponding directories
declare -A USER_DIR_MAP
USER_DIR_MAP["postgres"]="postgresql"
USER_DIR_MAP["clickhouse"]="clickhouse"
USER_DIR_MAP["kafka"]="kafka"
USER_DIR_MAP["mongodb"]="mongodb"
USER_DIR_MAP["redis"]="redis"

for user in "${USERS[@]}"; do
    if [[ "$user" != "root" ]]; then
        service_dir="${USER_DIR_MAP[$user]}"
        TEST_FILE="$BASE_DIR/$service_dir/test_write_$$"
        if sudo -u "$user" touch "$TEST_FILE" 2>/dev/null; then
            success "Write access validated for user: $user"
            TEMP_FILES+=("$TEST_FILE")
        else
            error "Write access failed for user: $user"
            exit 1
        fi
    fi
done

# Clean up test files
for file in "${TEMP_FILES[@]}"; do
    rm -f "$file"
done
success "Cleaned up test files"

# Display directory structure
log "Final directory structure:"
if command -v tree >/dev/null 2>&1; then
    tree "$BASE_DIR" -L 3
else
    ls -la "$BASE_DIR"
    for dir in "$BASE_DIR"/*; do
        if [[ -d "$dir" ]]; then
            echo "$(basename "$dir"):"
            ls -la "$dir"
            echo
        fi
    done
fi

success "Hot Storage Directory Setup completed successfully!"
echo
log "Summary:"
echo "- Base directory: $BASE_DIR"
echo "- Service users created: ${USERS[*]}"
echo "- Total directories created: $(find "$BASE_DIR" -type d | wc -l)"
echo "- Permissions configured for secure multi-service access"
echo
log "Next steps:"
echo "1. Run validation script: ./scripts/validate-directories.sh"
echo "2. Install monitoring script: ./scripts/setup-hot-directories.sh install-monitor"
echo "3. Review documentation: docs/HOT_STORAGE_SETUP.md"