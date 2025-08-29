#!/bin/bash
# Generated from: [Database Mount Integration](../../1012.md)
# Context: [Implementation Context](../../1012.context.md)
# Created: 2025-08-27
# Purpose: Comprehensive validation of database mount integration setup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Validation counters
PASSED=0
FAILED=0
WARNINGS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
    ((PASSED++))
}

log_error() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
    ((FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
    ((WARNINGS++))
}

log_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_warning "Not running as root - some checks will be limited"
        return 1
    fi
    return 0
}

# Validate service user exists and has correct properties
validate_user() {
    local username=$1
    local expected_home=$2
    local test_name="User $username"
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        log_error "$test_name: User does not exist"
        return 1
    fi
    
    # Get user properties
    local uid=$(id -u "$username")
    local shell=$(getent passwd "$username" | cut -d: -f7)
    local home=$(getent passwd "$username" | cut -d: -f6)
    
    # Validate system user (UID < 1000)
    if [[ $uid -lt 1000 ]]; then
        log_success "$test_name: Is system user (UID: $uid)"
    else
        log_warning "$test_name: Not a system user (UID: $uid)"
    fi
    
    # Validate nologin shell
    if [[ "$shell" == "/bin/false" ]] || [[ "$shell" == "/usr/sbin/nologin" ]]; then
        log_success "$test_name: Has nologin shell ($shell)"
    else
        log_error "$test_name: Incorrect shell ($shell)"
    fi
    
    # Validate home directory
    if [[ "$home" == "$expected_home" ]]; then
        log_success "$test_name: Home directory correct ($home)"
    else
        log_warning "$test_name: Unexpected home directory ($home, expected $expected_home)"
    fi
    
    # Check if account is locked
    if [[ $EUID -eq 0 ]]; then
        if passwd -S "$username" 2>/dev/null | grep -q "L"; then
            log_success "$test_name: Account is locked"
        else
            log_warning "$test_name: Account is not locked"
        fi
    fi
    
    return 0
}

# Validate group exists
validate_group() {
    local groupname=$1
    local test_name="Group $groupname"
    
    if getent group "$groupname" &>/dev/null; then
        local gid=$(getent group "$groupname" | cut -d: -f3)
        log_success "$test_name: Exists (GID: $gid)"
        return 0
    else
        log_error "$test_name: Does not exist"
        return 1
    fi
}

# Validate mount point directory
validate_mount_directory() {
    local mount_point=$1
    local expected_owner=$2
    local expected_group=$3
    local expected_perms=$4
    local test_name="Mount point $mount_point"
    
    # Check if directory exists
    if [[ ! -d "$mount_point" ]]; then
        log_error "$test_name: Directory does not exist"
        return 1
    fi
    
    log_success "$test_name: Directory exists"
    
    # Check ownership
    local actual_owner=$(stat -c '%U' "$mount_point")
    local actual_group=$(stat -c '%G' "$mount_point")
    
    if [[ "$actual_owner" == "$expected_owner" ]] && [[ "$actual_group" == "$expected_group" ]]; then
        log_success "$test_name: Ownership correct ($actual_owner:$actual_group)"
    else
        log_error "$test_name: Incorrect ownership (expected $expected_owner:$expected_group, got $actual_owner:$actual_group)"
    fi
    
    # Check permissions
    local actual_perms=$(stat -c '%a' "$mount_point")
    if [[ "$actual_perms" == "$expected_perms" ]]; then
        log_success "$test_name: Permissions correct ($actual_perms)"
    else
        log_error "$test_name: Incorrect permissions (expected $expected_perms, got $actual_perms)"
    fi
    
    return 0
}

# Validate mount status
validate_mount_status() {
    local mount_point=$1
    local test_name="Mount status $mount_point"
    
    if mountpoint -q "$mount_point" 2>/dev/null; then
        log_success "$test_name: Is a mount point"
        
        # Get mount details
        local fs_info=$(df -hT "$mount_point" | tail -1)
        local fs_type=$(echo "$fs_info" | awk '{print $2}')
        local size=$(echo "$fs_info" | awk '{print $3}')
        local used=$(echo "$fs_info" | awk '{print $4}')
        local avail=$(echo "$fs_info" | awk '{print $5}')
        local use_percent=$(echo "$fs_info" | awk '{print $6}')
        
        log_info "  Filesystem: $fs_type, Size: $size, Used: $used, Available: $avail, Use: $use_percent"
        
        # Check mount options
        if [[ $EUID -eq 0 ]]; then
            local mount_opts=$(mount | grep " $mount_point " | sed 's/.*(\(.*\))/\1/')
            log_info "  Mount options: $mount_opts"
            
            # Validate important mount options
            if echo "$mount_opts" | grep -q "noatime"; then
                log_success "$test_name: Has noatime option"
            else
                log_warning "$test_name: Missing noatime option"
            fi
        fi
    else
        log_warning "$test_name: Not mounted (directory exists but not a mount point)"
    fi
    
    return 0
}

# Validate write access for service user
validate_write_access() {
    local user=$1
    local path=$2
    local test_name="Write access for $user to $path"
    
    if [[ ! -d "$path" ]]; then
        log_warning "$test_name: Directory does not exist"
        return 1
    fi
    
    if [[ $EUID -ne 0 ]]; then
        log_warning "$test_name: Cannot test (not root)"
        return 0
    fi
    
    local test_file="$path/.write_test_$$"
    
    if sudo -u "$user" touch "$test_file" 2>/dev/null; then
        sudo -u "$user" rm "$test_file" 2>/dev/null
        log_success "$test_name: Write access confirmed"
    else
        log_error "$test_name: Cannot write to directory"
    fi
    
    return 0
}

# Validate service isolation
validate_isolation() {
    local user1=$1
    local path1=$2
    local user2=$3
    local path2=$4
    local test_name="Isolation between $user1 and $user2"
    
    if [[ $EUID -ne 0 ]]; then
        log_warning "$test_name: Cannot test (not root)"
        return 0
    fi
    
    # Test that user1 cannot access user2's directory
    if sudo -u "$user1" test -r "$path2" 2>/dev/null; then
        log_error "$test_name: $user1 can read $path2"
    else
        log_success "$test_name: $user1 cannot access $path2"
    fi
    
    return 0
}

# Validate subdirectory structure
validate_subdirectories() {
    local base_dir=$1
    local expected_subdirs=$2
    local test_name="Subdirectories for $base_dir"
    
    IFS=',' read -ra subdirs <<< "$expected_subdirs"
    local missing=()
    
    for subdir in "${subdirs[@]}"; do
        if [[ -d "$base_dir/$subdir" ]]; then
            log_success "$test_name/$subdir: Exists"
        else
            log_warning "$test_name/$subdir: Missing"
            missing+=("$subdir")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "  Missing subdirectories can be created with setup-mount-points.sh"
    fi
    
    return 0
}

# Validate fstab entries
validate_fstab() {
    local mount_point=$1
    local test_name="fstab entry for $mount_point"
    
    if grep -q "$mount_point" /etc/fstab; then
        log_success "$test_name: Entry exists"
        local entry=$(grep "$mount_point" /etc/fstab | grep -v "^#")
        if [[ -n "$entry" ]]; then
            log_info "  Entry: $entry"
        fi
    else
        log_warning "$test_name: No entry found"
    fi
    
    return 0
}

# Validate ACLs if available
validate_acls() {
    local path=$1
    local expected_group=$2
    local test_name="ACLs for $path"
    
    if ! command -v getfacl &>/dev/null; then
        log_warning "$test_name: ACL tools not installed"
        return 0
    fi
    
    if [[ ! -d "$path" ]]; then
        return 0
    fi
    
    local acls=$(getfacl -p "$path" 2>/dev/null | grep "group:$expected_group")
    if [[ -n "$acls" ]]; then
        log_success "$test_name: Group $expected_group has ACL access"
        log_info "  ACL: $acls"
    else
        log_warning "$test_name: No ACL for group $expected_group"
    fi
    
    return 0
}

# Generate validation report
generate_report() {
    local total=$((PASSED + FAILED + WARNINGS))
    local pass_rate=0
    if [[ $total -gt 0 ]]; then
        pass_rate=$((PASSED * 100 / total))
    fi
    
    log_section "VALIDATION SUMMARY"
    
    echo ""
    echo "┌─────────────────────────────────────┐"
    echo "│         VALIDATION RESULTS          │"
    echo "├─────────────────────────────────────┤"
    echo -e "│ ${GREEN}✓ Passed:${NC}    $(printf "%3d" $PASSED) tests              │"
    echo -e "│ ${RED}✗ Failed:${NC}    $(printf "%3d" $FAILED) tests              │"
    echo -e "│ ${YELLOW}⚠ Warnings:${NC}  $(printf "%3d" $WARNINGS) tests              │"
    echo "├─────────────────────────────────────┤"
    echo "│ Total:      $(printf "%3d" $total) tests              │"
    echo "│ Pass Rate:  $(printf "%3d" $pass_rate)%                 │"
    echo "└─────────────────────────────────────┘"
    
    echo ""
    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}✅ All critical checks passed!${NC}"
        echo "Database mount integration is properly configured."
    else
        echo -e "${RED}❌ Some critical checks failed!${NC}"
        echo "Please review the errors above and run the setup scripts:"
        echo "  1. ./setup-database-users.sh"
        echo "  2. ./setup-mount-points.sh"
        echo "  3. ./configure-permissions.sh"
    fi
    
    if [[ $WARNINGS -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}⚠ Warnings detected:${NC}"
        echo "Some non-critical issues were found. Review warnings above."
    fi
}

# Main validation function
main() {
    log_info "=== Database Mount Integration Validation ==="
    log_info "Starting at $(date)"
    echo ""
    
    local is_root=false
    if check_root; then
        is_root=true
        log_info "Running as root - full validation enabled"
    else
        log_info "Running as non-root - limited validation"
    fi
    
    # Define expected configurations
    declare -A user_configs=(
        ["postgres"]="/var/lib/postgresql"
        ["clickhouse"]="/var/lib/clickhouse"
        ["kafka"]="/var/lib/kafka"
        ["mongodb"]="/var/lib/mongodb"
        ["redis"]="/var/lib/redis"
    )
    
    declare -A mount_configs=(
        ["/var/lib/postgresql"]="postgres:postgres:750"
        ["/var/lib/clickhouse"]="clickhouse:clickhouse:750"
        ["/var/lib/kafka"]="kafka:kafka:750"
        ["/var/lib/mongodb"]="mongodb:mongodb:750"
        ["/var/lib/redis"]="redis:redis:750"
        ["/var/lib/docker-jts"]="root:docker:750"
        ["/data/local-backup"]="root:backup:755"
    )
    
    declare -A subdirs_config=(
        ["/var/lib/postgresql"]="data,logs,config,backups,wal"
        ["/var/lib/clickhouse"]="data,logs,config,tmp,user_files"
        ["/var/lib/kafka"]="data,logs,config,scripts"
        ["/var/lib/mongodb"]="data,logs,config,journal"
        ["/var/lib/redis"]="data,logs,config"
        ["/var/lib/docker-jts"]="volumes,images,containers,tmp"
    )
    
    # Validate service users
    log_section "SERVICE USER VALIDATION"
    for username in "${!user_configs[@]}"; do
        validate_user "$username" "${user_configs[$username]}"
    done
    
    # Validate operational groups
    log_section "OPERATIONAL GROUP VALIDATION"
    for group in docker backup db-backup db-monitor db-admin; do
        validate_group "$group"
    done
    
    # Validate mount directories
    log_section "MOUNT DIRECTORY VALIDATION"
    for mount_point in "${!mount_configs[@]}"; do
        IFS=':' read -r owner group perms <<< "${mount_configs[$mount_point]}"
        validate_mount_directory "$mount_point" "$owner" "$group" "$perms"
    done
    
    # Validate subdirectory structure
    log_section "SUBDIRECTORY STRUCTURE VALIDATION"
    for mount_point in "${!subdirs_config[@]}"; do
        if [[ -d "$mount_point" ]]; then
            validate_subdirectories "$mount_point" "${subdirs_config[$mount_point]}"
        fi
    done
    
    # Validate mount status
    log_section "MOUNT STATUS VALIDATION"
    for mount_point in "${!mount_configs[@]}"; do
        if [[ -d "$mount_point" ]]; then
            validate_mount_status "$mount_point"
        fi
    done
    
    # Validate fstab entries
    log_section "FSTAB CONFIGURATION VALIDATION"
    for mount_point in "${!mount_configs[@]}"; do
        validate_fstab "$mount_point"
    done
    
    # Validate write access (only if root)
    if [[ $is_root == true ]]; then
        log_section "WRITE ACCESS VALIDATION"
        for username in "${!user_configs[@]}"; do
            validate_write_access "$username" "${user_configs[$username]}"
        done
    fi
    
    # Validate service isolation (only if root)
    if [[ $is_root == true ]]; then
        log_section "SERVICE ISOLATION VALIDATION"
        validate_isolation "postgres" "/var/lib/postgresql" "clickhouse" "/var/lib/clickhouse"
        validate_isolation "clickhouse" "/var/lib/clickhouse" "kafka" "/var/lib/kafka"
        validate_isolation "kafka" "/var/lib/kafka" "mongodb" "/var/lib/mongodb"
        validate_isolation "mongodb" "/var/lib/mongodb" "redis" "/var/lib/redis"
    fi
    
    # Validate ACLs
    log_section "ACL VALIDATION"
    for mount_point in /var/lib/postgresql /var/lib/clickhouse /var/lib/kafka /var/lib/mongodb /var/lib/redis; do
        validate_acls "$mount_point" "db-backup"
        validate_acls "$mount_point" "db-monitor"
    done
    
    # Generate summary report
    generate_report
    
    # Exit with appropriate code
    if [[ $FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"