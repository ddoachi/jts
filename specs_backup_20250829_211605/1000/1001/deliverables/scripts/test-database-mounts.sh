#!/bin/bash

# Database Mount Integration Test Suite
# Tests all acceptance criteria for spec 1012
# Run with: sudo ./test-database-mounts.sh

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test result arrays
declare -a TEST_RESULTS
declare -a FAILED_TEST_NAMES

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}\n"
}

# Function to record test result
record_test() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        [ -n "$details" ] && echo -e "  ${details}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("PASS: $test_name")
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  ${RED}$details${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("FAIL: $test_name")
        FAILED_TEST_NAMES+=("$test_name")
    fi
}

# Function to test command success
test_command() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    if eval "$command" > /dev/null 2>&1; then
        record_test "$test_name" "PASS" ""
    else
        record_test "$test_name" "FAIL" "Command failed: $command"
    fi
}

# Acceptance Criteria 1: Service User Creation
test_service_users() {
    print_section "Testing Service User Creation"
    
    local users=("postgres" "clickhouse" "kafka" "mongodb" "redis")
    
    for user in "${users[@]}"; do
        if id "$user" &>/dev/null; then
            # Check user properties
            local user_info=$(getent passwd "$user")
            local shell=$(echo "$user_info" | cut -d: -f7)
            local home=$(echo "$user_info" | cut -d: -f6)
            
            # Verify system user (UID < 1000 typically)
            local uid=$(id -u "$user")
            if [ "$uid" -lt 1000 ]; then
                record_test "User $user exists as system user (UID: $uid)" "PASS" ""
            else
                record_test "User $user exists" "FAIL" "Not a system user (UID: $uid)"
            fi
            
            # Verify nologin shell
            if [[ "$shell" == *"nologin"* ]] || [[ "$shell" == "/bin/false" ]]; then
                record_test "User $user has restricted shell" "PASS" "Shell: $shell"
            else
                record_test "User $user shell restriction" "FAIL" "Shell should be nologin, got: $shell"
            fi
            
            # Verify home directory
            if [[ "$home" == "/var/lib/$user"* ]]; then
                record_test "User $user home directory" "PASS" "Home: $home"
            else
                record_test "User $user home directory" "FAIL" "Expected /var/lib/$user*, got: $home"
            fi
        else
            record_test "User $user exists" "FAIL" "User not found"
        fi
    done
    
    # Test operational groups
    for group in docker backup; do
        if getent group "$group" &>/dev/null; then
            record_test "Group $group exists" "PASS" ""
        else
            record_test "Group $group exists" "FAIL" "Group not found"
        fi
    done
}

# Acceptance Criteria 2: Mount Point Creation
test_mount_points() {
    print_section "Testing Mount Point Creation"
    
    local mount_points=(
        "/var/lib/postgresql"
        "/var/lib/clickhouse"
        "/var/lib/kafka"
        "/var/lib/mongodb"
        "/var/lib/redis"
        "/var/lib/docker-jts"
        "/data/local-backup"
    )
    
    for mount_point in "${mount_points[@]}"; do
        if [ -d "$mount_point" ]; then
            record_test "Mount point $mount_point exists" "PASS" ""
            
            # Check if it's actually a mount point (optional)
            if mountpoint -q "$mount_point" 2>/dev/null; then
                record_test "Directory $mount_point is mounted" "PASS" ""
            else
                # Not necessarily a failure - might not be mounted yet
                echo -e "${YELLOW}  Note: $mount_point exists but is not currently mounted${NC}"
            fi
        else
            record_test "Mount point $mount_point exists" "FAIL" "Directory not found"
        fi
    done
}

# Acceptance Criteria 3: Ownership Configuration
test_ownership() {
    print_section "Testing Ownership Configuration"
    
    declare -A expected_ownership=(
        ["/var/lib/postgresql"]="postgres:postgres"
        ["/var/lib/clickhouse"]="clickhouse:clickhouse"
        ["/var/lib/kafka"]="kafka:kafka"
        ["/var/lib/mongodb"]="mongodb:mongodb"
        ["/var/lib/redis"]="redis:redis"
        ["/var/lib/docker-jts"]="root:docker"
        ["/data/local-backup"]="root:backup"
    )
    
    for path in "${!expected_ownership[@]}"; do
        if [ -d "$path" ]; then
            local actual_owner=$(stat -c "%U:%G" "$path" 2>/dev/null)
            local expected="${expected_ownership[$path]}"
            
            if [ "$actual_owner" = "$expected" ]; then
                record_test "Ownership of $path" "PASS" "Owner: $actual_owner"
            else
                record_test "Ownership of $path" "FAIL" "Expected $expected, got $actual_owner"
            fi
        else
            record_test "Ownership of $path" "FAIL" "Directory not found"
        fi
    done
}

# Acceptance Criteria 4: Permission Security
test_permissions() {
    print_section "Testing Permission Security"
    
    declare -A expected_permissions=(
        ["/var/lib/postgresql"]="750"
        ["/var/lib/clickhouse"]="750"
        ["/var/lib/kafka"]="750"
        ["/var/lib/mongodb"]="750"
        ["/var/lib/redis"]="750"
        ["/var/lib/docker-jts"]="750"
        ["/data/local-backup"]="755"
    )
    
    for path in "${!expected_permissions[@]}"; do
        if [ -d "$path" ]; then
            local actual_perms=$(stat -c "%a" "$path" 2>/dev/null)
            local expected="${expected_permissions[$path]}"
            
            if [ "$actual_perms" = "$expected" ]; then
                record_test "Permissions of $path" "PASS" "Perms: $actual_perms"
            else
                record_test "Permissions of $path" "FAIL" "Expected $expected, got $actual_perms"
            fi
        else
            record_test "Permissions of $path" "FAIL" "Directory not found"
        fi
    done
}

# Acceptance Criteria 5: Mount Validation
test_mount_validation() {
    print_section "Testing Mount Validation"
    
    # Check if LVM volumes exist
    if command -v lvs &>/dev/null; then
        if lvs vg_jts 2>/dev/null | grep -q lv_; then
            record_test "LVM volume group vg_jts exists" "PASS" ""
            
            # Check for specific logical volumes
            local volumes=("postgresql" "clickhouse" "kafka" "mongodb" "redis" "docker" "backup")
            for vol in "${volumes[@]}"; do
                if lvs vg_jts/lv_$vol &>/dev/null 2>&1; then
                    record_test "Logical volume lv_$vol exists" "PASS" ""
                else
                    echo -e "${YELLOW}  Note: Logical volume lv_$vol not found${NC}"
                fi
            done
        else
            echo -e "${YELLOW}  Note: LVM volume group vg_jts not found - might not be using LVM${NC}"
        fi
    else
        echo -e "${YELLOW}  Note: LVM tools not installed - skipping LVM checks${NC}"
    fi
    
    # Test mount command
    if mount -a 2>/dev/null; then
        record_test "mount -a command successful" "PASS" ""
    else
        echo -e "${YELLOW}  Note: mount -a had issues (might need fstab entries)${NC}"
    fi
}

# Acceptance Criteria 6: Database Integration
test_database_integration() {
    print_section "Testing Database Integration"
    
    # Test write access for each service user
    declare -A test_paths=(
        ["postgres"]="/var/lib/postgresql"
        ["clickhouse"]="/var/lib/clickhouse"
        ["kafka"]="/var/lib/kafka"
        ["mongodb"]="/var/lib/mongodb"
        ["redis"]="/var/lib/redis"
    )
    
    for user in "${!test_paths[@]}"; do
        local path="${test_paths[$user]}"
        local test_file="$path/.test_write_$$"
        
        if [ -d "$path" ]; then
            # Test write access
            if sudo -u "$user" touch "$test_file" 2>/dev/null; then
                sudo -u "$user" rm "$test_file" 2>/dev/null
                record_test "Write access for $user to $path" "PASS" ""
            else
                record_test "Write access for $user to $path" "FAIL" "Cannot write to directory"
            fi
            
            # Test read access
            if sudo -u "$user" ls "$path" &>/dev/null; then
                record_test "Read access for $user to $path" "PASS" ""
            else
                record_test "Read access for $user to $path" "FAIL" "Cannot read directory"
            fi
        else
            record_test "Database integration for $user" "FAIL" "Directory $path not found"
        fi
    done
}

# Acceptance Criteria 7: Security Validation
test_security_isolation() {
    print_section "Testing Security Isolation"
    
    # Test cross-service access (should fail)
    declare -A cross_tests=(
        ["postgres trying to access clickhouse"]="sudo -u postgres ls /var/lib/clickhouse 2>/dev/null"
        ["clickhouse trying to access mongodb"]="sudo -u clickhouse ls /var/lib/mongodb 2>/dev/null"
        ["mongodb trying to access kafka"]="sudo -u mongodb ls /var/lib/kafka 2>/dev/null"
        ["kafka trying to access redis"]="sudo -u kafka ls /var/lib/redis 2>/dev/null"
        ["redis trying to access postgresql"]="sudo -u redis ls /var/lib/postgresql 2>/dev/null"
    )
    
    for test_name in "${!cross_tests[@]}"; do
        local command="${cross_tests[$test_name]}"
        
        if eval "$command"; then
            record_test "Isolation: $test_name" "FAIL" "Cross-service access should be denied"
        else
            record_test "Isolation: $test_name" "PASS" "Access properly denied"
        fi
    done
    
    # Test that each service can ONLY access its own directory
    local services=("postgres" "clickhouse" "kafka" "mongodb" "redis")
    for service in "${services[@]}"; do
        local own_dir="/var/lib/$service"
        if [ -d "$own_dir" ]; then
            if sudo -u "$service" ls "$own_dir" &>/dev/null; then
                record_test "Service $service can access own directory" "PASS" ""
            else
                record_test "Service $service can access own directory" "FAIL" "Cannot access $own_dir"
            fi
        fi
    done
}

# Acceptance Criteria 8: Automation Scripts
test_automation_scripts() {
    print_section "Testing Automation Scripts"
    
    local script_dir="/home/joohan/dev/project-jts/jts/specs/1000/1001/deliverables/scripts"
    local scripts=(
        "setup-database-users.sh"
        "setup-mount-points.sh"
        "configure-permissions.sh"
        "validate-database-mounts.sh"
    )
    
    for script in "${scripts[@]}"; do
        local script_path="$script_dir/$script"
        if [ -f "$script_path" ]; then
            record_test "Script $script exists" "PASS" ""
            
            # Check if executable
            if [ -x "$script_path" ]; then
                record_test "Script $script is executable" "PASS" ""
            else
                record_test "Script $script is executable" "FAIL" "Missing execute permission"
            fi
            
            # Basic syntax check
            if bash -n "$script_path" 2>/dev/null; then
                record_test "Script $script syntax" "PASS" ""
            else
                record_test "Script $script syntax" "FAIL" "Syntax errors detected"
            fi
        else
            record_test "Script $script exists" "FAIL" "File not found at $script_path"
        fi
    done
    
    # Check documentation
    local doc_path="$script_dir/../docs/DATABASE_MOUNT_SETUP.md"
    if [ -f "$doc_path" ]; then
        record_test "Documentation DATABASE_MOUNT_SETUP.md exists" "PASS" ""
    else
        record_test "Documentation DATABASE_MOUNT_SETUP.md exists" "FAIL" "File not found"
    fi
}

# Function to print summary
print_summary() {
    print_section "Test Summary"
    
    echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo -e "\n${RED}Failed Tests:${NC}"
        for test in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
    fi
    
    # Calculate success rate
    if [ $TOTAL_TESTS -gt 0 ]; then
        local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo -e "\nSuccess Rate: ${success_rate}%"
        
        if [ $success_rate -eq 100 ]; then
            echo -e "\n${GREEN}All acceptance criteria have been met!${NC}"
            return 0
        elif [ $success_rate -ge 80 ]; then
            echo -e "\n${YELLOW}Most acceptance criteria met, but some issues remain.${NC}"
            return 1
        else
            echo -e "\n${RED}Multiple acceptance criteria not met.${NC}"
            return 1
        fi
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Database Mount Integration Test Suite${NC}"
    echo -e "${BLUE}Spec 1012 Acceptance Criteria Testing${NC}"
    echo -e "${BLUE}======================================${NC}\n"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Warning: Some tests require root privileges.${NC}"
        echo -e "${YELLOW}Run with: sudo $0${NC}\n"
    fi
    
    # Run all test suites
    test_service_users
    test_mount_points
    test_ownership
    test_permissions
    test_mount_validation
    test_database_integration
    test_security_isolation
    test_automation_scripts
    
    # Print summary
    print_summary
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"