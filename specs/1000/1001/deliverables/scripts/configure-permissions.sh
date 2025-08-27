#!/bin/bash
# Generated from: [Database Mount Integration](../../1012.md)
# Context: [Implementation Context](../../1012.context.md)
# Created: 2025-08-27
# Purpose: Configure ownership, permissions, and ACLs for database mount points

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

# Check if required users and groups exist
check_users_groups() {
    log_info "Checking for required users and groups..."
    
    # Check database users
    local required_users=("postgres" "clickhouse" "kafka" "mongodb" "redis")
    local missing_users=()
    
    for user in "${required_users[@]}"; do
        if ! id "$user" &>/dev/null; then
            log_warning "User $user does not exist"
            missing_users+=("$user")
        else
            log_success "Found user: $user"
        fi
    done
    
    # Check operational groups
    local required_groups=("docker" "backup" "db-backup" "db-monitor" "db-admin")
    local missing_groups=()
    
    for group in "${required_groups[@]}"; do
        if ! getent group "$group" &>/dev/null; then
            log_warning "Group $group does not exist"
            missing_groups+=("$group")
        else
            log_success "Found group: $group"
        fi
    done
    
    if [[ ${#missing_users[@]} -gt 0 ]] || [[ ${#missing_groups[@]} -gt 0 ]]; then
        log_error "Missing users or groups. Please run setup-database-users.sh first"
        return 1
    fi
    
    return 0
}

# Set ownership for a directory
set_ownership() {
    local path=$1
    local owner=$2
    local group=$3
    local recursive=${4:-true}
    
    log_info "Setting ownership for $path to $owner:$group"
    
    if [[ ! -e "$path" ]]; then
        log_error "Path does not exist: $path"
        return 1
    fi
    
    if [[ "$recursive" == "true" ]]; then
        if chown -R "$owner:$group" "$path"; then
            log_success "Set ownership recursively: $path -> $owner:$group"
        else
            log_error "Failed to set ownership for $path"
            return 1
        fi
    else
        if chown "$owner:$group" "$path"; then
            log_success "Set ownership: $path -> $owner:$group"
        else
            log_error "Failed to set ownership for $path"
            return 1
        fi
    fi
    
    return 0
}

# Set permissions for a directory
set_permissions() {
    local path=$1
    local perms=$2
    local recursive=${3:-false}
    
    log_info "Setting permissions for $path to $perms"
    
    if [[ ! -e "$path" ]]; then
        log_error "Path does not exist: $path"
        return 1
    fi
    
    if [[ "$recursive" == "true" ]]; then
        # Set directory permissions
        find "$path" -type d -exec chmod "$perms" {} \; 2>/dev/null || true
        # Set file permissions (less restrictive)
        local file_perms=$((perms - 111))  # Remove execute from directories
        find "$path" -type f -exec chmod "$file_perms" {} \; 2>/dev/null || true
        log_success "Set permissions recursively: $path -> dirs:$perms, files:$file_perms"
    else
        if chmod "$perms" "$path"; then
            log_success "Set permissions: $path -> $perms"
        else
            log_error "Failed to set permissions for $path"
            return 1
        fi
    fi
    
    return 0
}

# Configure ACLs for operational access
configure_acls() {
    local path=$1
    local acl_rules=$2
    
    log_info "Configuring ACLs for $path"
    
    # Check if ACL support is available
    if ! command -v setfacl &>/dev/null; then
        log_warning "setfacl not found. Installing acl package..."
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y acl
        elif command -v yum &>/dev/null; then
            yum install -y acl
        else
            log_error "Cannot install acl package. Please install manually."
            return 1
        fi
    fi
    
    # Apply ACL rules
    IFS=';' read -ra rules <<< "$acl_rules"
    for rule in "${rules[@]}"; do
        if [[ -n "$rule" ]]; then
            if setfacl -m "$rule" "$path"; then
                log_success "Applied ACL: $rule on $path"
            else
                log_error "Failed to apply ACL: $rule on $path"
            fi
        fi
    done
    
    # Set default ACLs for new files/directories
    if setfacl -d -m "$acl_rules" "$path" 2>/dev/null; then
        log_success "Set default ACLs for $path"
    fi
    
    return 0
}

# Configure permissions for a database mount point
configure_database_mount() {
    local mount_point=$1
    local owner=$2
    local group=$3
    local perms=$4
    local acls=$5
    
    log_info "=== Configuring $mount_point ==="
    
    # Set ownership
    set_ownership "$mount_point" "$owner" "$group" true
    
    # Set base permissions
    set_permissions "$mount_point" "$perms" false
    
    # Configure subdirectory permissions if they exist
    if [[ -d "$mount_point/data" ]]; then
        set_permissions "$mount_point/data" "700" false
        log_info "  Secured data directory with 700 permissions"
    fi
    
    if [[ -d "$mount_point/logs" ]]; then
        set_permissions "$mount_point/logs" "750" false
        log_info "  Set logs directory to 750 for monitoring access"
    fi
    
    if [[ -d "$mount_point/config" ]]; then
        set_permissions "$mount_point/config" "755" false
        log_info "  Set config directory to 755 for read access"
    fi
    
    if [[ -d "$mount_point/backups" ]]; then
        set_permissions "$mount_point/backups" "750" false
        configure_acls "$mount_point/backups" "g:backup:rx"
        log_info "  Configured backup directory with backup group access"
    fi
    
    # Apply operational ACLs
    if [[ -n "$acls" ]]; then
        configure_acls "$mount_point" "$acls"
    fi
}

# Test write access for a user
test_write_access() {
    local user=$1
    local path=$2
    
    log_info "Testing write access for $user to $path"
    
    local test_file="$path/.write_test_$(date +%s)"
    
    if sudo -u "$user" touch "$test_file" 2>/dev/null; then
        sudo -u "$user" rm "$test_file" 2>/dev/null
        log_success "$user can write to $path"
        return 0
    else
        log_error "$user cannot write to $path"
        return 1
    fi
}

# Verify isolation between services
verify_isolation() {
    log_info "=== Verifying service isolation ==="
    
    local services=("postgres" "clickhouse" "kafka" "mongodb" "redis")
    local mount_points=("/var/lib/postgresql" "/var/lib/clickhouse" "/var/lib/kafka" "/var/lib/mongodb" "/var/lib/redis")
    
    for i in "${!services[@]}"; do
        local service="${services[$i]}"
        local own_mount="${mount_points[$i]}"
        
        # Test that service can write to its own mount
        if [[ -d "$own_mount" ]]; then
            test_write_access "$service" "$own_mount"
        fi
        
        # Test that service cannot write to other mounts
        for j in "${!mount_points[@]}"; do
            if [[ $i -ne $j ]]; then
                local other_mount="${mount_points[$j]}"
                if [[ -d "$other_mount" ]]; then
                    if sudo -u "$service" test -w "$other_mount" 2>/dev/null; then
                        log_error "SECURITY ISSUE: $service can write to $other_mount"
                    else
                        log_success "$service cannot write to $other_mount (correct)"
                    fi
                fi
            fi
        done
    done
}

# Main function
main() {
    log_info "=== Database Permissions Configuration Script ==="
    log_info "Starting at $(date)"
    
    # Check prerequisites
    check_root
    
    if ! check_users_groups; then
        log_error "Prerequisites not met. Exiting."
        exit 1
    fi
    
    # Define mount points and their permission configurations
    declare -A mount_configs=(
        ["/var/lib/postgresql"]="postgres:postgres:750:g:db-backup:rx;g:db-monitor:rx"
        ["/var/lib/clickhouse"]="clickhouse:clickhouse:750:g:db-backup:rx;g:db-monitor:rx"
        ["/var/lib/kafka"]="kafka:kafka:750:g:db-backup:rx;g:db-monitor:rx"
        ["/var/lib/mongodb"]="mongodb:mongodb:750:g:db-backup:rx;g:db-monitor:rx"
        ["/var/lib/redis"]="redis:redis:750:g:db-backup:rx;g:db-monitor:rx"
        ["/var/lib/docker-jts"]="root:docker:750:g:docker:rwx"
        ["/data/local-backup"]="root:backup:755:g:backup:rwx;g:db-admin:rx"
    )
    
    # Configure each mount point
    log_info "=== Configuring mount point permissions ==="
    for mount_point in "${!mount_configs[@]}"; do
        if [[ -d "$mount_point" ]]; then
            IFS=':' read -r owner group perms acls <<< "${mount_configs[$mount_point]}"
            configure_database_mount "$mount_point" "$owner" "$group" "$perms" "$acls"
        else
            log_warning "Mount point $mount_point does not exist, skipping"
        fi
    done
    
    # Verify isolation between services
    verify_isolation
    
    # Display permission summary
    log_info "=== Permission Summary ==="
    for mount_point in "${!mount_configs[@]}"; do
        if [[ -d "$mount_point" ]]; then
            echo ""
            echo "Mount Point: $mount_point"
            ls -ld "$mount_point"
            
            # Show ACLs if configured
            if command -v getfacl &>/dev/null; then
                echo "ACLs:"
                getfacl -p "$mount_point" 2>/dev/null | grep -E "^(user:|group:|mask:|other:)" | sed 's/^/  /'
            fi
        fi
    done
    
    # Test operational group access
    log_info "=== Testing operational group access ==="
    
    # Test backup group access
    if getent group db-backup &>/dev/null; then
        for dir in /var/lib/postgresql /var/lib/clickhouse /var/lib/kafka /var/lib/mongodb /var/lib/redis; do
            if [[ -d "$dir" ]]; then
                if sudo -u nobody -g db-backup test -r "$dir" 2>/dev/null; then
                    log_success "db-backup group can read $dir"
                else
                    log_warning "db-backup group cannot read $dir"
                fi
            fi
        done
    fi
    
    # Log to system log
    logger -t "jts-setup" "Database permissions configured successfully"
    
    log_success "Permissions configuration complete!"
    log_info "Note: Database services should now be able to use their designated storage"
    exit 0
}

# Run main function
main "$@"