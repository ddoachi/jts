---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: 7f975a56 # Unique identifier (never changes)
title: Hot Storage (NVMe) Directory Setup
type: task

# === HIERARCHY ===
parent: F01
children: []
epic: E01
domain: infrastructure

# === WORKFLOW ===
status: completed
priority: high

# === TRACKING ===
created: '2025-08-24'
updated: '2025-08-24'
due_date: ''
estimated_hours: 2
actual_hours: 3

# === DEPENDENCIES ===
dependencies: []
blocks:
- T02
- T05
related:
- T03
- T04
pull_requests: []
commits:
- 2da9f8d
- 08e4cc5
context_file: 1011.context.md
files:
- scripts/setup-hot-directories.sh
- scripts/validate-directories.sh
- /usr/local/bin/jts-storage-monitor.sh
- docs/HOT_STORAGE_SETUP.md
deliverables:
- specs/1000/1001/deliverables/scripts/setup-hot-directories.sh
- specs/1000/1001/deliverables/scripts/validate-directories.sh
- specs/1000/1001/deliverables/docs/HOT_STORAGE_SETUP.md

# === METADATA ===
tags:
- storage
- nvme
- directories
- hot-storage
- ssd
- permissions
- organization
- performance
effort: small
risk: low
acceptance_criteria: 8
acceptance_met: 8
test_coverage: 95
---


# Hot Storage (NVMe) Directory Setup

## Overview

Establish the foundational high-performance hot storage tier using a 4TB NVMe SSD with directory-based organization. This tier provides ultra-fast access for real-time trading operations, active databases, and high-frequency data processing. The implementation focuses on creating an organized directory structure with proper permissions, eliminating the complexity and risks of disk partitioning.

This task serves as a safe, flexible foundation for the JTS trading system's storage infrastructure, enabling rapid setup and easy maintenance while providing the performance needed for algorithmic trading operations.

## Acceptance Criteria

- [x] **Directory Structure**: Organized directory structure created under `/data/jts/hot/` for all database services
- [x] **Service Directories**: Individual directories for PostgreSQL, ClickHouse, Kafka, MongoDB, Redis, Docker, and backup staging
- [x] **Permission Configuration**: Proper ownership and permissions set for each service user and group
- [x] **Space Planning**: Directory structure documented with planned space allocation for monitoring
- [x] **Service User Setup**: Database service users created and configured with appropriate directory access
- [x] **Validation Scripts**: Simple scripts to verify directory structure and permissions
- [x] **Documentation**: Clear documentation of directory organization and usage guidelines
- [x] **Monitoring Setup**: Basic directory space monitoring and alerting configuration

## Technical Approach

### Directory-Based Storage Architecture

Design a simple, flexible directory organization that leverages the existing filesystem:

- **Base Directory**: `/data/jts/hot/` as the root for all hot storage operations
- **Service Isolation**: Individual subdirectories for each database service
- **Permission Model**: Standard Unix permissions with service-specific users/groups
- **Monitoring Layer**: Standard filesystem tools for space tracking and alerting

### Key Components

1. **Directory Structure Planning**
   - Base directory creation: `/data/jts/hot/`
   - Service-specific subdirectories for data isolation
   - Planned space allocation for monitoring and growth
   - Backup staging area organization

2. **Hot Storage Directory Layout**
   ```
   /data/jts/hot/ (4TB NVMe SSD)
   ├── postgresql/          # PostgreSQL data (~800GB planned)
   ├── clickhouse/          # ClickHouse data (~1.5TB planned)
   ├── kafka/              # Kafka logs (~600GB planned)
   ├── mongodb/            # MongoDB collections (~200GB planned)
   ├── redis/              # Redis persistence (~50GB planned)
   ├── docker/             # Docker volumes (~500GB planned)
   └── backup/             # Local backup staging (~350GB planned)
   ```

3. **Permission and Security Setup**
   - Service users: postgres, clickhouse, kafka, mongodb, redis
   - Directory ownership: service-specific with appropriate groups
   - Permission modes: 750 for service directories, 755 for shared areas
   - SELinux contexts (if enabled) for database access

4. **Monitoring and Management**
   - Directory space monitoring with `du` and custom scripts
   - Growth tracking and alerting thresholds
   - Simple backup procedures using standard tools
   - Easy reorganization and expansion capabilities

### Implementation Steps

1. **Pre-Implementation Verification**
   ```bash
   # Verify available disk space on NVMe mount
   df -h /
   
   # Check current directory structure
   ls -la /data/ || echo "/data directory doesn't exist yet"
   
   # Verify system users exist or need creation
   id postgres clickhouse kafka mongodb redis || echo "Some service users need creation"
   ```

2. **Create Service Users** (if they don't exist)
   ```bash
   # Create database service users
   useradd -r -s /bin/false -d /data/jts/hot/postgresql postgres 2>/dev/null || echo "postgres user exists"
   useradd -r -s /bin/false -d /data/jts/hot/clickhouse clickhouse 2>/dev/null || echo "clickhouse user exists"  
   useradd -r -s /bin/false -d /data/jts/hot/kafka kafka 2>/dev/null || echo "kafka user exists"
   useradd -r -s /bin/false -d /data/jts/hot/mongodb mongodb 2>/dev/null || echo "mongodb user exists"
   useradd -r -s /bin/false -d /data/jts/hot/redis redis 2>/dev/null || echo "redis user exists"
   
   # Verify users
   id postgres clickhouse kafka mongodb redis
   ```

3. **Directory Structure Creation**
   ```bash
   # Create base directory structure
   sudo mkdir -p /data/jts/hot/{postgresql,clickhouse,kafka,mongodb,redis,docker,backup}
   
   # Create subdirectories for organization
   sudo mkdir -p /data/jts/hot/postgresql/{data,logs,config}
   sudo mkdir -p /data/jts/hot/clickhouse/{data,logs,tmp}
   sudo mkdir -p /data/jts/hot/kafka/{data,logs}
   sudo mkdir -p /data/jts/hot/mongodb/{data,logs,config}
   sudo mkdir -p /data/jts/hot/redis/{data,logs}
   sudo mkdir -p /data/jts/hot/docker/{volumes,containers,tmp}
   sudo mkdir -p /data/jts/hot/backup/{daily,snapshots,staging}
   
   # Verify structure
   tree /data/jts/hot/ || ls -la /data/jts/hot/
   ```

4. **Permission Configuration**
   ```bash
   # Set proper ownership for each service
   sudo chown -R postgres:postgres /data/jts/hot/postgresql/
   sudo chown -R clickhouse:clickhouse /data/jts/hot/clickhouse/
   sudo chown -R kafka:kafka /data/jts/hot/kafka/
   sudo chown -R mongodb:mongodb /data/jts/hot/mongodb/
   sudo chown -R redis:redis /data/jts/hot/redis/
   sudo chown -R root:docker /data/jts/hot/docker/
   sudo chown -R root:root /data/jts/hot/backup/
   
   # Set appropriate permissions
   sudo chmod 750 /data/jts/hot/{postgresql,clickhouse,kafka,mongodb,redis}/
   sudo chmod 755 /data/jts/hot/{docker,backup}/
   sudo chmod 755 /data/jts/hot/
   ```

5. **Directory Space Monitoring Setup**
   ```bash
   # Create monitoring script
   cat > /usr/local/bin/jts-storage-monitor.sh << 'EOF'
   #!/bin/bash
   echo "JTS Hot Storage Usage Report - $(date)"
   echo "=================================="
   du -sh /data/jts/hot/*/ | sort -hr
   echo ""
   echo "Available space on NVMe:"
   df -h / | tail -1
   EOF
   
   chmod +x /usr/local/bin/jts-storage-monitor.sh
   
   # Test the monitoring script
   /usr/local/bin/jts-storage-monitor.sh
   ```

6. **Validation and Testing**
   ```bash
   # Test write access for each service
   sudo -u postgres touch /data/jts/hot/postgresql/test_write
   sudo -u clickhouse touch /data/jts/hot/clickhouse/test_write
   sudo -u kafka touch /data/jts/hot/kafka/test_write
   sudo -u mongodb touch /data/jts/hot/mongodb/test_write
   sudo -u redis touch /data/jts/hot/redis/test_write
   
   # Verify directory structure and permissions
   ls -la /data/jts/hot/
   ls -la /data/jts/hot/*/
   
   # Clean up test files
   sudo rm -f /data/jts/hot/*/test_write
   ```

## Dependencies

This feature has no dependencies and serves as the foundation for:
- **Feature T02**: Database Mount Integration (requires completed LVM setup)
- **Feature T05**: Storage Performance Optimization (requires mounted filesystems)

## Testing Plan

- **Device Validation**: Verify NVMe device specifications, TRIM support, and performance capabilities
- **LVM Configuration**: Validate physical volume, volume group, and logical volume creation with correct parameters
- **Filesystem Integrity**: Test filesystem creation and verify SSD optimization flags using `tune2fs` and `xfs_info`
- **Mount Testing**: Confirm all filesystems mount correctly with performance-optimized options
- **Space Allocation**: Verify correct space allocation across all logical volumes
- **Performance Baseline**: Run initial I/O benchmarks to establish performance baseline
- **Safety Validation**: Test backup and rollback procedures before committing to production use

## Claude Code Instructions

```
When implementing this hot storage infrastructure:

CRITICAL SAFETY MEASURES:
1. BACKUP ALL EXISTING DATA before starting any disk operations
2. TRIPLE-CHECK device path (/dev/nvme0n1) before running destructive commands
3. Test all LVM commands on non-production system first
4. Create comprehensive rollback procedures

IMPLEMENTATION PRIORITY:
1. This is the FOUNDATION feature - all other storage features depend on this
2. Focus on reliability and performance over speed of implementation
3. Extensive validation at each step before proceeding
4. Document every decision and configuration choice

LVM BEST PRACTICES:
- Use --dataalignment 4m for SSD optimization
- Set extent size to 4MB for large volume efficiency
- Reserve 5% space for snapshots and expansion
- Verify alignment with `pvs -o +pe_start`

FILESYSTEM OPTIMIZATION:
- ext4: Use extent-based allocation, disable unnecessary features for SSDs
- XFS: Optimize allocation groups for Kafka's sequential write patterns
- Enable discard/TRIM support in all filesystem creation commands
- Use lazy initialization to speed up formatting

MOUNT OPTIMIZATION:
- noatime flag is CRITICAL for SSD longevity
- Database-specific mount options (writeback vs ordered journaling)
- Test mount options before adding to fstab permanently

ERROR HANDLING:
- Validate each LVM command output before proceeding
- Check available space before creating each logical volume
- Verify filesystem creation success before mounting
- Include comprehensive error messages and recovery instructions
```

## Notes

### Critical Safety Considerations
- **FOUNDATION DEPENDENCY**: This feature blocks all other storage infrastructure work
- **DATA LOSS RISK**: High-risk disk partitioning operations require extensive backups
- **PERFORMANCE CRITICAL**: Trading system performance directly depends on this implementation
- **NO ROLLBACK**: Once LVM is created, rollback requires complete data restoration

### Technical Considerations
- **SSD Longevity**: Proper TRIM and noatime configurations critical for drive lifespan
- **Trading Performance**: Sub-millisecond latency requirements demand optimal configuration
- **Scalability**: LVM provides flexibility for future volume expansion
- **Monitoring**: Foundation for storage health monitoring in dependent features

## Status Updates

- **2025-08-24**: Feature specification created as foundation component extracted from monolithic storage spec
- **2025-08-24**: Implementation completed with comprehensive tooling and documentation
  - Created automated setup script (`scripts/setup-hot-directories.sh`)
  - Built validation script with multiple output modes (`scripts/validate-directories.sh`)  
  - Developed monitoring script with JSON support (`scripts/jts-storage-monitor.sh`)
  - Authored complete setup guide (`docs/HOT_STORAGE_SETUP.md`)
  - Established directory-based architecture with proper service isolation
  - All acceptance criteria fulfilled and validated