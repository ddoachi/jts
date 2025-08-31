#!/bin/bash
# Generated from: [Database Mount Integration](../../1012.md)
# Context: [Implementation Context](../../1012.context.md)
# Created: 2025-08-27
# Purpose: Create and configure mount point directories for database services

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check if LVM volumes exist (from spec 1011)
check_lvm_volumes() {
    log_info "Checking for LVM volumes from hot storage setup..."
    
    local required_volumes=(
        "vg_jts-lv_postgresql"
        "vg_jts-lv_clickhouse"
        "vg_jts-lv_kafka"
        "vg_jts-lv_mongodb"
        "vg_jts-lv_redis"
        "vg_jts-lv_docker"
    )
    
    local missing_volumes=()
    for volume in "${required_volumes[@]}"; do
        if ! lvdisplay "/dev/$volume" &>/dev/null; then
            log_warning "LVM volume /dev/$volume not found"
            missing_volumes+=("$volume")
        else
            log_success "Found LVM volume: /dev/$volume"
        fi
    done
    
    if [[ ${#missing_volumes[@]} -gt 0 ]]; then
        log_warning "Missing LVM volumes: ${missing_volumes[*]}"
        log_warning "Please ensure spec 1011 (Hot Storage Foundation) is completed first"
        return 1
    fi
    
    return 0
}

# Create mount point directory
create_mount_directory() {
    local dir_path=$1
    local description=$2
    
    log_info "Creating mount directory: $dir_path ($description)"
    
    if [[ -d "$dir_path" ]]; then
        log_warning "Directory $dir_path already exists"
        
        # Check if it's already a mount point
        if mountpoint -q "$dir_path" 2>/dev/null; then
            log_warning "$dir_path is already a mount point"
            df -h "$dir_path"
        fi
    else
        if mkdir -p "$dir_path"; then
            log_success "Created directory: $dir_path"
        else
            log_error "Failed to create directory: $dir_path"
            return 1
        fi
    fi
    
    return 0
}

# Create subdirectory structure for a database
create_database_subdirs() {
    local base_dir=$1
    local db_type=$2
    
    log_info "Creating subdirectories for $db_type..."
    
    case "$db_type" in
        postgresql)
            local subdirs=("data" "logs" "config" "backups" "wal")
            ;;
        clickhouse)
            local subdirs=("data" "logs" "config" "tmp" "user_files")
            ;;
        kafka)
            local subdirs=("data" "logs" "config" "scripts")
            ;;
        mongodb)
            local subdirs=("data" "logs" "config" "journal")
            ;;
        redis)
            local subdirs=("data" "logs" "config")
            ;;
        docker)
            local subdirs=("volumes" "images" "containers" "tmp")
            ;;
        *)
            log_warning "Unknown database type: $db_type"
            return 0
            ;;
    esac
    
    for subdir in "${subdirs[@]}"; do
        local full_path="$base_dir/$subdir"
        if [[ ! -d "$full_path" ]]; then
            if mkdir -p "$full_path"; then
                log_success "  Created: $full_path"
            else
                log_error "  Failed to create: $full_path"
            fi
        else
            log_warning "  Already exists: $full_path"
        fi
    done
}

# Configure mount options in /etc/fstab
configure_fstab_entry() {
    local device=$1
    local mount_point=$2
    local fs_type=$3
    local options=$4
    local dump=$5
    local pass=$6
    
    log_info "Configuring /etc/fstab entry for $mount_point..."
    
    # Backup fstab
    if [[ ! -f /etc/fstab.jts-backup ]]; then
        cp /etc/fstab /etc/fstab.jts-backup
        log_success "Created fstab backup: /etc/fstab.jts-backup"
    fi
    
    # Check if entry already exists
    if grep -q "$mount_point" /etc/fstab; then
        log_warning "Entry for $mount_point already exists in /etc/fstab"
        grep "$mount_point" /etc/fstab
    else
        # Add entry to fstab
        echo "# JTS Database Mount: $(basename $mount_point)" >> /etc/fstab
        echo "$device $mount_point $fs_type $options $dump $pass" >> /etc/fstab
        log_success "Added fstab entry for $mount_point"
    fi
}

# Mount filesystem
mount_filesystem() {
    local device=$1
    local mount_point=$2
    local mount_options=$3
    
    log_info "Mounting $device to $mount_point..."
    
    # Check if already mounted
    if mountpoint -q "$mount_point" 2>/dev/null; then
        log_warning "$mount_point is already mounted"
        return 0
    fi
    
    # Check if device exists
    if [[ ! -b "$device" ]]; then
        log_error "Block device $device does not exist"
        return 1
    fi
    
    # Mount with specified options
    if mount -o "$mount_options" "$device" "$mount_point"; then
        log_success "Mounted $device to $mount_point"
        df -h "$mount_point"
    else
        log_error "Failed to mount $device to $mount_point"
        return 1
    fi
    
    return 0
}

# Main function
main() {
    log_info "=== Database Mount Point Setup Script ==="
    log_info "Starting at $(date)"
    
    # Check prerequisites
    check_root
    
    # Check if LVM volumes exist (optional - warn if not found)
    if ! check_lvm_volumes; then
        log_warning "Continuing without LVM volumes - directories will be created but not mounted"
    fi
    
    # Define mount points and their configurations
    declare -A mount_points=(
        ["/var/lib/postgresql"]="PostgreSQL:postgresql:vg_jts-lv_postgresql"
        ["/var/lib/clickhouse"]="ClickHouse:clickhouse:vg_jts-lv_clickhouse"
        ["/var/lib/kafka"]="Kafka:kafka:vg_jts-lv_kafka"
        ["/var/lib/mongodb"]="MongoDB:mongodb:vg_jts-lv_mongodb"
        ["/var/lib/redis"]="Redis:redis:vg_jts-lv_redis"
        ["/var/lib/docker-jts"]="Docker:docker:vg_jts-lv_docker"
        ["/data/local-backup"]="Backup:backup:vg_jts-lv_backup"
    )
    
    # Create mount point directories
    log_info "=== Creating mount point directories ==="
    for mount_point in "${!mount_points[@]}"; do
        IFS=':' read -r description db_type lvm_volume <<< "${mount_points[$mount_point]}"
        create_mount_directory "$mount_point" "$description"
        
        # Create subdirectories for better organization
        if [[ "$mount_point" != "/data/local-backup" ]]; then
            create_database_subdirs "$mount_point" "$db_type"
        fi
    done
    
    # Configure mount options based on database requirements
    declare -A mount_options=(
        ["/var/lib/postgresql"]="noatime,nodiratime,rw,relatime"
        ["/var/lib/clickhouse"]="noatime,nodiratime,rw,largeio"
        ["/var/lib/kafka"]="noatime,nodiratime,rw,largeio"
        ["/var/lib/mongodb"]="noatime,nodiratime,rw,relatime"
        ["/var/lib/redis"]="noatime,nodiratime,rw,relatime"
        ["/var/lib/docker-jts"]="noatime,nodiratime,rw"
        ["/data/local-backup"]="noatime,nodiratime,rw,noexec"
    )
    
    # Configure /etc/fstab entries (if LVM volumes exist)
    if check_lvm_volumes; then
        log_info "=== Configuring /etc/fstab entries ==="
        for mount_point in "${!mount_points[@]}"; do
            IFS=':' read -r description db_type lvm_volume <<< "${mount_points[$mount_point]}"
            local device="/dev/$lvm_volume"
            local options="${mount_options[$mount_point]}"
            
            # Add fstab entry
            configure_fstab_entry "$device" "$mount_point" "ext4" "$options" "0" "2"
        done
        
        # Mount all configured filesystems
        log_info "=== Mounting filesystems ==="
        for mount_point in "${!mount_points[@]}"; do
            IFS=':' read -r description db_type lvm_volume <<< "${mount_points[$mount_point]}"
            local device="/dev/$lvm_volume"
            local options="${mount_options[$mount_point]}"
            
            mount_filesystem "$device" "$mount_point" "$options"
        done
    fi
    
    # Display summary
    log_info "=== Setup Summary ==="
    log_success "Mount point directories created successfully!"
    
    # Show directory structure
    log_info "Created directory structure:"
    for mount_point in "${!mount_points[@]}"; do
        echo "  $mount_point/"
        if [[ -d "$mount_point" ]]; then
            ls -la "$mount_point" | grep "^d" | tail -n +2 | while read -r line; do
                dir_name=$(echo "$line" | awk '{print $NF}')
                echo "    └── $dir_name/"
            done
        fi
    done
    
    # Show mount status
    if check_lvm_volumes; then
        log_info "Mount status:"
        for mount_point in "${!mount_points[@]}"; do
            if mountpoint -q "$mount_point" 2>/dev/null; then
                echo "  ✓ $mount_point is mounted"
            else
                echo "  ✗ $mount_point is not mounted"
            fi
        done
    fi
    
    # Log to system log
    logger -t "jts-setup" "Database mount points configured successfully"
    
    log_success "Mount point setup complete!"
    exit 0
}

# Run main function
main "$@"