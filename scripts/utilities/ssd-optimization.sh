#!/bin/bash
# From: E01-F01-T05 Storage Performance Optimization
# Purpose: Monitor and verify SSD optimization settings for JTS trading system
#
# JTS SSD Optimization Status Monitor
# ===================================
#
# This script monitors the status of all SSD performance optimizations
# and provides actionable insights for maintaining optimal trading system performance
#
# Usage: ./ssd-optimization.sh [--check|--fix|--report]

set -euo pipefail

# Colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MODE="check"  # Default mode

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            MODE="check"
            shift
            ;;
        --fix)
            MODE="fix"
            shift
            ;;
        --report)
            MODE="report"
            shift
            ;;
        *)
            echo "Usage: $0 [--check|--fix|--report]"
            echo "  --check: Check optimization status (default)"
            echo "  --fix:   Attempt to fix optimization issues"
            echo "  --report: Generate detailed report"
            exit 1
            ;;
    esac
done

echo -e "${YELLOW}⚙️  JTS SSD Optimization Status Monitor${NC}"
echo "========================================="
echo "Mode: $MODE"
echo "Timestamp: $(date)"
echo ""

# Function to check I/O scheduler status
check_io_scheduler() {
    echo -e "${BLUE}📊 I/O Scheduler Status:${NC}"
    echo "------------------------"
    
    local issues_found=0
    
    for device in /sys/block/nvme*n*; do
        if [ -d "$device" ]; then
            local device_name=$(basename "$device")
            local scheduler_file="$device/queue/scheduler"
            
            if [ -r "$scheduler_file" ]; then
                local current_scheduler=$(cat "$scheduler_file")
                echo "Device: $device_name"
                echo "  Current: $current_scheduler"
                
                # Check if 'none' scheduler is active
                if [[ "$current_scheduler" == *"[none]"* ]]; then
                    echo -e "  Status: ${GREEN}✅ Optimized (none scheduler active)${NC}"
                else
                    echo -e "  Status: ${RED}❌ Not optimized${NC}"
                    echo -e "  Action: ${YELLOW}Set scheduler to 'none' for optimal NVMe performance${NC}"
                    issues_found=1
                    
                    if [ "$MODE" = "fix" ]; then
                        echo "  Fixing: Setting scheduler to 'none'..."
                        echo "none" > "$scheduler_file" 2>/dev/null || echo -e "    ${RED}Failed to set scheduler (permission denied)${NC}"
                    fi
                fi
            else
                echo -e "$device_name: ${YELLOW}⚠️  Scheduler file not readable${NC}"
            fi
            echo ""
        fi
    done
    
    if [ $issues_found -eq 0 ]; then
        echo -e "${GREEN}✅ All NVMe devices using optimal I/O scheduler${NC}"
    fi
    
    return $issues_found
}

# Function to check TRIM support status
check_trim_support() {
    echo -e "${BLUE}✂️  TRIM Support Status:${NC}"
    echo "----------------------"
    
    local trim_issues=0
    
    # Check if TRIM/discard is supported by devices
    for device in /dev/nvme*n*; do
        if [ -b "$device" ]; then
            local device_name=$(basename "$device")
            echo "Device: $device_name"
            
            # Check TRIM support using lsblk
            if command -v lsblk >/dev/null 2>&1; then
                local discard_info=$(lsblk -D "$device" 2>/dev/null | tail -1)
                if [ -n "$discard_info" ]; then
                    echo "  TRIM Support: $discard_info"
                    # Check if DISC-MAX is greater than 0 (TRIM supported)
                    local disc_max=$(echo "$discard_info" | awk '{print $4}')
                    if [ "$disc_max" != "0B" ] && [ -n "$disc_max" ]; then
                        echo -e "  Status: ${GREEN}✅ TRIM supported${NC}"
                    else
                        echo -e "  Status: ${YELLOW}⚠️  TRIM may not be supported${NC}"
                        trim_issues=1
                    fi
                else
                    echo -e "  Status: ${YELLOW}⚠️  Unable to determine TRIM support${NC}"
                fi
            else
                echo -e "  Status: ${YELLOW}⚠️  lsblk not available for TRIM check${NC}"
            fi
            echo ""
        fi
    done
    
    return $trim_issues
}

# Function to check systemd timer status
check_systemd_timers() {
    echo -e "${BLUE}⏰ Automated Maintenance Status:${NC}"
    echo "-------------------------------"
    
    local timer_issues=0
    local timer_name="fstrim-all.timer"
    
    # Check if timer exists and is enabled
    if systemctl list-unit-files "$timer_name" >/dev/null 2>&1; then
        local timer_status=$(systemctl is-enabled "$timer_name" 2>/dev/null || echo "disabled")
        local timer_active=$(systemctl is-active "$timer_name" 2>/dev/null || echo "inactive")
        
        echo "Timer: $timer_name"
        echo "  Enabled: $timer_status"
        echo "  Active: $timer_active"
        
        if [ "$timer_status" = "enabled" ] && [ "$timer_active" = "active" ]; then
            echo -e "  Status: ${GREEN}✅ Timer properly configured${NC}"
            
            # Show next execution time
            local next_run=$(systemctl list-timers "$timer_name" --no-pager 2>/dev/null | grep "$timer_name" | awk '{print $1, $2, $3, $4}' | head -1)
            if [ -n "$next_run" ]; then
                echo "  Next run: $next_run"
            fi
        else
            echo -e "  Status: ${RED}❌ Timer not properly configured${NC}"
            timer_issues=1
            
            if [ "$MODE" = "fix" ]; then
                echo "  Fixing: Enabling and starting timer..."
                systemctl enable "$timer_name" 2>/dev/null || echo -e "    ${RED}Failed to enable timer${NC}"
                systemctl start "$timer_name" 2>/dev/null || echo -e "    ${RED}Failed to start timer${NC}"
            fi
        fi
    else
        echo -e "Timer: ${RED}❌ $timer_name not found${NC}"
        echo -e "Action: ${YELLOW}Install systemd timer files${NC}"
        timer_issues=1
    fi
    echo ""
    
    return $timer_issues
}

# Function to check filesystem mount optimizations
check_mount_optimizations() {
    echo -e "${BLUE}🗂️  Filesystem Mount Optimizations:${NC}"
    echo "----------------------------------"
    
    local mount_issues=0
    local hot_storage_mounts=("/var/lib/postgresql" "/var/lib/clickhouse" "/var/lib/kafka")
    
    for mount_point in "${hot_storage_mounts[@]}"; do
        if mountpoint -q "$mount_point" 2>/dev/null; then
            echo "Mount: $mount_point"
            
            # Get mount options
            local mount_opts=$(mount | grep "$mount_point" | cut -d'(' -f2 | cut -d')' -f1)
            echo "  Options: $mount_opts"
            
            # Check for performance-critical options
            local has_noatime=false
            local has_discard=false
            
            if [[ "$mount_opts" == *"noatime"* ]]; then
                has_noatime=true
            fi
            
            if [[ "$mount_opts" == *"discard"* ]]; then
                has_discard=true
            fi
            
            if [ "$has_noatime" = true ] && [ "$has_discard" = true ]; then
                echo -e "  Status: ${GREEN}✅ Optimally configured${NC}"
            else
                echo -e "  Status: ${YELLOW}⚠️  Could be optimized further${NC}"
                [ "$has_noatime" = false ] && echo -e "    Missing: ${YELLOW}noatime${NC} (reduces metadata updates)"
                [ "$has_discard" = false ] && echo -e "    Missing: ${YELLOW}discard${NC} (automatic TRIM)"
                mount_issues=1
            fi
        else
            echo -e "Mount: ${YELLOW}⚠️  $mount_point not mounted${NC}"
        fi
        echo ""
    done
    
    return $mount_issues
}

# Function to generate performance report
generate_report() {
    echo -e "${BLUE}📈 Performance Health Summary:${NC}"
    echo "=============================="
    
    local total_issues=0
    
    # Run all checks and count issues
    check_io_scheduler; ((total_issues += $?))
    check_trim_support; ((total_issues += $?))  
    check_systemd_timers; ((total_issues += $?))
    check_mount_optimizations; ((total_issues += $?))
    
    # Overall health assessment
    echo -e "${BLUE}🎯 Overall System Health:${NC}"
    echo "========================"
    
    if [ $total_issues -eq 0 ]; then
        echo -e "${GREEN}✅ EXCELLENT: All optimizations properly configured${NC}"
        echo -e "   Trading system performance should be optimal"
        echo -e "   Recommendation: Continue regular monitoring"
    elif [ $total_issues -le 2 ]; then
        echo -e "${YELLOW}⚠️  GOOD: Minor optimization opportunities${NC}"
        echo -e "   Trading system performance likely acceptable"  
        echo -e "   Recommendation: Address minor issues when convenient"
    else
        echo -e "${RED}❌ NEEDS ATTENTION: Multiple optimization issues${NC}"
        echo -e "   Trading system performance may be impacted"
        echo -e "   Recommendation: Address issues promptly"
    fi
    
    echo ""
    echo "Issues found: $total_issues"
    echo "Run with --fix to attempt automatic fixes"
    
    return $total_issues
}

# Main execution logic
case $MODE in
    "check")
        generate_report
        exit_code=$?
        ;;
    "fix")
        echo -e "${YELLOW}🔧 Attempting to fix optimization issues...${NC}"
        echo ""
        generate_report
        exit_code=$?
        ;;
    "report")
        generate_report
        exit_code=$?
        
        # Additional reporting information
        echo ""
        echo -e "${BLUE}📋 Detailed System Information:${NC}"
        echo "==============================="
        echo "Hostname: $(hostname)"
        echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
        echo "Load: $(cat /proc/loadavg)"
        
        if command -v iostat >/dev/null 2>&1; then
            echo ""
            echo "Current I/O Statistics:"
            iostat -x 1 1 2>/dev/null | grep -E "(Device|nvme)" || echo "No NVMe devices found in iostat"
        fi
        ;;
esac

# Exit with appropriate code for monitoring integration
exit $exit_code