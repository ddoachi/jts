#!/bin/bash

# Quick test summary for database mount integration
# Can be run without sudo to check current state

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Database Mount Integration - Quick Status Check${NC}"
echo -e "${BLUE}===============================================${NC}\n"

# Acceptance Criteria Checklist
echo -e "${BLUE}Acceptance Criteria Status:${NC}\n"

# 1. Service User Creation
echo -e "${YELLOW}1. Service User Creation:${NC}"
users=("postgres" "clickhouse" "kafka" "mongodb" "redis")
all_users_ok=true
for user in "${users[@]}"; do
    if id "$user" &>/dev/null; then
        echo -e "   ${GREEN}✓${NC} User $user exists"
    else
        echo -e "   ${RED}✗${NC} User $user missing"
        all_users_ok=false
    fi
done
if $all_users_ok; then
    echo -e "   ${GREEN}[PASS] All database users created${NC}"
else
    echo -e "   ${RED}[FAIL] Some users missing${NC}"
fi

# 2. Mount Point Creation
echo -e "\n${YELLOW}2. Mount Point Creation:${NC}"
mount_points=(
    "/var/lib/postgresql"
    "/var/lib/clickhouse"
    "/var/lib/kafka"
    "/var/lib/mongodb"
    "/var/lib/redis"
    "/var/lib/docker-jts"
    "/data/local-backup"
)
all_mounts_ok=true
for mount in "${mount_points[@]}"; do
    if [ -d "$mount" ]; then
        echo -e "   ${GREEN}✓${NC} Directory $mount exists"
    else
        echo -e "   ${RED}✗${NC} Directory $mount missing"
        all_mounts_ok=false
    fi
done
if $all_mounts_ok; then
    echo -e "   ${GREEN}[PASS] All mount points created${NC}"
else
    echo -e "   ${RED}[FAIL] Some mount points missing${NC}"
fi

# 3. Ownership Configuration
echo -e "\n${YELLOW}3. Ownership Configuration:${NC}"
declare -A ownership=(
    ["/var/lib/postgresql"]="postgres:postgres"
    ["/var/lib/clickhouse"]="clickhouse:clickhouse"
    ["/var/lib/kafka"]="kafka:kafka"
    ["/var/lib/mongodb"]="mongodb:mongodb"
    ["/var/lib/redis"]="redis:redis"
    ["/var/lib/docker-jts"]="root:docker"
    ["/data/local-backup"]="root:backup"
)
ownership_ok=true
for path in "${!ownership[@]}"; do
    if [ -d "$path" ]; then
        actual=$(stat -c "%U:%G" "$path" 2>/dev/null)
        expected="${ownership[$path]}"
        if [ "$actual" = "$expected" ]; then
            echo -e "   ${GREEN}✓${NC} $path owned by $actual"
        else
            echo -e "   ${RED}✗${NC} $path owned by $actual (expected $expected)"
            ownership_ok=false
        fi
    fi
done
if $ownership_ok; then
    echo -e "   ${GREEN}[PASS] All ownership configured correctly${NC}"
else
    echo -e "   ${RED}[FAIL] Some ownership issues${NC}"
fi

# 4. Permission Security
echo -e "\n${YELLOW}4. Permission Security:${NC}"
declare -A permissions=(
    ["/var/lib/postgresql"]="750"
    ["/var/lib/clickhouse"]="750"
    ["/var/lib/kafka"]="750"
    ["/var/lib/mongodb"]="750"
    ["/var/lib/redis"]="750"
    ["/var/lib/docker-jts"]="750"
    ["/data/local-backup"]="755"
)
perms_ok=true
for path in "${!permissions[@]}"; do
    if [ -d "$path" ]; then
        actual=$(stat -c "%a" "$path" 2>/dev/null)
        expected="${permissions[$path]}"
        if [ "$actual" = "$expected" ]; then
            echo -e "   ${GREEN}✓${NC} $path has permissions $actual"
        else
            echo -e "   ${RED}✗${NC} $path has permissions $actual (expected $expected)"
            perms_ok=false
        fi
    fi
done
if $perms_ok; then
    echo -e "   ${GREEN}[PASS] All permissions set correctly${NC}"
else
    echo -e "   ${RED}[FAIL] Some permission issues${NC}"
fi

# 5. Mount Validation (check if LVM configured)
echo -e "\n${YELLOW}5. Mount Validation:${NC}"
if command -v lvs &>/dev/null; then
    if lvs 2>/dev/null | grep -q vg_jts; then
        echo -e "   ${GREEN}✓${NC} LVM volume group vg_jts exists"
        echo -e "   ${GREEN}[PASS] LVM configured${NC}"
    else
        echo -e "   ${YELLOW}⚠${NC} LVM volume group vg_jts not found"
        echo -e "   ${YELLOW}[INFO] LVM not yet configured (expected if storage setup incomplete)${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} LVM tools not installed"
    echo -e "   ${YELLOW}[INFO] Cannot check LVM configuration${NC}"
fi

# 6. Database Integration (requires sudo)
echo -e "\n${YELLOW}6. Database Integration:${NC}"
echo -e "   ${YELLOW}[INFO] Requires sudo to test write access${NC}"
echo -e "   Run: sudo ./test-database-mounts.sh for full testing"

# 7. Security Validation (requires sudo)
echo -e "\n${YELLOW}7. Security Validation:${NC}"
echo -e "   ${YELLOW}[INFO] Requires sudo to test cross-service isolation${NC}"
echo -e "   Run: sudo ./test-database-mounts.sh for full testing"

# 8. Automation Scripts
echo -e "\n${YELLOW}8. Automation Scripts:${NC}"
script_dir="/home/joohan/dev/project-jts/jts/specs/1000/1001/deliverables/scripts"
scripts=(
    "setup-database-users.sh"
    "setup-mount-points.sh"
    "configure-permissions.sh"
    "validate-database-mounts.sh"
)
scripts_ok=true
for script in "${scripts[@]}"; do
    if [ -f "$script_dir/$script" ]; then
        if [ -x "$script_dir/$script" ]; then
            echo -e "   ${GREEN}✓${NC} Script $script exists and is executable"
        else
            echo -e "   ${YELLOW}⚠${NC} Script $script exists but not executable"
            scripts_ok=false
        fi
    else
        echo -e "   ${RED}✗${NC} Script $script missing"
        scripts_ok=false
    fi
done
if [ -f "$script_dir/../docs/DATABASE_MOUNT_SETUP.md" ]; then
    echo -e "   ${GREEN}✓${NC} Documentation exists"
else
    echo -e "   ${RED}✗${NC} Documentation missing"
    scripts_ok=false
fi
if $scripts_ok; then
    echo -e "   ${GREEN}[PASS] All automation scripts ready${NC}"
else
    echo -e "   ${RED}[FAIL] Some scripts/docs missing or not executable${NC}"
fi

# Summary
echo -e "\n${BLUE}===============================================${NC}"
echo -e "${BLUE}Summary:${NC}"
echo -e "  • Most acceptance criteria can be verified without sudo"
echo -e "  • Database integration and security tests require sudo access"
echo -e "  • Run ${YELLOW}sudo ./test-database-mounts.sh${NC} for complete testing"
echo -e "  • Run ${YELLOW}sudo ./fix-test-issues.sh${NC} to fix any issues found"
echo -e "${BLUE}===============================================${NC}"