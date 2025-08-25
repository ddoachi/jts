#!/bin/bash
#
# JTS SATA Warm Storage Health Check Script
# 
# This script monitors the health and performance of the warm storage SATA drive
# and provides alerts when issues are detected or maintenance is needed.
#
# Usage:
#   ./sata-health-check.sh [--json] [--alert] [--verbose]
#

set -euo pipefail

# Configuration
DEVICE="/dev/sda2"
MOUNT_POINT="/data/warm-storage"
LABEL="jts-warm-storage"
WARNING_THRESHOLD=80  # Disk usage percentage
CRITICAL_THRESHOLD=90 # Disk usage percentage
LOG_FILE="/var/log/sata-health-check.log"

# Command line options
JSON_OUTPUT=false
ALERT_MODE=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Health status
OVERALL_STATUS="HEALTHY"
ISSUES=()
WARNINGS=()

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[INFO]${NC} $message"
    fi
}

warn() {
    local message="$1"
    WARNINGS+=("$message")
    
    echo -e "${YELLOW}[WARN]${NC} $message"
    log "WARNING: $message"
}

error() {
    local message="$1"
    ISSUES+=("$message")
    OVERALL_STATUS="CRITICAL"
    
    echo -e "${RED}[ERROR]${NC} $message"
    log "ERROR: $message"
}

success() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${GREEN}[OK]${NC} $1"
    fi
    log "SUCCESS: $1"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --alert)
                ALERT_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
JTS SATA Warm Storage Health Check

Usage: $0 [OPTIONS]

Options:
    --json      Output results in JSON format
    --alert     Send alerts for issues (requires notification setup)
    --verbose   Show detailed output
    -h, --help  Show this help message

Exit Codes:
    0  All checks passed (HEALTHY)
    1  Warnings detected (DEGRADED)
    2  Critical issues detected (CRITICAL)
EOF
}

# Check if device exists and is accessible
check_device() {
    log "Checking device availability..."
    
    if [[ ! -b "$DEVICE" ]]; then
        error "Device $DEVICE not found"
        return 1
    fi
    
    success "Device $DEVICE is accessible"
    return 0
}

# Check mount status
check_mount() {
    log "Checking mount status..."
    
    if ! mount | grep -q "$DEVICE.*$MOUNT_POINT"; then
        error "Device $DEVICE is not mounted at $MOUNT_POINT"
        return 1
    fi
    
    # Check mount options
    MOUNT_OPTIONS=$(mount | grep "$DEVICE.*$MOUNT_POINT" | sed 's/.*(\(.*\)).*/\1/')
    log "Mount options: $MOUNT_OPTIONS"
    
    # Verify compression is enabled
    if [[ "$MOUNT_OPTIONS" =~ compress ]]; then
        success "Compression is enabled"
    else
        warn "Compression not detected in mount options"
    fi
    
    success "Device is properly mounted"
    return 0
}

# Check disk usage
check_disk_usage() {
    log "Checking disk usage..."
    
    if [[ ! -d "$MOUNT_POINT" ]]; then
        error "Mount point $MOUNT_POINT does not exist"
        return 1
    fi
    
    # Get disk usage percentage
    USAGE=$(df "$MOUNT_POINT" | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [[ "$USAGE" -ge "$CRITICAL_THRESHOLD" ]]; then
        error "Disk usage critical: ${USAGE}% (threshold: ${CRITICAL_THRESHOLD}%)"
    elif [[ "$USAGE" -ge "$WARNING_THRESHOLD" ]]; then
        warn "Disk usage high: ${USAGE}% (threshold: ${WARNING_THRESHOLD}%)"
        if [[ "$OVERALL_STATUS" == "HEALTHY" ]]; then
            OVERALL_STATUS="DEGRADED"
        fi
    else
        success "Disk usage normal: ${USAGE}%"
    fi
    
    # Get detailed space information
    SPACE_INFO=$(df -h "$MOUNT_POINT" | tail -1)
    log "Space info: $SPACE_INFO"
    
    return 0
}

# Check btrfs filesystem health
check_btrfs_health() {
    log "Checking btrfs filesystem health..."
    
    # Check if btrfs tools are available
    if ! command -v btrfs &> /dev/null; then
        warn "btrfs command not available, skipping filesystem health check"
        return 0
    fi
    
    # Check filesystem errors
    if ! btrfs filesystem show "$DEVICE" &> /dev/null; then
        error "Cannot query btrfs filesystem on $DEVICE"
        return 1
    fi
    
    # Get filesystem usage
    FS_USAGE=$(btrfs filesystem usage "$MOUNT_POINT" 2>/dev/null || echo "Unable to get filesystem usage")
    log "Filesystem usage: $FS_USAGE"
    
    # Check for scrub status (if available)
    SCRUB_STATUS=$(btrfs scrub status "$MOUNT_POINT" 2>/dev/null | grep "Status:" || echo "Scrub status unavailable")
    log "Scrub status: $SCRUB_STATUS"
    
    success "Btrfs filesystem appears healthy"
    return 0
}

# Check directory structure
check_directories() {
    log "Checking directory structure..."
    
    REQUIRED_DIRS=(
        "$MOUNT_POINT/daily-backups"
        "$MOUNT_POINT/logs"  
        "$MOUNT_POINT/temp-processing"
        "$MOUNT_POINT/daily-backups/postgresql"
        "$MOUNT_POINT/daily-backups/clickhouse"
        "$MOUNT_POINT/daily-backups/mongodb"
        "$MOUNT_POINT/logs/application"
        "$MOUNT_POINT/logs/system"
        "$MOUNT_POINT/logs/audit"
    )
    
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            warn "Required directory missing: $dir"
        else
            success "Directory exists: $dir"
        fi
    done
    
    return 0
}

# Check system integration
check_system_integration() {
    log "Checking system integration..."
    
    # Check logrotate configuration
    if [[ -f "/etc/logrotate.d/warm-storage" ]]; then
        success "Logrotate configuration exists"
    else
        warn "Logrotate configuration missing"
    fi
    
    # Check cron cleanup job
    if grep -q "/data/warm-storage/temp-processing" /etc/crontab 2>/dev/null; then
        success "Cleanup cron job configured"
    else
        warn "Cleanup cron job missing"
    fi
    
    return 0
}

# Check I/O performance
check_performance() {
    log "Checking I/O performance..."
    
    # Simple write test
    TEST_FILE="$MOUNT_POINT/.health-check-$$"
    
    # Test write speed
    if ! timeout 30s dd if=/dev/zero of="$TEST_FILE" bs=1M count=10 &>/dev/null; then
        error "Write performance test failed"
        rm -f "$TEST_FILE"
        return 1
    fi
    
    # Test read speed
    if ! timeout 30s dd if="$TEST_FILE" of=/dev/null bs=1M &>/dev/null; then
        error "Read performance test failed"
        rm -f "$TEST_FILE"
        return 1
    fi
    
    # Cleanup
    rm -f "$TEST_FILE"
    
    success "I/O performance test passed"
    return 0
}

# Generate JSON output
generate_json() {
    cat << EOF
{
    "timestamp": "$(date -I)",
    "device": "$DEVICE",
    "mount_point": "$MOUNT_POINT",
    "overall_status": "$OVERALL_STATUS",
    "disk_usage_percent": $USAGE,
    "warnings": [$(printf '"%s",' "${WARNINGS[@]}" | sed 's/,$//')],"
    "errors": [$(printf '"%s",' "${ISSUES[@]}" | sed 's/,$//')]
}
EOF
}

# Send alerts if configured
send_alerts() {
    if [[ "$ALERT_MODE" != true ]]; then
        return 0
    fi
    
    # Check if telegram notification is available
    if [[ -x "$HOME/.claude/hooks/telegram-notify.sh" ]]; then
        local message="🔍 SATA Health Check: $OVERALL_STATUS"
        if [[ ${#ISSUES[@]} -gt 0 ]]; then
            message="$message - ${#ISSUES[@]} critical issues detected"
        elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
            message="$message - ${#WARNINGS[@]} warnings detected"  
        fi
        
        "$HOME/.claude/hooks/telegram-notify.sh" "$message" || true
    fi
    
    return 0
}

# Main health check function
run_health_check() {
    log "Starting SATA warm storage health check..."
    
    check_device
    check_mount
    check_disk_usage
    check_btrfs_health
    check_directories
    check_system_integration
    check_performance
    
    log "Health check completed. Status: $OVERALL_STATUS"
    
    # Output results
    if [[ "$JSON_OUTPUT" == true ]]; then
        generate_json
    else
        echo
        echo "=== SATA Warm Storage Health Check Results ==="
        echo "Device: $DEVICE"
        echo "Mount Point: $MOUNT_POINT"
        echo "Overall Status: $OVERALL_STATUS"
        echo "Disk Usage: ${USAGE}%"
        
        if [[ ${#WARNINGS[@]} -gt 0 ]]; then
            echo
            echo "Warnings:"
            for warning in "${WARNINGS[@]}"; do
                echo "  - $warning"
            done
        fi
        
        if [[ ${#ISSUES[@]} -gt 0 ]]; then
            echo
            echo "Critical Issues:"
            for issue in "${ISSUES[@]}"; do
                echo "  - $issue"
            done
        fi
        echo
    fi
    
    send_alerts
    
    # Return appropriate exit code
    case "$OVERALL_STATUS" in
        "HEALTHY")
            return 0
            ;;
        "DEGRADED")
            return 1
            ;;
        "CRITICAL")
            return 2
            ;;
    esac
}

# Main execution
main() {
    parse_args "$@"
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE" 2>/dev/null || true
    
    run_health_check
}

# Execute main function with all arguments
main "$@"