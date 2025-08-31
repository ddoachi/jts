#!/bin/bash
# ============================================================================
# JTS Storage Monitoring Script
# ============================================================================
# Generated from: specs/1000/1001/1013.md
# Context: specs/1000/1001/1013.context.md
# Created: 2025-08-25
# Purpose: Monitor SATA warm storage health and performance
#
# Monitors disk usage and provides detailed reports for JTS warm storage
# infrastructure. Designed for SATA storage tier monitoring.
#
# Usage: 
#   ./jts-storage-monitor.sh [options]
#   
# Options:
#   -h, --help      Show this help message
#   -s, --summary   Show summary only
#   -j, --json      Output in JSON format
#   -w, --warning   Set warning threshold (default: 80%)
#   -c, --critical  Set critical threshold (default: 90%)
#
# Installation: sudo cp jts-storage-monitor.sh /usr/local/bin/
# ============================================================================

set -euo pipefail

# Default configuration
BASE_DIR="/data/jts/hot"
WARNING_THRESHOLD=80
CRITICAL_THRESHOLD=90
OUTPUT_FORMAT="human"
SUMMARY_ONLY=false

# Colors for human-readable output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Function to print usage
usage() {
    echo "JTS Storage Monitoring Script"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -s, --summary   Show summary only"  
    echo "  -j, --json      Output in JSON format"
    echo "  -w, --warning   Set warning threshold percentage (default: 80)"
    echo "  -c, --critical  Set critical threshold percentage (default: 90)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full report in human format"
    echo "  $0 -s                 # Summary only"
    echo "  $0 -j                 # JSON output for monitoring systems"
    echo "  $0 -w 75 -c 85        # Custom thresholds"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -s|--summary)
            SUMMARY_ONLY=true
            shift
            ;;
        -j|--json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        -w|--warning)
            WARNING_THRESHOLD="$2"
            shift 2
            ;;
        -c|--critical)
            CRITICAL_THRESHOLD="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

# Function to get directory size in bytes
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sb "$dir" 2>/dev/null | cut -f1 || echo "0"
    else
        echo "0"
    fi
}

# Function to convert bytes to human readable
bytes_to_human() {
    local bytes=$1
    if [[ $bytes -ge 1099511627776 ]]; then
        echo "$(( bytes / 1099511627776 ))TB"
    elif [[ $bytes -ge 1073741824 ]]; then
        echo "$(( bytes / 1073741824 ))GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(( bytes / 1048576 ))MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(( bytes / 1024 ))KB"
    else
        echo "${bytes}B"
    fi
}

# Function to get filesystem info
get_fs_info() {
    local mount_point
    mount_point=$(df "$BASE_DIR" 2>/dev/null | tail -1 | awk '{print $6}' || echo "/")
    df -B1 "$mount_point" | tail -1
}

# Function to calculate usage percentage
calc_percentage() {
    local used=$1
    local total=$2
    if [[ $total -gt 0 ]]; then
        echo $(( (used * 100) / total ))
    else
        echo "0"
    fi
}

# Function to get status color/level
get_status() {
    local percentage=$1
    if [[ $percentage -ge $CRITICAL_THRESHOLD ]]; then
        echo "CRITICAL"
    elif [[ $percentage -ge $WARNING_THRESHOLD ]]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# Main monitoring function
monitor_storage() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if base directory exists
    if [[ ! -d "$BASE_DIR" ]]; then
        if [[ "$OUTPUT_FORMAT" == "json" ]]; then
            echo "{\"error\": \"Base directory $BASE_DIR does not exist\", \"timestamp\": \"$timestamp\"}"
        else
            echo -e "${RED}❌ Base directory $BASE_DIR does not exist${NC}"
        fi
        exit 1
    fi

    # Get filesystem information
    local fs_info
    fs_info=$(get_fs_info)
    local fs_total fs_used fs_available fs_percentage fs_mount
    fs_total=$(echo "$fs_info" | awk '{print $2}')
    fs_used=$(echo "$fs_info" | awk '{print $3}')
    fs_available=$(echo "$fs_info" | awk '{print $4}')
    fs_percentage=$(echo "$fs_info" | awk '{print $5}' | sed 's/%//')
    fs_mount=$(echo "$fs_info" | awk '{print $6}')

    # Service directories to monitor
    local services=("postgresql" "clickhouse" "kafka" "mongodb" "redis" "docker" "backup")
    local service_data=()
    local total_used=0

    # Collect data for each service
    for service in "${services[@]}"; do
        local service_dir="$BASE_DIR/$service"
        local size_bytes
        size_bytes=$(get_dir_size "$service_dir")
        total_used=$((total_used + size_bytes))
        
        local size_human
        size_human=$(bytes_to_human "$size_bytes")
        
        local percentage
        if [[ $fs_total -gt 0 ]]; then
            percentage=$(calc_percentage "$size_bytes" "$fs_total")
        else
            percentage=0
        fi
        
        local status
        status=$(get_status "$percentage")
        
        service_data+=("$service:$size_bytes:$size_human:$percentage:$status")
    done

    # Output results
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        # JSON output for monitoring systems
        echo "{"
        echo "  \"timestamp\": \"$timestamp\","
        echo "  \"base_directory\": \"$BASE_DIR\","
        echo "  \"filesystem\": {"
        echo "    \"mount_point\": \"$fs_mount\","
        echo "    \"total_bytes\": $fs_total,"
        echo "    \"used_bytes\": $fs_used,"
        echo "    \"available_bytes\": $fs_available,"
        echo "    \"usage_percentage\": $fs_percentage,"
        echo "    \"total_human\": \"$(bytes_to_human "$fs_total")\","
        echo "    \"used_human\": \"$(bytes_to_human "$fs_used")\","
        echo "    \"available_human\": \"$(bytes_to_human "$fs_available")\""
        echo "  },"
        echo "  \"services\": ["
        
        local first=true
        for data in "${service_data[@]}"; do
            IFS=':' read -r service size_bytes size_human percentage status <<< "$data"
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ","
            fi
            echo -n "    {"
            echo -n "\"name\": \"$service\", "
            echo -n "\"size_bytes\": $size_bytes, "
            echo -n "\"size_human\": \"$size_human\", "
            echo -n "\"usage_percentage\": $percentage, "
            echo -n "\"status\": \"$status\""
            echo -n "}"
        done
        echo ""
        echo "  ],"
        echo "  \"thresholds\": {"
        echo "    \"warning\": $WARNING_THRESHOLD,"
        echo "    \"critical\": $CRITICAL_THRESHOLD"
        echo "  }"
        echo "}"
    else
        # Human-readable output
        echo -e "${BOLD}JTS Hot Storage Usage Report - $timestamp${NC}"
        echo "=================================================================="
        
        if [[ "$SUMMARY_ONLY" == "false" ]]; then
            echo -e "${BLUE}📁 Service Directory Usage:${NC}"
            printf "%-12s %10s %8s %8s\n" "Service" "Size" "Usage%" "Status"
            echo "------------------------------------------"
            
            for data in "${service_data[@]}"; do
                IFS=':' read -r service size_bytes size_human percentage status <<< "$data"
                
                local status_color
                case $status in
                    "CRITICAL") status_color="$RED" ;;
                    "WARNING") status_color="$YELLOW" ;;
                    "OK") status_color="$GREEN" ;;
                esac
                
                printf "%-12s %10s %7s%% %s%8s%s\n" \
                    "$service" "$size_human" "$percentage" \
                    "$status_color" "$status" "$NC"
            done
            echo
        else
            # Summary mode - show total hot storage usage
            local hot_total_bytes=0
            local services_with_data=0
            for data in "${service_data[@]}"; do
                IFS=':' read -r service size_bytes size_human percentage status <<< "$data"
                if [[ $size_bytes -gt 0 ]]; then
                    hot_total_bytes=$((hot_total_bytes + size_bytes))
                    services_with_data=$((services_with_data + 1))
                fi
            done
            
            local hot_total_human
            hot_total_human=$(bytes_to_human "$hot_total_bytes")
            local hot_percentage
            if [[ $fs_total -gt 0 ]]; then
                hot_percentage=$(calc_percentage "$hot_total_bytes" "$fs_total")
            else
                hot_percentage=0
            fi
            
            echo -e "${BLUE}📁 Hot Storage Summary:${NC}"
            printf "%-15s %10s\n" "Total Used:" "$hot_total_human"
            printf "%-15s %10s\n" "Services:" "$services_with_data active"
            printf "%-15s %7s%%\n" "Usage:" "$hot_percentage"
            echo
        fi
        
        echo -e "${BLUE}💾 Filesystem Information:${NC}"
        printf "%-15s %10s\n" "Mount Point:" "$fs_mount"
        printf "%-15s %10s\n" "Total Space:" "$(bytes_to_human "$fs_total")"
        printf "%-15s %10s\n" "Used Space:" "$(bytes_to_human "$fs_used")"
        printf "%-15s %10s\n" "Available:" "$(bytes_to_human "$fs_available")"
        
        local fs_status
        fs_status=$(get_status "$fs_percentage")
        local fs_status_color
        case $fs_status in
            "CRITICAL") fs_status_color="$RED" ;;
            "WARNING") fs_status_color="$YELLOW" ;;
            "OK") fs_status_color="$GREEN" ;;
        esac
        
        printf "%-15s %s%7s%% (%s)%s\n" "Usage:" \
            "$fs_status_color" "$fs_percentage" "$fs_status" "$NC"
        
        echo
        echo -e "${BLUE}⚙️  Configuration:${NC}"
        printf "%-15s %s%%\n" "Warning at:" "$WARNING_THRESHOLD"
        printf "%-15s %s%%\n" "Critical at:" "$CRITICAL_THRESHOLD"
        
        if [[ "$fs_status" != "OK" ]]; then
            echo
            echo -e "${YELLOW}⚠️  Recommendations:${NC}"
            if [[ "$fs_status" == "CRITICAL" ]]; then
                echo "• Immediate action required - storage is critically full"
                echo "• Clean up old backups and temporary files"
                echo "• Consider expanding storage capacity"
            else
                echo "• Monitor storage growth closely"
                echo "• Plan for storage expansion if trend continues"
                echo "• Review backup retention policies"
            fi
        fi
    fi
}

# Run monitoring
monitor_storage