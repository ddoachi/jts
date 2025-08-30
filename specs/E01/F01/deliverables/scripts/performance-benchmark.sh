#!/bin/bash
# From: E01-F01-T05 Storage Performance Optimization
# Purpose: Comprehensive storage performance benchmarking for JTS trading system
#
# JTS Storage Performance Benchmarking
# ===================================
#
# This script provides comprehensive I/O performance testing across all storage tiers
# to validate optimization effectiveness and establish performance baselines
#
# Storage Tiers Tested:
# - Hot Storage (NVMe): Maximum IOPS for real-time trading data
# - Warm Storage (SATA): Sequential I/O for backups and logs  
# - Cold Storage (NAS): Network-optimized bulk transfers
#
# Usage: ./performance-benchmark.sh [--quick|--full]

set -euo pipefail

# Colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Performance test configuration
QUICK_MODE=false
TEST_SIZE="1024"  # MB for full test
QUICK_SIZE="256"  # MB for quick test

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --full)
            QUICK_MODE=false
            shift
            ;;
        *)
            echo "Usage: $0 [--quick|--full]"
            exit 1
            ;;
    esac
done

# Set test size based on mode
if [ "$QUICK_MODE" = true ]; then
    TEST_SIZE=$QUICK_SIZE
    echo -e "${YELLOW}🚀 JTS Storage Performance Benchmarking (Quick Mode)${NC}"
else
    echo -e "${YELLOW}🚀 JTS Storage Performance Benchmarking (Full Mode)${NC}"
fi

echo "======================================="
echo "Test size: ${TEST_SIZE}MB"
echo "Timestamp: $(date)"
echo ""

# Function to test sequential performance
test_sequential_performance() {
    local mount_point=$1
    local tier_name=$2
    
    echo -e "${BLUE}Testing $tier_name sequential I/O on $mount_point${NC}"
    
    # Check if mount point is writable
    if [ ! -w "$mount_point" ]; then
        echo -e "  ${RED}❌ Mount point not writable, skipping${NC}"
        return
    fi
    
    # Sequential write test
    echo "  📝 Sequential Write:"
    local write_result
    write_result=$(dd if=/dev/zero of="$mount_point/seq_write_test" bs=1M count="$TEST_SIZE" oflag=direct 2>&1 | tail -1)
    echo "    $write_result"
    
    # Sequential read test
    echo "  📖 Sequential Read:"
    local read_result
    read_result=$(dd if="$mount_point/seq_write_test" of=/dev/null bs=1M 2>&1 | tail -1)
    echo "    $read_result"
    
    # Cleanup test file
    rm -f "$mount_point/seq_write_test"
    echo ""
}

# Function to test random IOPS performance  
test_random_iops() {
    local mount_point=$1
    local tier_name=$2
    
    echo -e "${BLUE}Testing $tier_name random IOPS on $mount_point${NC}"
    
    # Check if mount point is writable
    if [ ! -w "$mount_point" ]; then
        echo -e "  ${RED}❌ Mount point not writable, skipping${NC}"
        return
    fi
    
    # Random IOPS test using fio if available
    if command -v fio >/dev/null 2>&1; then
        echo "  🎯 Random Read IOPS:"
        fio --name=random_test --ioengine=libaio --iodepth=32 --rw=randread --bs=4k \
            --direct=1 --size="${TEST_SIZE}M" --numjobs=1 --runtime=30 --group_reporting \
            --filename="$mount_point/random_test" 2>/dev/null | grep -E "(read|IOPS)" | head -2
        rm -f "$mount_point/random_test"
    else
        echo -e "  ${YELLOW}⚠️  fio not installed - skipping random IOPS test${NC}"
        echo "     Install with: apt install fio (Ubuntu/Debian) or yum install fio (RHEL/CentOS)"
    fi
    echo ""
}

# Function to test storage tier
test_storage_tier() {
    local tier_name=$1
    local tier_emoji=$2
    shift 2
    local mounts=("$@")
    
    echo -e "${GREEN}${tier_emoji} ${tier_name} Storage Performance Tests:${NC}"
    echo "================================================="
    
    local tested_any=false
    for mount in "${mounts[@]}"; do
        if [ -d "$mount" ]; then
            tested_any=true
            echo -e "\n📊 Testing $mount"
            test_sequential_performance "$mount" "$tier_name"
            if [ "$QUICK_MODE" = false ]; then
                test_random_iops "$mount" "$tier_name"  
            fi
        else
            echo -e "${YELLOW}⚠️  $mount directory not found, skipping${NC}"
        fi
    done
    
    if [ "$tested_any" = false ]; then
        echo -e "${YELLOW}⚠️  No ${tier_name,,} storage mounts found${NC}"
    fi
    echo ""
}

# Main benchmarking execution
echo -e "${GREEN}🔍 System Information:${NC}"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Storage devices:"
lsblk -d -o NAME,SIZE,MODEL | grep -E "(nvme|sda)"
echo ""

# Test Hot Storage (NVMe) - Critical for trading performance  
hot_mounts=("/data/jts/hot/postgresql" "/data/jts/hot/clickhouse" "/data/jts/hot/kafka" "/data/jts/hot/mongodb" "/data/jts/hot/redis")
test_storage_tier "Hot" "🔥" "${hot_mounts[@]}"

# Test Warm Storage (SATA) - For backups and logs
warm_mounts=("/data/warm-storage" "/data/local-backup")  
test_storage_tier "Warm" "🌡️" "${warm_mounts[@]}"

# Test Cold Storage (NAS) - For archival
cold_mounts=("/mnt/synology/jts/development" "/mnt/synology")
test_storage_tier "Cold" "🧊" "${cold_mounts[@]}"

# Display system I/O statistics if available
echo -e "${GREEN}📈 Current I/O Statistics:${NC}"
echo "================================"
if command -v iostat >/dev/null 2>&1; then
    iostat -x 1 1 2>/dev/null | grep -E "(Device|nvme|sda)" | head -10
else
    echo -e "${YELLOW}⚠️  iostat not available (install sysstat package)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Performance benchmarking completed!${NC}"
echo "Timestamp: $(date)"

# Performance threshold validation for trading system requirements
validate_performance_thresholds() {
    echo -e "${GREEN}🎯 Performance Threshold Validation:${NC}"
    echo "=========================================="
    
    # Define minimum performance thresholds for each storage tier
    local hot_min_iops=50000      # Hot storage: 50K IOPS minimum
    local hot_min_throughput=1000 # Hot storage: 1GB/s minimum  
    local warm_min_throughput=500 # Warm storage: 500MB/s minimum
    local cold_min_throughput=100 # Cold storage: 100MB/s minimum
    
    local overall_status=0        # 0 = success, 1 = failure
    local temp_log="/tmp/jts_benchmark_results.tmp"
    
    echo "Trading System Performance Requirements:"
    echo "  🔥 Hot Storage (NVMe):  ≥${hot_min_throughput} MB/s, ≥${hot_min_iops} IOPS"
    echo "  🌡️  Warm Storage (SATA): ≥${warm_min_throughput} MB/s" 
    echo "  🧊 Cold Storage (NAS):  ≥${cold_min_throughput} MB/s"
    echo ""
    
    # Function to extract throughput from dd output
    extract_throughput() {
        local dd_output="$1"
        # Handle both English and Korean dd output formats
        # English: "1073741824 bytes (1.1 GB, 1.0 GiB) copied, 1.23456 s, 869 MB/s"  
        # Korean: "268435456 바이트 (268 MB, 256 MiB) 복사함, 0.073157 s, 3.7 GB/s"
        local throughput=$(echo "$dd_output" | grep -o "[0-9.]\+ [GM]B/s" | head -1 | awk '{print $1}')
        local unit=$(echo "$dd_output" | grep -o "[0-9.]\+ [GM]B/s" | head -1 | awk '{print $2}')
        
        if [ "$unit" = "GB/s" ]; then
            # Convert GB/s to MB/s
            echo "$throughput * 1000" | bc -l 2>/dev/null | cut -d. -f1
        else
            # Already MB/s
            echo "$throughput" | cut -d. -f1
        fi
    }
    
    # Function to validate throughput against threshold
    check_throughput() {
        local actual="$1"
        local threshold="$2" 
        local storage_type="$3"
        
        if [ -n "$actual" ] && [ "${actual%.*}" -ge "$threshold" ] 2>/dev/null; then
            echo -e "    ✅ $storage_type: ${actual} MB/s (threshold: ${threshold} MB/s)"
            return 0
        else
            echo -e "    ❌ $storage_type: ${actual:-"N/A"} MB/s (threshold: ${threshold} MB/s)"
            return 1
        fi
    }
    
    echo "Analyzing recent benchmark results..."
    
    # Check if we have any mount points to validate
    local validation_performed=false
    
    # Validate Hot Storage performance
    for mount in "/data/jts/hot/postgresql" "/data/jts/hot/clickhouse"; do
        if [ -d "$mount" ] && [ -w "$mount" ]; then
            validation_performed=true
            echo "🔥 Testing $mount for trading system requirements..."
            
            # Quick throughput test
            local write_output
            write_output=$(dd if=/dev/zero of="$mount/validation_test" bs=1M count=100 oflag=direct 2>&1 | tail -1)
            local throughput=$(extract_throughput "$write_output")
            
            if ! check_throughput "$throughput" "$hot_min_throughput" "Hot Storage Write"; then
                overall_status=1
            fi
            
            # Read test
            local read_output
            read_output=$(dd if="$mount/validation_test" of=/dev/null bs=1M 2>&1 | tail -1)
            local read_throughput=$(extract_throughput "$read_output")
            
            if ! check_throughput "$read_throughput" "$hot_min_throughput" "Hot Storage Read"; then
                overall_status=1
            fi
            
            # Cleanup
            rm -f "$mount/validation_test"
            break # Only test first available mount
        fi
    done
    
    # Validate Warm Storage if available
    if mountpoint -q "/data/warm-storage" 2>/dev/null && [ -w "/data/warm-storage" ]; then
        validation_performed=true
        echo "🌡️ Testing warm storage for backup requirements..."
        
        local warm_output
        warm_output=$(dd if=/dev/zero of="/data/warm-storage/validation_test" bs=1M count=100 2>&1 | tail -1)
        local warm_throughput=$(extract_throughput "$warm_output")
        
        if ! check_throughput "$warm_throughput" "$warm_min_throughput" "Warm Storage"; then
            overall_status=1
        fi
        
        rm -f "/data/warm-storage/validation_test"
    fi
    
    echo ""
    
    # Final validation result
    if [ "$validation_performed" = false ]; then
        echo -e "${YELLOW}⚠️  No writable storage mounts found for validation${NC}"
        echo -e "   Manual performance validation required"
        return 2
    elif [ $overall_status -eq 0 ]; then
        echo -e "${GREEN}✅ ALL PERFORMANCE THRESHOLDS MET${NC}"
        echo -e "   Trading system performance requirements satisfied"
        return 0
    else
        echo -e "${RED}❌ PERFORMANCE BELOW TRADING REQUIREMENTS${NC}"
        echo -e "   ⚠️  System may experience trading latency issues"
        echo -e "   📋 Recommended actions:"
        echo -e "      - Verify SSD optimization settings"
        echo -e "      - Check for background I/O processes"  
        echo -e "      - Consider storage hardware upgrades"
        return 1
    fi
}

# Call the validation function at the end
validate_performance_thresholds
validation_exit_code=$?

# Exit with appropriate status for monitoring systems
if [ $validation_exit_code -eq 1 ]; then
    echo ""
    echo -e "${RED}🚨 CRITICAL: Trading system performance below requirements${NC}"
    exit 1
elif [ $validation_exit_code -eq 2 ]; then
    echo ""  
    echo -e "${YELLOW}⚠️  WARNING: Performance validation incomplete${NC}"
    exit 2
else
    echo ""
    echo -e "${GREEN}🎯 SUCCESS: All performance requirements met${NC}" 
    exit 0
fi