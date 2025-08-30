#!/bin/bash

# Fix issues found during database mount integration testing
# Run with: sudo ./fix-test-issues.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Database Mount Integration - Test Issue Fixes${NC}"
echo -e "${BLUE}=============================================${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo -e "${YELLOW}Usage: sudo $0${NC}"
    exit 1
fi

echo -e "${GREEN}Fixing identified issues from test results...${NC}\n"

# Issue 1: Fix user home directories
echo -e "${YELLOW}1. Correcting user home directories...${NC}"
users=("postgres" "clickhouse" "kafka" "mongodb" "redis")

for user in "${users[@]}"; do
    echo -e "  Updating home directory for $user to /var/lib/$user"
    usermod -d "/var/lib/$user" "$user" 2>/dev/null || echo "    Warning: Could not update $user home directory"
done

# Issue 2: Fix permissions
echo -e "\n${YELLOW}2. Correcting directory permissions...${NC}"

# Fix /var/lib/docker-jts permissions (should be 750, not 770)
if [ -d "/var/lib/docker-jts" ]; then
    echo -e "  Setting /var/lib/docker-jts permissions to 750"
    chmod 750 /var/lib/docker-jts
else
    echo -e "  ${RED}Directory /var/lib/docker-jts not found${NC}"
fi

# Fix /data/local-backup permissions (should be 755, not 775)
if [ -d "/data/local-backup" ]; then
    echo -e "  Setting /data/local-backup permissions to 755"
    chmod 755 /data/local-backup
else
    echo -e "  ${RED}Directory /data/local-backup not found${NC}"
fi

# Issue 3: Ensure proper subdirectory structure for databases
echo -e "\n${YELLOW}3. Creating subdirectory structures...${NC}"

# PostgreSQL needs a data subdirectory
if [ -d "/var/lib/postgresql" ]; then
    echo -e "  Creating /var/lib/postgresql/data"
    mkdir -p /var/lib/postgresql/data
    chown -R postgres:postgres /var/lib/postgresql
    chmod -R 750 /var/lib/postgresql
fi

# ClickHouse needs data and tmp subdirectories
if [ -d "/var/lib/clickhouse" ]; then
    echo -e "  Creating /var/lib/clickhouse/{data,tmp}"
    mkdir -p /var/lib/clickhouse/{data,tmp}
    chown -R clickhouse:clickhouse /var/lib/clickhouse
    chmod -R 750 /var/lib/clickhouse
fi

# Kafka needs logs subdirectory
if [ -d "/var/lib/kafka" ]; then
    echo -e "  Creating /var/lib/kafka/logs"
    mkdir -p /var/lib/kafka/logs
    chown -R kafka:kafka /var/lib/kafka
    chmod -R 750 /var/lib/kafka
fi

# MongoDB needs db subdirectory
if [ -d "/var/lib/mongodb" ]; then
    echo -e "  Creating /var/lib/mongodb/db"
    mkdir -p /var/lib/mongodb/db
    chown -R mongodb:mongodb /var/lib/mongodb
    chmod -R 750 /var/lib/mongodb
fi

# Redis needs data subdirectory
if [ -d "/var/lib/redis" ]; then
    echo -e "  Creating /var/lib/redis/data"
    mkdir -p /var/lib/redis/data
    chown -R redis:redis /var/lib/redis
    chmod -R 750 /var/lib/redis
fi

# Verification
echo -e "\n${YELLOW}4. Verifying fixes...${NC}"

# Check user home directories
echo -e "\n  ${BLUE}User Home Directories:${NC}"
for user in "${users[@]}"; do
    home_dir=$(getent passwd "$user" | cut -d: -f6)
    if [[ "$home_dir" == "/var/lib/$user" ]]; then
        echo -e "  ${GREEN}✓${NC} $user: $home_dir"
    else
        echo -e "  ${RED}✗${NC} $user: $home_dir (expected /var/lib/$user)"
    fi
done

# Check permissions
echo -e "\n  ${BLUE}Directory Permissions:${NC}"
declare -A expected_perms=(
    ["/var/lib/docker-jts"]="750"
    ["/data/local-backup"]="755"
)

for path in "${!expected_perms[@]}"; do
    if [ -d "$path" ]; then
        actual=$(stat -c "%a" "$path")
        expected="${expected_perms[$path]}"
        if [ "$actual" = "$expected" ]; then
            echo -e "  ${GREEN}✓${NC} $path: $actual"
        else
            echo -e "  ${RED}✗${NC} $path: $actual (expected $expected)"
        fi
    fi
done

# Test write access
echo -e "\n  ${BLUE}Write Access Test:${NC}"
for user in "${users[@]}"; do
    test_dir="/var/lib/$user"
    test_file="$test_dir/.write_test_$$"
    
    if [ -d "$test_dir" ]; then
        if sudo -u "$user" touch "$test_file" 2>/dev/null; then
            rm -f "$test_file"
            echo -e "  ${GREEN}✓${NC} $user can write to $test_dir"
        else
            echo -e "  ${RED}✗${NC} $user cannot write to $test_dir"
        fi
    fi
done

echo -e "\n${GREEN}Fixes applied!${NC}"
echo -e "${YELLOW}Run the test script again to verify all issues are resolved:${NC}"
echo -e "  sudo /home/joohan/dev/project-jts/jts/specs/1000/1001/deliverables/scripts/test-database-mounts.sh"