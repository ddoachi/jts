---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '1001' # Numeric ID for stable reference
title: 'Storage Infrastructure Setup'
type: 'feature' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '1000' # Parent spec ID
children: [] # Child spec IDs (if any)
epic: '1000' # Root epic ID for this work
domain: 'infrastructure' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low
assignee: '' # Who's working on this
reviewer: '' # Who should review (optional)

# === TRACKING ===
created: '2025-08-24' # YYYY-MM-DD
updated: '2025-08-24' # YYYY-MM-DD
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 16 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: [] # Must be done before this (spec IDs)
blocks: ['1002', '1004', '1005'] # This blocks these specs (spec IDs)
related: ['1006', '1008'] # Related but not blocking (spec IDs)

# === IMPLEMENTATION ===
branch: 'feature/1001-storage-infrastructure' # Git branch name
worktree: '' # Worktree path (optional)
files: ['/etc/fstab', 'scripts/setup-lvm.sh', 'scripts/storage-health.sh', 'scripts/lvm-backup.sh', 'docs/STORAGE_SETUP.md'] # Key files to modify

# === METADATA ===
tags: ['storage', 'lvm', 'ssd', 'filesystem', 'performance', 'ext4', 'xfs'] # Searchable tags
effort: 'large' # small | medium | large | epic
risk: 'high' # low | medium | high

# ============================================================================
---

# Storage Infrastructure Setup

## Overview

Establish a high-performance storage infrastructure using Logical Volume Manager (LVM) on a 4TB NVMe SSD to provide optimized storage for the JTS trading system. This includes LVM configuration, partition setup for each database system, filesystem optimization with ext4 and XFS, mount point configuration, and performance tuning parameters specifically designed for trading system workloads.

## Acceptance Criteria

- [ ] **LVM Configuration**: Complete 4TB SSD setup with physical volume, volume group, and logical volumes
- [ ] **Partition Allocation**: Proper space allocation (2TB ClickHouse, 800GB PostgreSQL, 600GB Kafka, 200GB MongoDB, 50GB Redis, 350GB system/backup)
- [ ] **Filesystem Optimization**: Optimized filesystems (ext4 for databases, XFS for Kafka) with SSD-specific parameters
- [ ] **Mount Point Configuration**: Automated mounting with performance-optimized options in `/etc/fstab`
- [ ] **Performance Tuning**: SSD-specific optimizations including noatime, TRIM support, and I/O schedulers
- [ ] **Directory Structure**: Proper directory creation with correct ownership and permissions for all database systems
- [ ] **Backup Volume**: Dedicated backup logical volume with LVM snapshot capabilities
- [ ] **Management Scripts**: Automated scripts for LVM snapshot creation, health monitoring, and maintenance
- [ ] **Performance Validation**: I/O performance testing and validation for each database workload
- [ ] **Documentation**: Complete storage setup, maintenance, and disaster recovery documentation

## Technical Approach

### LVM Storage Architecture

Design a flexible and high-performance storage architecture using LVM2 that provides:
- **Scalability**: Easy expansion when additional storage is needed
- **Performance**: SSD-optimized filesystems and mount options for each database type
- **Reliability**: LVM snapshots for consistent backups and disaster recovery
- **Monitoring**: Health checks and capacity monitoring for proactive maintenance

### Key Components

1. **Physical Volume Setup**
   - Single 4TB NVMe SSD configured as LVM physical volume
   - Proper alignment for SSD optimization
   - TRIM support configuration for SSD longevity

2. **Volume Group Management**
   - Single volume group `vg_jts` spanning the entire SSD
   - Optimal extent size for performance (4MB for large volumes)
   - Reserved space for snapshots and future expansion

3. **Logical Volume Layout**
   ```
   vg_jts (4TB total)
   ├── lv_system (200GB)      # OS and Docker containers
   ├── lv_postgres (800GB)    # PostgreSQL data with ext4
   ├── lv_clickhouse (2TB)    # ClickHouse time-series data with ext4
   ├── lv_kafka (600GB)       # Kafka logs with XFS
   ├── lv_mongodb (200GB)     # MongoDB documents with ext4
   ├── lv_redis (50GB)        # Redis persistence with ext4
   └── lv_backup (150GB)      # Local backups and snapshots
   ```

4. **Filesystem Optimization Strategy**
   - **ext4**: For PostgreSQL, ClickHouse, MongoDB, Redis with journal optimizations
   - **XFS**: For Kafka with optimized allocation groups and log buffers
   - **SSD Optimizations**: noatime, discard support, optimal stripe alignment

### Implementation Steps

1. **Pre-Implementation Validation**
   ```bash
   # Verify SSD device and capabilities
   lsblk -d -o name,size,model,tran,rota /dev/nvme0n1
   
   # Check TRIM/discard support
   lsblk -D /dev/nvme0n1
   
   # Verify no existing partitions
   fdisk -l /dev/nvme0n1
   
   # Check available space
   df -h
   ```

2. **Initialize LVM Infrastructure**
   ```bash
   # Install LVM tools if not present
   apt-get update && apt-get install -y lvm2
   
   # Create physical volume with optimal alignment
   pvcreate --dataalignment 4m /dev/nvme0n1
   
   # Create volume group with 4MB extent size
   vgcreate -s 4m vg_jts /dev/nvme0n1
   
   # Verify configuration
   pvdisplay /dev/nvme0n1
   vgdisplay vg_jts
   ```

3. **Create Logical Volumes**
   ```bash
   # Create logical volumes with optimal sizing
   lvcreate -L 200G -n lv_system vg_jts
   lvcreate -L 800G -n lv_postgres vg_jts
   lvcreate -L 2000G -n lv_clickhouse vg_jts
   lvcreate -L 600G -n lv_kafka vg_jts
   lvcreate -L 200G -n lv_mongodb vg_jts
   lvcreate -L 50G -n lv_redis vg_jts
   lvcreate -L 150G -n lv_backup vg_jts
   
   # Verify logical volume creation
   lvdisplay vg_jts
   lsblk | grep vg_jts
   ```

4. **Format Filesystems with Optimization**
   ```bash
   # PostgreSQL - ext4 with SSD optimizations
   mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard \
     -O ^has_journal,extent,flex_bg,sparse_super2 \
     /dev/vg_jts/lv_postgres
   
   # ClickHouse - ext4 with ordered journaling for consistency
   mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard \
     -O extent,flex_bg,sparse_super2 \
     /dev/vg_jts/lv_clickhouse
   
   # Kafka - XFS with optimized allocation groups
   mkfs.xfs -f -d agcount=32,su=64k,sw=1 \
     -l size=128m,su=64k \
     /dev/vg_jts/lv_kafka
   
   # MongoDB - ext4 with default journaling
   mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard \
     /dev/vg_jts/lv_mongodb
   
   # Redis - ext4 with writeback journaling for performance
   mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard \
     -O ^has_journal,extent,flex_bg \
     /dev/vg_jts/lv_redis
   
   # Backup - ext4 with standard configuration
   mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard \
     /dev/vg_jts/lv_backup
   ```

5. **Create Mount Points and Set Ownership**
   ```bash
   # Create mount directories
   mkdir -p /var/lib/postgresql /var/lib/clickhouse /var/lib/kafka
   mkdir -p /var/lib/mongodb /var/lib/redis /backup
   
   # Create service users if they don't exist
   useradd -r -s /bin/false -d /var/lib/postgresql postgres || true
   useradd -r -s /bin/false -d /var/lib/clickhouse clickhouse || true
   useradd -r -s /bin/false -d /var/lib/kafka kafka || true
   useradd -r -s /bin/false -d /var/lib/mongodb mongodb || true
   useradd -r -s /bin/false -d /var/lib/redis redis || true
   
   # Set proper ownership
   chown postgres:postgres /var/lib/postgresql
   chown clickhouse:clickhouse /var/lib/clickhouse
   chown kafka:kafka /var/lib/kafka
   chown mongodb:mongodb /var/lib/mongodb
   chown redis:redis /var/lib/redis
   chown root:backup /backup
   
   # Set secure permissions
   chmod 750 /var/lib/postgresql /var/lib/clickhouse /var/lib/kafka
   chmod 750 /var/lib/mongodb /var/lib/redis
   chmod 755 /backup
   ```

6. **Configure Optimized Mount Options**
   ```bash
   # Backup existing fstab
   cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
   
   # Add optimized mount entries
   cat >> /etc/fstab << 'EOF'
   
   # JTS Trading System - High-Performance Storage Configuration
   # PostgreSQL - ext4 with writeback journaling for performance
   /dev/vg_jts/lv_postgres   /var/lib/postgresql  ext4  defaults,noatime,data=writeback,barrier=0,commit=30  0 2
   
   # ClickHouse - ext4 with ordered journaling for consistency
   /dev/vg_jts/lv_clickhouse /var/lib/clickhouse  ext4  defaults,noatime,data=ordered,commit=5              0 2
   
   # Kafka - XFS with optimized sequential I/O
   /dev/vg_jts/lv_kafka      /var/lib/kafka       xfs   defaults,noatime,nobarrier,logbufs=8,logbsize=256k,largeio,swalloc  0 2
   
   # MongoDB - ext4 with standard journaling
   /dev/vg_jts/lv_mongodb    /var/lib/mongodb     ext4  defaults,noatime,commit=10                          0 2
   
   # Redis - ext4 with writeback for memory-backed operations
   /dev/vg_jts/lv_redis      /var/lib/redis       ext4  defaults,noatime,data=writeback,barrier=0          0 2
   
   # Backup - ext4 with standard configuration
   /dev/vg_jts/lv_backup     /backup              ext4  defaults,nodev,nosuid                              0 2
   EOF
   ```

7. **Mount All Filesystems**
   ```bash
   # Test mount configuration
   mount -a
   
   # Verify all mounts
   df -h | grep -E "(postgres|clickhouse|kafka|mongodb|redis|backup)"
   
   # Check mount options
   mount | grep -E "vg_jts"
   ```

8. **Create Management and Monitoring Scripts**
   ```bash
   # scripts/setup-lvm.sh - Complete LVM setup script
   cat > scripts/setup-lvm.sh << 'EOF'
   #!/bin/bash
   set -euo pipefail
   
   DEVICE="/dev/nvme0n1"
   VG_NAME="vg_jts"
   
   echo "🚀 Starting JTS Storage Infrastructure Setup"
   
   # Validation checks
   if [[ ! -b "$DEVICE" ]]; then
       echo "❌ Device $DEVICE not found"
       exit 1
   fi
   
   # Create LVM structure
   echo "📦 Creating LVM structure on $DEVICE"
   pvcreate --dataalignment 4m "$DEVICE"
   vgcreate -s 4m "$VG_NAME" "$DEVICE"
   
   # Create logical volumes
   echo "💾 Creating logical volumes"
   lvcreate -L 200G -n lv_system "$VG_NAME"
   lvcreate -L 800G -n lv_postgres "$VG_NAME"
   lvcreate -L 2000G -n lv_clickhouse "$VG_NAME"
   lvcreate -L 600G -n lv_kafka "$VG_NAME"
   lvcreate -L 200G -n lv_mongodb "$VG_NAME"
   lvcreate -L 50G -n lv_redis "$VG_NAME"
   lvcreate -L 150G -n lv_backup "$VG_NAME"
   
   echo "✅ LVM setup completed successfully"
   EOF
   
   # scripts/storage-health.sh - Storage monitoring script
   cat > scripts/storage-health.sh << 'EOF'
   #!/bin/bash
   
   echo "🔍 JTS Storage Health Check - $(date)"
   echo "======================================"
   
   # Check volume group health
   echo "📊 Volume Group Status:"
   vgdisplay vg_jts | grep -E "(VG Name|VG Status|VG Size|Free)"
   
   # Check logical volume usage
   echo -e "\n💾 Logical Volume Usage:"
   df -h | grep -E "(Filesystem|vg_jts)" | column -t
   
   # Alert on high usage (>80%)
   echo -e "\n⚠️  Usage Alerts:"
   df -h | grep vg_jts | awk '{
       gsub(/%/, "", $5);
       if ($5 > 80) {
           print "WARNING: " $6 " usage at " $5 "%"
       } else if ($5 > 90) {
           print "CRITICAL: " $6 " usage at " $5 "%"
       }
   }'
   
   # Check I/O performance
   echo -e "\n⚡ I/O Statistics:"
   iostat -x 1 1 | grep nvme0n1 | tail -1
   EOF
   
   # scripts/lvm-backup.sh - LVM snapshot management
   cat > scripts/lvm-backup.sh << 'EOF'
   #!/bin/bash
   
   DATE=$(date +%Y%m%d_%H%M%S)
   VG_NAME="vg_jts"
   
   create_snapshots() {
       echo "📸 Creating LVM snapshots - $DATE"
       
       # Create snapshots for critical data
       lvcreate -L5G -s -n snap_postgres_$DATE /dev/$VG_NAME/lv_postgres
       lvcreate -L10G -s -n snap_clickhouse_$DATE /dev/$VG_NAME/lv_clickhouse
       lvcreate -L2G -s -n snap_mongodb_$DATE /dev/$VG_NAME/lv_mongodb
       
       echo "✅ Snapshots created successfully"
   }
   
   cleanup_old_snapshots() {
       echo "🧹 Cleaning up snapshots older than 7 days"
       
       # Find and remove old snapshots
       lvs --noheadings -o lv_name $VG_NAME | grep "^  snap_" | while read snapshot; do
           snapshot=$(echo $snapshot | xargs)  # trim whitespace
           creation_date=$(lvs --noheadings -o lv_time /dev/$VG_NAME/$snapshot | xargs)
           
           # Remove snapshots older than 7 days
           if [[ $(date -d "$creation_date" +%s) -lt $(date -d "7 days ago" +%s) ]]; then
               echo "Removing old snapshot: $snapshot"
               lvremove -f /dev/$VG_NAME/$snapshot
           fi
       done
   }
   
   case "${1:-create}" in
       create)
           create_snapshots
           ;;
       cleanup)
           cleanup_old_snapshots
           ;;
       *)
           echo "Usage: $0 {create|cleanup}"
           exit 1
           ;;
   esac
   EOF
   
   # Make scripts executable
   chmod +x scripts/setup-lvm.sh scripts/storage-health.sh scripts/lvm-backup.sh
   ```

9. **Configure System Optimizations**
   ```bash
   # Configure SSD I/O scheduler
   echo 'ACTION=="add|change", KERNEL=="nvme0n1", ATTR{queue/scheduler}="none"' > /etc/udev/rules.d/60-ssd-scheduler.rules
   
   # Enable TRIM support
   echo 'ACTION=="add|change", KERNEL=="nvme0n1", ATTR{queue/discard_max_bytes}!="0", RUN+="/sbin/fstrim -v /"' >> /etc/udev/rules.d/60-ssd-scheduler.rules
   
   # Configure automatic TRIM
   cat > /etc/systemd/system/fstrim-all.service << 'EOF'
   [Unit]
   Description=Discard unused filesystem blocks on all mounted filesystems
   
   [Service]
   Type=oneshot
   ExecStart=/bin/bash -c 'for mount in /var/lib/postgresql /var/lib/clickhouse /var/lib/kafka /var/lib/mongodb /var/lib/redis; do /sbin/fstrim -v "$mount"; done'
   EOF
   
   cat > /etc/systemd/system/fstrim-all.timer << 'EOF'
   [Unit]
   Description=Run fstrim weekly
   
   [Timer]
   OnCalendar=weekly
   Persistent=true
   
   [Install]
   WantedBy=timers.target
   EOF
   
   # Enable TRIM timer
   systemctl enable fstrim-all.timer
   systemctl start fstrim-all.timer
   ```

10. **Performance Validation and Testing**
    ```bash
    # scripts/performance-test.sh
    cat > scripts/performance-test.sh << 'EOF'
    #!/bin/bash
    
    echo "🚀 JTS Storage Performance Testing"
    echo "=================================="
    
    test_sequential_write() {
        local mount_point=$1
        local test_file="$mount_point/perf_test_seq_write"
        
        echo "Testing sequential write on $mount_point"
        dd if=/dev/zero of="$test_file" bs=1M count=1000 oflag=direct 2>&1 | tail -1
        rm -f "$test_file"
    }
    
    test_random_iops() {
        local mount_point=$1
        local test_file="$mount_point/perf_test_random"
        
        echo "Testing random IOPS on $mount_point"
        fio --name=random_test --ioengine=libaio --iodepth=32 --rw=randread --bs=4k \
            --direct=1 --size=500M --numjobs=1 --runtime=30 --group_reporting \
            --filename="$test_file" | grep -E "(read|IOPS)"
        rm -f "$test_file"
    }
    
    # Test each mount point
    for mount in /var/lib/postgresql /var/lib/clickhouse /var/lib/kafka; do
        echo -e "\n📊 Testing $mount"
        test_sequential_write "$mount"
        test_random_iops "$mount"
    done
    EOF
    
    chmod +x scripts/performance-test.sh
    ```

## Dependencies

This feature forms part of the foundation infrastructure and has no technical dependencies, but should be implemented early in the infrastructure setup process before database services are deployed.

## Testing Plan

- **LVM Configuration Validation**: Verify all logical volumes are created with correct sizes and properties using `lvdisplay` and `vgdisplay`
- **Filesystem Integrity**: Test filesystem creation and verify optimal parameters using `tune2fs` for ext4 and `xfs_info` for XFS
- **Mount Point Testing**: Confirm all filesystems mount correctly with specified options using `mount` and `/proc/mounts`
- **Performance Benchmarking**: Run I/O performance tests using `fio` and `dd` to validate SSD optimization
- **Ownership and Permissions**: Verify correct ownership and permissions for all database directories
- **Snapshot Functionality**: Test LVM snapshot creation, mounting, and cleanup processes
- **Health Monitoring**: Validate storage health check scripts and monitoring functionality
- **Disaster Recovery**: Test volume expansion and snapshot restoration procedures
- **TRIM Support**: Verify SSD TRIM/discard functionality is working correctly

## Claude Code Instructions

```
When implementing this storage infrastructure:

CRITICAL SAFETY MEASURES:
1. BACKUP ALL EXISTING DATA before starting any disk operations
2. Verify the correct device path (/dev/nvme0n1) before running any commands
3. Test all commands on a non-production system first
4. Create comprehensive rollback procedures

IMPLEMENTATION STEPS:
1. Validate SSD device and check for existing partitions/data
2. Create LVM structure with proper alignment (--dataalignment 4m)
3. Use exact filesystem creation commands with optimization flags
4. Set up mount points with correct ownership and permissions
5. Configure /etc/fstab with performance-optimized mount options
6. Create and test all management scripts (setup, health check, backup)
7. Implement SSD-specific optimizations (I/O scheduler, TRIM support)
8. Set up automated monitoring and maintenance (systemd timers)
9. Run comprehensive performance validation tests
10. Document all procedures and create troubleshooting guide

PERFORMANCE CONSIDERATIONS:
- Use noatime mount option to reduce write operations
- Configure appropriate commit intervals for ext4 filesystems
- Set up XFS with optimal allocation group count for Kafka
- Enable SSD-specific optimizations (TRIM, I/O scheduler)
- Monitor I/O patterns and adjust configurations as needed

ERROR HANDLING:
- Include comprehensive error checking in all scripts
- Validate each step before proceeding to the next
- Provide clear error messages and recovery instructions
- Create rollback procedures for each major step
```

## Notes

- **CRITICAL**: This is a high-risk operation involving disk partitioning and filesystem creation
- **BACKUP**: Complete system backup is mandatory before implementation
- **TESTING**: All procedures must be tested on non-production systems first
- **PERFORMANCE**: SSD optimizations are crucial for trading system performance requirements
- **SCALABILITY**: LVM provides flexibility for future storage expansion
- **MONITORING**: Proactive monitoring prevents capacity and performance issues
- **SECURITY**: Proper file permissions and ownership are essential for database security

## Status Updates

- **2025-08-24**: Feature specification created with detailed implementation plan