# Database Mount Integration Setup Guide

Generated from: [Database Mount Integration](../../1012.md)  
Context: [Implementation Context](../../1012.context.md)  
Created: 2025-08-27  
Purpose: Comprehensive guide for setting up and managing database mount integration

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Detailed Setup](#detailed-setup)
5. [Architecture](#architecture)
6. [Security Model](#security-model)
7. [Troubleshooting](#troubleshooting)
8. [Maintenance](#maintenance)
9. [Reference](#reference)

## Overview

The Database Mount Integration provides a secure, high-performance storage foundation for the JTS trading system databases. This implementation bridges the hot storage infrastructure (NVMe SSDs) with database services through properly configured mount points, user accounts, and permissions.

### Key Features

- **Service Isolation**: Each database runs under its own system user with restricted access
- **Security-First Design**: Restrictive permissions (750) prevent unauthorized access
- **Operational Access**: Group-based model for backup and monitoring tools
- **Performance Optimized**: Mount options tuned for each database's I/O patterns
- **Production Ready**: Follows Linux FHS standards for compatibility

### Supported Databases

- PostgreSQL (Trading data, user accounts)
- ClickHouse (Time-series market data)
- Kafka (Message streaming)
- MongoDB (Configuration storage)
- Redis (Caching layer)

## Prerequisites

### Required Dependencies

```bash
# Check system requirements
uname -a  # Linux kernel 5.4+ recommended
free -h   # Minimum 16GB RAM recommended
df -h     # Ensure adequate disk space

# Install required packages (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y acl lvm2 e2fsprogs

# Install required packages (RHEL/CentOS)
sudo yum install -y acl lvm2 e2fsprogs
```

### Spec Dependencies

- **Spec 1011**: Hot Storage (NVMe) Foundation must be completed
  - LVM volume group `vg_jts` must exist
  - Logical volumes for each database must be created
  - Filesystems must be formatted (ext4 recommended)

### Verification

```bash
# Verify LVM setup
sudo vgdisplay vg_jts
sudo lvdisplay vg_jts

# Expected logical volumes:
# - vg_jts/lv_postgresql
# - vg_jts/lv_clickhouse
# - vg_jts/lv_kafka
# - vg_jts/lv_mongodb
# - vg_jts/lv_redis
# - vg_jts/lv_docker
```

## Quick Start

For a rapid deployment, run the setup scripts in order:

```bash
# Navigate to scripts directory
cd specs/1000/1001/deliverables/scripts/

# 1. Create database service users
sudo ./setup-database-users.sh

# 2. Create mount points and directory structure
sudo ./setup-mount-points.sh

# 3. Configure permissions and ACLs
sudo ./configure-permissions.sh

# 4. Validate the setup
sudo ./validate-database-mounts.sh
```

Expected output:
```
✅ All critical checks passed!
Database mount integration is properly configured.
```

## Detailed Setup

### Step 1: Create Service Users

The `setup-database-users.sh` script creates system users with secure configuration:

```bash
sudo ./setup-database-users.sh
```

This script:
- Creates system users (UID < 1000) for each database service
- Sets `/bin/false` as shell to prevent login
- Locks accounts to disable password authentication
- Creates operational groups (backup, monitoring, admin)
- Configures resource limits in `/etc/security/limits.d/`

**Manual equivalent:**
```bash
# Create service users
sudo useradd -r -s /bin/false -d /var/lib/postgresql -M postgres
sudo useradd -r -s /bin/false -d /var/lib/clickhouse -M clickhouse
sudo useradd -r -s /bin/false -d /var/lib/kafka -M kafka
sudo useradd -r -s /bin/false -d /var/lib/mongodb -M mongodb
sudo useradd -r -s /bin/false -d /var/lib/redis -M redis

# Lock accounts
sudo passwd -l postgres clickhouse kafka mongodb redis

# Create operational groups
sudo groupadd docker backup db-backup db-monitor db-admin
```

### Step 2: Create Mount Points

The `setup-mount-points.sh` script creates the directory structure:

```bash
sudo ./setup-mount-points.sh
```

This script:
- Creates mount point directories under `/var/lib/`
- Sets up subdirectory structure for each database
- Configures `/etc/fstab` entries with optimized mount options
- Mounts the filesystems

**Directory Structure Created:**
```
/var/lib/
├── postgresql/
│   ├── data/       # Database files
│   ├── logs/       # Log files
│   ├── config/     # Configuration
│   ├── backups/    # Local backups
│   └── wal/        # Write-ahead logs
├── clickhouse/
│   ├── data/       # Column storage
│   ├── logs/       # Query logs
│   ├── config/     # Server config
│   ├── tmp/        # Temporary files
│   └── user_files/ # User uploads
├── kafka/
│   ├── data/       # Log segments
│   ├── logs/       # Broker logs
│   ├── config/     # Broker config
│   └── scripts/    # Management scripts
├── mongodb/
│   ├── data/       # Document storage
│   ├── logs/       # Database logs
│   ├── config/     # Server config
│   └── journal/    # Write journal
├── redis/
│   ├── data/       # RDB/AOF files
│   ├── logs/       # Server logs
│   └── config/     # Redis config
└── docker-jts/
    ├── volumes/    # Container volumes
    ├── images/     # Docker images
    ├── containers/ # Container data
    └── tmp/        # Temporary files
```

### Step 3: Configure Permissions

The `configure-permissions.sh` script sets ownership and permissions:

```bash
sudo ./configure-permissions.sh
```

This script:
- Sets ownership to service users
- Applies restrictive 750 permissions
- Configures ACLs for operational access
- Verifies service isolation

**Permission Model:**
```bash
# Base permissions
drwxr-x--- postgres:postgres   /var/lib/postgresql
drwxr-x--- clickhouse:clickhouse /var/lib/clickhouse
drwxr-x--- kafka:kafka         /var/lib/kafka
drwxr-x--- mongodb:mongodb     /var/lib/mongodb
drwxr-x--- redis:redis         /var/lib/redis
drwxr-x--- root:docker         /var/lib/docker-jts
drwxr-xr-x root:backup         /data/local-backup

# ACL for operational access
setfacl -m g:db-backup:rx /var/lib/postgresql
setfacl -m g:db-monitor:rx /var/lib/postgresql
```

### Step 4: Validate Setup

The `validate-database-mounts.sh` script performs comprehensive validation:

```bash
sudo ./validate-database-mounts.sh
```

Validation checks:
- ✓ Service users exist with correct properties
- ✓ Operational groups are created
- ✓ Mount directories exist with proper ownership
- ✓ Permissions are correctly set
- ✓ Filesystems are mounted
- ✓ Service isolation is enforced
- ✓ Write access works for each service
- ✓ ACLs are properly configured

## Architecture

### Storage Layer Stack

```
┌─────────────────────────────────────┐
│     Database Services Layer         │
│  (PostgreSQL, ClickHouse, Kafka,    │
│   MongoDB, Redis, Docker)           │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│    Mount Integration Layer          │
│  (This Spec - Mount Points,         │
│   Permissions, Service Users)       │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│     Filesystem Layer (ext4)         │
│  (Formatted with optimal options)   │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│      LVM Layer (vg_jts)            │
│  (Logical Volume Management)        │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│    Physical Storage (NVMe SSD)      │
│  (High-performance hardware)        │
└─────────────────────────────────────┘
```

### Mount Options Optimization

Each database has mount options tuned for its I/O patterns:

| Database | Mount Options | Rationale |
|----------|--------------|-----------|
| PostgreSQL | `noatime,nodiratime,rw,relatime` | Write-heavy with transaction logging |
| ClickHouse | `noatime,nodiratime,rw,largeio` | Large sequential reads for analytics |
| Kafka | `noatime,nodiratime,rw,largeio` | Sequential writes for log segments |
| MongoDB | `noatime,nodiratime,rw,relatime` | Mixed workload with documents |
| Redis | `noatime,nodiratime,rw,relatime` | Small files with frequent updates |

## Security Model

### Defense in Depth

The implementation uses multiple security layers:

1. **User Isolation**
   - System users with nologin shells
   - Locked accounts (no password auth)
   - Unique UID/GID per service

2. **Filesystem Permissions**
   - Restrictive 750 on service directories
   - 700 on sensitive data directories
   - No world-readable permissions

3. **Access Control Lists (ACLs)**
   - Fine-grained permissions for operations
   - Read-only access for backup groups
   - Monitoring access without write permissions

4. **Service Isolation Verification**
   ```bash
   # Test that postgres cannot access clickhouse data
   sudo -u postgres test -r /var/lib/clickhouse/
   # Expected: Permission denied
   ```

### Operational Access Model

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   db-admin   │     │  db-backup   │     │ db-monitor   │
│   (rw access)│     │  (r access)  │     │  (r access)  │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                     │
       └────────────────────┼─────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   ACL Rules  │
                    └──────┬───────┘
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
┌──────▼──────┐     ┌──────▼──────┐    ┌──────▼──────┐
│ PostgreSQL  │     │ ClickHouse  │    │    Kafka    │
└─────────────┘     └─────────────┘    └─────────────┘
```

## Troubleshooting

### Common Issues

#### Issue: User creation fails
```bash
# Error: useradd: user 'postgres' already exists
# Solution: User already exists, verify properties:
id postgres
getent passwd postgres
```

#### Issue: Mount point not accessible
```bash
# Error: Permission denied when accessing mount point
# Solution: Check ownership and permissions:
ls -ld /var/lib/postgresql
stat /var/lib/postgresql

# Fix permissions:
sudo chown postgres:postgres /var/lib/postgresql
sudo chmod 750 /var/lib/postgresql
```

#### Issue: Cannot write to database directory
```bash
# Test write access:
sudo -u postgres touch /var/lib/postgresql/test
# If fails, check:
# 1. Mount status
df -h /var/lib/postgresql
# 2. Filesystem errors
sudo dmesg | tail -20
# 3. SELinux/AppArmor
getenforce  # For SELinux
aa-status   # For AppArmor
```

#### Issue: LVM volumes not found
```bash
# Check volume group:
sudo vgdisplay vg_jts
# If missing, spec 1011 needs to be completed first

# Check logical volumes:
sudo lvdisplay | grep "LV Name"
# Create missing volumes if needed (from spec 1011)
```

### Validation Commands

```bash
# Quick health check
for user in postgres clickhouse kafka mongodb redis; do
    echo -n "$user: "
    id $user &>/dev/null && echo "✓" || echo "✗"
done

# Check mounts
mount | grep vg_jts

# Test write access (as root)
for user in postgres clickhouse kafka mongodb redis; do
    dir="/var/lib/${user/postgres/postgresql}"
    echo -n "$user -> $dir: "
    sudo -u $user touch "$dir/test" 2>/dev/null && \
        sudo -u $user rm "$dir/test" && echo "✓" || echo "✗"
done

# Check ACLs
for dir in /var/lib/postgresql /var/lib/clickhouse /var/lib/kafka; do
    echo "$dir:"
    getfacl -p $dir 2>/dev/null | grep "group:"
done
```

## Maintenance

### Regular Tasks

#### Weekly Validation
```bash
# Run validation script weekly
sudo /path/to/validate-database-mounts.sh

# Check disk usage
df -h | grep vg_jts

# Review system logs
journalctl -u postgresql -n 50
journalctl -xe | grep -E "(postgres|clickhouse|kafka|mongodb|redis)"
```

#### Monthly Reviews
```bash
# Check for permission drift
find /var/lib/postgresql -type d -not -perm 750 -ls
find /var/lib/postgresql -type f -not -perm 640 -ls

# Verify user properties haven't changed
for user in postgres clickhouse kafka mongodb redis; do
    passwd -S $user
done

# Review ACLs for changes
for dir in /var/lib/{postgresql,clickhouse,kafka,mongodb,redis}; do
    getfacl $dir > /tmp/acl_backup_$(basename $dir).txt
done
```

### Backup Procedures

```bash
# Backup mount configuration
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d)

# Backup ACLs
getfacl -R /var/lib/{postgresql,clickhouse,kafka,mongodb,redis} > \
    /backup/acls_$(date +%Y%m%d).txt

# Restore ACLs if needed
setfacl --restore=/backup/acls_20250827.txt
```

### Adding New Database Services

To add a new database service:

1. Create service user:
```bash
sudo useradd -r -s /bin/false -d /var/lib/newdb -M newdb
sudo passwd -l newdb
```

2. Create mount point:
```bash
sudo mkdir -p /var/lib/newdb/{data,logs,config}
sudo chown -R newdb:newdb /var/lib/newdb
sudo chmod 750 /var/lib/newdb
```

3. Configure ACLs:
```bash
sudo setfacl -m g:db-backup:rx /var/lib/newdb
sudo setfacl -m g:db-monitor:rx /var/lib/newdb
```

4. Update validation script to include new service

## Reference

### File Locations

| File | Purpose |
|------|---------|
| `/etc/fstab` | Mount configuration |
| `/etc/security/limits.d/90-database-users.conf` | Resource limits |
| `/var/log/syslog` | System logs |
| `/var/lib/{service}/` | Database mount points |

### Related Documentation

- [Spec 1011: Hot Storage Foundation](../1011.md)
- [Spec 1002: Database Services](../../1002.md)
- [Linux Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.html)

### Script Reference

| Script | Purpose | Run As |
|--------|---------|--------|
| `setup-database-users.sh` | Create service users and groups | root |
| `setup-mount-points.sh` | Create mount directories and configure fstab | root |
| `configure-permissions.sh` | Set ownership, permissions, and ACLs | root |
| `validate-database-mounts.sh` | Comprehensive validation of setup | root |

### Support

For issues or questions:
1. Check validation script output
2. Review troubleshooting section
3. Consult system logs
4. Reference parent spec documentation

---

*This document is part of the JTS Infrastructure Implementation*  
*Last Updated: 2025-08-27*