#!/bin/bash
#
# JTS Warm Storage (SATA) Setup Script
# 
# Generated from: specs/1000/1001/1013.md
# Context: specs/1000/1001/1013.context.md
# Created: 2025-08-25
# Purpose: Configure 1TB SATA drive as intermediate warm storage
#
# This script configures a 1TB SATA drive as intermediate warm storage
# with btrfs filesystem and zstd:3 compression for optimal space efficiency.
#
# Prerequisites:
# - 1TB SATA drive at /dev/sda2 (931.5G partition)
# - Root privileges for filesystem operations
# - btrfs-progs package installed
#

set -euo pipefail

# Configuration
DEVICE="/dev/sda2"
MOUNT_POINT="/data/warm-storage"
LABEL="jts-warm-storage"
FILESYSTEM_TYPE="btrfs"
COMPRESSION="zstd:3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Verify SATA drive and partition
verify_drive() {
    log "Verifying SATA drive and partition..."
    
    if [[ ! -b "$DEVICE" ]]; then
        error "Device $DEVICE not found"
        exit 1
    fi
    
    # Get drive info
    DRIVE_INFO=$(lsblk -o NAME,SIZE,MODEL,TRAN "$DEVICE" --noheadings)
    log "Drive information: $DRIVE_INFO"
    
    # Check if partition is mounted
    if mount | grep -q "$DEVICE"; then
        error "Device $DEVICE is currently mounted. Please unmount first."
        exit 1
    fi
    
    success "Drive verification completed"
}

# Format SATA partition with btrfs
format_filesystem() {
    log "Formatting $DEVICE with btrfs filesystem..."
    
    # Confirm operation
    warn "This will DESTROY all data on $DEVICE"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        error "Operation cancelled by user"
        exit 1
    fi
    
    # Format with btrfs and compression
    log "Creating btrfs filesystem with zstd:3 compression..."
    mkfs.btrfs -f -L "$LABEL" \
        -O compress-force="$COMPRESSION" \
        "$DEVICE"
    
    # Verify filesystem creation
    log "Verifying filesystem creation..."
    btrfs filesystem show "$DEVICE" || {
        error "Filesystem verification failed"
        exit 1
    }
    
    success "Btrfs filesystem created successfully"
}

# Create mount point and configure fstab
configure_mount() {
    log "Configuring mount point and fstab..."
    
    # Create mount point
    mkdir -p "$MOUNT_POINT"
    log "Created mount point: $MOUNT_POINT"
    
    # Backup fstab
    cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
    log "Backed up fstab"
    
    # Add fstab entry
    FSTAB_ENTRY="$DEVICE $MOUNT_POINT $FILESYSTEM_TYPE defaults,compress=$COMPRESSION,autodefrag,noatime 0 2"
    
    # Check if entry already exists
    if ! grep -q "$DEVICE" /etc/fstab; then
        echo "$FSTAB_ENTRY" >> /etc/fstab
        log "Added fstab entry: $FSTAB_ENTRY"
    else
        warn "Fstab entry for $DEVICE already exists, skipping"
    fi
    
    # Mount filesystem
    log "Mounting filesystem..."
    mount "$MOUNT_POINT"
    
    # Verify mount
    if mount | grep -q "$MOUNT_POINT"; then
        success "Filesystem mounted successfully"
        mount | grep "$MOUNT_POINT"
    else
        error "Mount verification failed"
        exit 1
    fi
}

# Create directory structure
create_directories() {
    log "Creating directory structure..."
    
    # Main directories
    mkdir -p "$MOUNT_POINT"/{daily-backups,logs,temp-processing}
    
    # Backup subdirectories
    mkdir -p "$MOUNT_POINT/daily-backups"/{postgresql,clickhouse,mongodb}
    
    # Log subdirectories  
    mkdir -p "$MOUNT_POINT/logs"/{application,system,audit}
    
    # Set permissions
    chmod 755 "$MOUNT_POINT"
    chmod 755 "$MOUNT_POINT/daily-backups"
    chmod 755 "$MOUNT_POINT/logs"
    chmod 755 "$MOUNT_POINT/temp-processing"
    
    # Display structure
    log "Directory structure created:"
    tree "$MOUNT_POINT" || ls -la "$MOUNT_POINT"
    
    success "Directory structure completed"
}

# Test compression effectiveness
test_compression() {
    log "Testing compression effectiveness..."
    
    # Create test file
    TEST_FILE="$MOUNT_POINT/compression-test"
    log "Creating 100MB test file..."
    dd if=/dev/zero of="$TEST_FILE" bs=1M count=100 status=progress
    
    # Check file size vs disk usage
    FILE_SIZE=$(ls -lh "$TEST_FILE" | awk '{print $5}')
    DISK_USAGE=$(du -sh "$TEST_FILE" | awk '{print $1}')
    
    log "File size: $FILE_SIZE"
    log "Disk usage: $DISK_USAGE"
    
    # Calculate compression ratio
    if [[ "$DISK_USAGE" =~ ^([0-9]+)([A-Za-z]+)$ ]]; then
        USAGE_NUM=${BASH_REMATCH[1]}
        USAGE_UNIT=${BASH_REMATCH[2]}
        
        if [[ "$USAGE_NUM" -lt 10 && "$USAGE_UNIT" == "M" ]]; then
            success "Compression working effectively (${DISK_USAGE} vs ${FILE_SIZE})"
        else
            warn "Compression may not be optimal (${DISK_USAGE} vs ${FILE_SIZE})"
        fi
    fi
    
    # Cleanup test file
    rm "$TEST_FILE"
    log "Cleaned up test file"
    
    # Show filesystem usage
    log "Filesystem usage:"
    btrfs filesystem usage "$MOUNT_POINT"
}

# Configure system integration
configure_system_integration() {
    log "Configuring system integration..."
    
    # Configure logrotate
    cat > /etc/logrotate.d/warm-storage << 'EOF'
/data/warm-storage/logs/*/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
    
    log "Configured logrotate for warm storage"
    
    # Set up automatic cleanup cron job
    CRON_ENTRY="0 2 * * * root find /data/warm-storage/temp-processing -mtime +3 -delete"
    
    # Add to crontab if not exists
    if ! grep -q "/data/warm-storage/temp-processing" /etc/crontab; then
        echo "$CRON_ENTRY" >> /etc/crontab
        log "Added automatic cleanup cron job"
    else
        warn "Cleanup cron job already exists"
    fi
    
    success "System integration configured"
}

# Main execution
main() {
    log "Starting JTS Warm Storage (SATA) Setup..."
    
    check_root
    verify_drive
    format_filesystem
    configure_mount
    create_directories
    test_compression
    configure_system_integration
    
    success "Warm storage setup completed successfully!"
    log "Mount point: $MOUNT_POINT"
    log "Device: $DEVICE ($LABEL)"
    log "Filesystem: $FILESYSTEM_TYPE with $COMPRESSION compression"
    
    # Display final status
    echo
    log "Final status:"
    df -h "$MOUNT_POINT"
    echo
    btrfs filesystem show "$DEVICE"
}

# Execute main function
main "$@"