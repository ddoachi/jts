#!/bin/bash
# ============================================================================
# JTS Hot Storage Directory Validation Script
# ============================================================================
# Generated from: specs/1000/1001/1011.md
# Context: specs/1000/1001/1011.context.md
# Created: 2025-08-24
# Purpose: Validate hot storage directory structure and permissions
#
# Validates the hot storage directory structure, permissions, and service
# user access for the JTS trading system infrastructure.
#
# Usage: ./scripts/validate-directories.sh [options]
#
# Options:
#   -h, --help      Show this help message
#   -v, --verbose   Verbose output with detailed checks
#   -j, --json      Output results in JSON format
#   -q, --quiet     Quiet mode - only show errors and final status
#
# Exit codes:
#   0 - All validations passed
#   1 - One or more validations failed
#   2 - Script error or invalid usage
# ============================================================================

set -euo pipefail

# Configuration
BASE_DIR="/data/jts/hot"
REQUIRED_USERS=("postgres" "clickhouse" "kafka" "mongodb" "redis")
REQUIRED_SERVICES=("postgresql" "clickhouse" "kafka" "mongodb" "redis" "docker" "backup")

# Output configuration  
VERBOSE=false
QUIET=false
JSON_OUTPUT=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Validation results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Arrays to store results
PASS_RESULTS=()
FAIL_RESULTS=()
WARN_RESULTS=()

# Function to print usage
usage() {
    echo "JTS Hot Storage Directory Validation Script"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -v, --verbose   Verbose output with detailed checks"
    echo "  -j, --json      Output results in JSON format"
    echo "  -q, --quiet     Quiet mode - only show errors and final status"
    echo ""
    echo "Examples:"
    echo "  $0                # Standard validation"
    echo "  $0 -v             # Verbose validation with details"
    echo "  $0 -j             # JSON output for automation"
    echo "  $0 -q             # Quiet mode for scripts"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -j|--json)
            JSON_OUTPUT=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 2
            ;;
    esac
done

# Logging functions
log_info() {
    if [[ "$QUIET" != "true" && "$JSON_OUTPUT" != "true" ]]; then
        echo -e "${BLUE}ℹ️  $1${NC}"
    fi
}

log_success() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    PASS_RESULTS+=("$1")
    
    if [[ "$QUIET" != "true" && "$JSON_OUTPUT" != "true" ]]; then
        echo -e "${GREEN}✅ $1${NC}"
    fi
}

log_failure() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    FAIL_RESULTS+=("$1")
    
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo -e "${RED}❌ $1${NC}"
    fi
}

log_warning() {
    WARNINGS=$((WARNINGS + 1))
    WARN_RESULTS+=("$1")
    
    if [[ "$QUIET" != "true" && "$JSON_OUTPUT" != "true" ]]; then
        echo -e "${YELLOW}⚠️  $1${NC}"
    fi
}

log_verbose() {
    if [[ "$VERBOSE" == "true" && "$JSON_OUTPUT" != "true" ]]; then
        echo -e "${BLUE}    → $1${NC}"
    fi
}

# Validation functions
validate_base_directory() {
    log_info "Validating base directory structure..."
    
    if [[ -d "$BASE_DIR" ]]; then
        log_success "Base directory exists: $BASE_DIR"
        log_verbose "Directory permissions: $(ls -ld "$BASE_DIR" | awk '{print $1}')"
        log_verbose "Directory owner: $(ls -ld "$BASE_DIR" | awk '{print $3":"$4}')"
    else
        log_failure "Base directory missing: $BASE_DIR"
        return 1
    fi
}

validate_service_users() {
    log_info "Validating service users..."
    
    local missing_users=()
    for user in "${REQUIRED_USERS[@]}"; do
        if id "$user" &>/dev/null; then
            log_success "Service user exists: $user"
            if [[ "$VERBOSE" == "true" ]]; then
                local user_info
                user_info=$(id "$user")
                log_verbose "User info: $user_info"
            fi
        else
            log_failure "Service user missing: $user"
            missing_users+=("$user")
        fi
    done
    
    # Check docker group
    if getent group docker > /dev/null; then
        log_success "Docker group exists"
    else
        log_warning "Docker group missing - required for Docker service"
    fi
    
    if [[ ${#missing_users[@]} -gt 0 ]]; then
        return 1
    fi
}

validate_service_directories() {
    log_info "Validating service directories..."
    
    local missing_dirs=()
    for service in "${REQUIRED_SERVICES[@]}"; do
        local service_dir="$BASE_DIR/$service"
        
        if [[ -d "$service_dir" ]]; then
            log_success "Service directory exists: $service"
            
            if [[ "$VERBOSE" == "true" ]]; then
                log_verbose "Path: $service_dir"
                log_verbose "Permissions: $(ls -ld "$service_dir" | awk '{print $1}')"
                log_verbose "Owner: $(ls -ld "$service_dir" | awk '{print $3":"$4}')"
            fi
        else
            log_failure "Service directory missing: $service"
            missing_dirs+=("$service")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        return 1
    fi
}

validate_subdirectories() {
    log_info "Validating service subdirectories..."
    
    # Define expected subdirectories for each service
    declare -A expected_subdirs
    expected_subdirs["postgresql"]="data logs config"
    expected_subdirs["clickhouse"]="data logs tmp"
    expected_subdirs["kafka"]="data logs"
    expected_subdirs["mongodb"]="data logs config"
    expected_subdirs["redis"]="data logs"
    expected_subdirs["docker"]="volumes containers tmp"
    expected_subdirs["backup"]="daily snapshots staging"
    
    local missing_subdirs=()
    for service in "${REQUIRED_SERVICES[@]}"; do
        local service_dir="$BASE_DIR/$service"
        if [[ -d "$service_dir" ]]; then
            local subdirs="${expected_subdirs[$service]}"
            for subdir in $subdirs; do
                local full_path="$service_dir/$subdir"
                if [[ -d "$full_path" ]]; then
                    log_success "Subdirectory exists: $service/$subdir"
                    log_verbose "Path: $full_path"
                else
                    log_failure "Subdirectory missing: $service/$subdir"
                    missing_subdirs+=("$service/$subdir")
                fi
            done
        fi
    done
    
    if [[ ${#missing_subdirs[@]} -gt 0 ]]; then
        return 1
    fi
}

validate_permissions() {
    log_info "Validating directory permissions..."
    
    local permission_errors=()
    
    # Check base directory permissions (should be 755)
    local base_perms
    base_perms=$(stat -c "%a" "$BASE_DIR" 2>/dev/null || echo "000")
    if [[ "$base_perms" == "755" ]]; then
        log_success "Base directory permissions correct: $base_perms"
    else
        log_failure "Base directory permissions incorrect: $base_perms (expected: 755)"
        permission_errors+=("base")
    fi
    
    # Check service directory permissions
    for service in "${REQUIRED_SERVICES[@]}"; do
        local service_dir="$BASE_DIR/$service"
        if [[ -d "$service_dir" ]]; then
            local perms
            perms=$(stat -c "%a" "$service_dir" 2>/dev/null || echo "000")
            
            case "$service" in
                "docker"|"backup")
                    if [[ "$perms" == "755" ]]; then
                        log_success "Directory permissions correct: $service ($perms)"
                    else
                        log_failure "Directory permissions incorrect: $service ($perms, expected: 755)"
                        permission_errors+=("$service")
                    fi
                    ;;
                *)
                    if [[ "$perms" == "750" ]]; then
                        log_success "Directory permissions correct: $service ($perms)"
                    else
                        log_failure "Directory permissions incorrect: $service ($perms, expected: 750)"
                        permission_errors+=("$service")
                    fi
                    ;;
            esac
        fi
    done
    
    if [[ ${#permission_errors[@]} -gt 0 ]]; then
        return 1
    fi
}

validate_ownership() {
    log_info "Validating directory ownership..."
    
    local ownership_errors=()
    
    for service in "${REQUIRED_SERVICES[@]}"; do
        local service_dir="$BASE_DIR/$service"
        if [[ -d "$service_dir" ]]; then
            local owner group
            owner=$(stat -c "%U" "$service_dir" 2>/dev/null || echo "unknown")
            group=$(stat -c "%G" "$service_dir" 2>/dev/null || echo "unknown")
            
            case "$service" in
                "docker")
                    if [[ "$owner" == "root" && "$group" == "docker" ]]; then
                        log_success "Directory ownership correct: $service (root:docker)"
                    else
                        log_failure "Directory ownership incorrect: $service ($owner:$group, expected: root:docker)"
                        ownership_errors+=("$service")
                    fi
                    ;;
                "backup")
                    if [[ "$owner" == "root" && "$group" == "root" ]]; then
                        log_success "Directory ownership correct: $service (root:root)"
                    else
                        log_failure "Directory ownership incorrect: $service ($owner:$group, expected: root:root)"
                        ownership_errors+=("$service")
                    fi
                    ;;
                "postgresql")
                    if [[ "$owner" == "postgres" && "$group" == "postgres" ]]; then
                        log_success "Directory ownership correct: $service (postgres:postgres)"
                    else
                        log_failure "Directory ownership incorrect: $service ($owner:$group, expected: postgres:postgres)"
                        ownership_errors+=("$service")
                    fi
                    ;;
                *)
                    if [[ "$owner" == "$service" && "$group" == "$service" ]]; then
                        log_success "Directory ownership correct: $service ($service:$service)"
                    else
                        log_failure "Directory ownership incorrect: $service ($owner:$group, expected: $service:$service)"
                        ownership_errors+=("$service")
                    fi
                    ;;
            esac
        fi
    done
    
    if [[ ${#ownership_errors[@]} -gt 0 ]]; then
        return 1
    fi
}

validate_write_access() {
    log_info "Validating write access for service users..."
    
    local access_errors=()
    local temp_files=()
    
    for user in "${REQUIRED_USERS[@]}"; do
        if id "$user" &>/dev/null; then
            local user_dir="$BASE_DIR/$user"
            if [[ -d "$user_dir" ]]; then
                local test_file="$user_dir/.validation_test_$$"
                if sudo -u "$user" touch "$test_file" 2>/dev/null; then
                    log_success "Write access validated: $user"
                    temp_files+=("$test_file")
                    log_verbose "Test file created: $test_file"
                else
                    log_failure "Write access failed: $user"
                    access_errors+=("$user")
                fi
            fi
        fi
    done
    
    # Clean up test files
    for file in "${temp_files[@]}"; do
        rm -f "$file" 2>/dev/null || true
    done
    
    if [[ "$VERBOSE" == "true" && ${#temp_files[@]} -gt 0 ]]; then
        log_verbose "Cleaned up ${#temp_files[@]} test files"
    fi
    
    if [[ ${#access_errors[@]} -gt 0 ]]; then
        return 1
    fi
}

validate_disk_space() {
    log_info "Validating available disk space..."
    
    local fs_info
    fs_info=$(df -B1 "$BASE_DIR" 2>/dev/null | tail -1)
    local total used available percentage
    total=$(echo "$fs_info" | awk '{print $2}')
    used=$(echo "$fs_info" | awk '{print $3}')
    available=$(echo "$fs_info" | awk '{print $4}')
    percentage=$(echo "$fs_info" | awk '{print $5}' | sed 's/%//')
    
    # Convert to human readable
    local total_gb available_gb
    total_gb=$(( total / 1024 / 1024 / 1024 ))
    available_gb=$(( available / 1024 / 1024 / 1024 ))
    
    if [[ $available_gb -gt 10 ]]; then
        log_success "Sufficient disk space available: ${available_gb}GB"
    elif [[ $available_gb -gt 1 ]]; then
        log_warning "Low disk space: ${available_gb}GB available"
    else
        log_failure "Critical disk space: ${available_gb}GB available"
        return 1
    fi
    
    if [[ $percentage -lt 90 ]]; then
        log_success "Disk usage acceptable: ${percentage}%"
    elif [[ $percentage -lt 95 ]]; then
        log_warning "Disk usage high: ${percentage}%"
    else
        log_failure "Disk usage critical: ${percentage}%"
        return 1
    fi
    
    log_verbose "Total space: ${total_gb}GB"
    log_verbose "Used space: $(( used / 1024 / 1024 / 1024 ))GB"
    log_verbose "Available space: ${available_gb}GB"
}

# Output results in JSON format
output_json() {
    echo "{"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"validation_summary\": {"
    echo "    \"total_checks\": $TOTAL_CHECKS,"
    echo "    \"passed\": $PASSED_CHECKS,"
    echo "    \"failed\": $FAILED_CHECKS,"
    echo "    \"warnings\": $WARNINGS,"
    echo "    \"success_rate\": \"$(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))%\""
    echo "  },"
    echo "  \"results\": {"
    echo "    \"passed\": ["
    
    local first=true
    for result in "${PASS_RESULTS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        echo -n "      \"$result\""
    done
    echo ""
    echo "    ],"
    echo "    \"failed\": ["
    
    first=true
    for result in "${FAIL_RESULTS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        echo -n "      \"$result\""
    done
    echo ""
    echo "    ],"
    echo "    \"warnings\": ["
    
    first=true
    for result in "${WARN_RESULTS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        echo -n "      \"$result\""
    done
    echo ""
    echo "    ]"
    echo "  }"
    echo "}"
}

# Main validation function
main() {
    local start_time
    start_time=$(date +%s)
    
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo -e "${BOLD}JTS Hot Storage Directory Validation${NC}"
        echo "==========================================="
        echo
    fi
    
    # Run all validations
    local validation_result=0
    
    validate_base_directory || validation_result=1
    validate_service_users || validation_result=1
    validate_service_directories || validation_result=1
    validate_subdirectories || validation_result=1
    validate_permissions || validation_result=1
    validate_ownership || validation_result=1
    validate_write_access || validation_result=1
    validate_disk_space || validation_result=1
    
    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Output results
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        output_json
    else
        echo
        echo -e "${BOLD}Validation Summary:${NC}"
        echo "==================="
        echo "Total Checks: $TOTAL_CHECKS"
        echo "Passed: $PASSED_CHECKS"
        echo "Failed: $FAILED_CHECKS"
        echo "Warnings: $WARNINGS"
        echo "Duration: ${duration}s"
        
        if [[ $validation_result -eq 0 ]]; then
            echo
            echo -e "${GREEN}🎉 All validations passed! Hot storage is properly configured.${NC}"
        else
            echo
            echo -e "${RED}💥 Validation failed! Please fix the issues above.${NC}"
            echo
            echo -e "${YELLOW}To fix issues, run:${NC}"
            echo "  sudo ./scripts/setup-hot-directories.sh"
        fi
    fi
    
    exit $validation_result
}

# Run main function
main "$@"