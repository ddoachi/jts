# JTS Warm Storage (SATA) Setup Guide

## Overview

This document provides comprehensive guidance for setting up and managing the intermediate warm storage tier in the JTS (JooHan Trading System) infrastructure. The warm storage uses a 1TB SATA drive with btrfs filesystem and zstd:3 compression to provide efficient storage for backups, logs, and temporary processing files.

## Architecture

### Storage Tier Purpose

The warm storage tier serves as an intermediate layer between hot storage (NVMe) and cold storage, optimized for:

- **Daily Backups**: Database snapshots and automated backup operations
- **Log Aggregation**: Compressed storage for application and system logs  
- **Temporary Processing**: Workspace for large file operations and data processing
- **Space Efficiency**: btrfs compression maximizes storage utilization

### Technical Specifications

- **Device**: 1TB SATA drive (/dev/sda2)
- **Filesystem**: btrfs with zstd:3 compression
- **Mount Point**: `/data/warm-storage`
- **Capacity**: 931.5G available space
- **Features**: autodefrag, compression, sequential I/O optimization

## Quick Start

### Prerequisites

Before starting the setup, ensure you have:

1. **Hardware Requirements**:
   - 1TB SATA drive installed and detected as `/dev/sda2`
   - Minimum 16GB available space for setup and testing

2. **Software Requirements**:
   - btrfs-progs package installed
   - Root/sudo privileges
   - Basic system administration tools

3. **System Requirements**:
   - Linux system with kernel support for btrfs
   - Available mount point `/data/warm-storage`

### Automated Setup

The fastest way to set up warm storage is using the provided setup script:

```bash
# Make the script executable (if not already)
chmod +x scripts/setup-sata-storage.sh

# Run the setup script with root privileges
sudo scripts/setup-sata-storage.sh
```

The script will:
1. Verify SATA drive specifications and availability
2. Format the partition with btrfs and zstd:3 compression
3. Configure automatic mounting with optimized options
4. Create organized directory structure
5. Test compression effectiveness  
6. Configure system integration (logrotate, cron cleanup)

### Manual Setup (Alternative)

If you prefer manual setup or need to customize the process:

#### Step 1: Verify Drive
```bash
# Check drive specifications
lsblk -o NAME,SIZE,MODEL,TRAN /dev/sda

# Verify partition availability
lsblk /dev/sda2
```

#### Step 2: Format Filesystem
```bash
# Format with btrfs and compression
sudo mkfs.btrfs -f -L "jts-warm-storage" \
  -O compress-force=zstd:3 \
  /dev/sda2

# Verify filesystem creation
sudo btrfs filesystem show /dev/sda2
```

#### Step 3: Configure Mount
```bash
# Create mount point
sudo mkdir -p /data/warm-storage

# Add to fstab
echo '/dev/sda2 /data/warm-storage btrfs defaults,compress=zstd:3,autodefrag,noatime 0 2' | sudo tee -a /etc/fstab

# Mount filesystem
sudo mount /data/warm-storage
```

#### Step 4: Create Directory Structure
```bash
# Create main directories
sudo mkdir -p /data/warm-storage/{daily-backups,logs,temp-processing}

# Create backup subdirectories
sudo mkdir -p /data/warm-storage/daily-backups/{postgresql,clickhouse,mongodb}

# Create log subdirectories
sudo mkdir -p /data/warm-storage/logs/{application,system,audit}

# Set permissions
sudo chmod 755 /data/warm-storage
sudo chmod 755 /data/warm-storage/daily-backups
sudo chmod 755 /data/warm-storage/logs
sudo chmod 755 /data/warm-storage/temp-processing
```

## Directory Structure

The warm storage is organized with a logical directory hierarchy:

```
/data/warm-storage/
├── daily-backups/         # Database snapshots and automated backups
│   ├── postgresql/        # PostgreSQL database backups
│   ├── clickhouse/        # ClickHouse database backups
│   └── mongodb/           # MongoDB database backups
├── logs/                  # Application logs with 30-day retention
│   ├── application/       # Application-specific logs
│   ├── system/           # System and service logs
│   └── audit/            # Security and audit logs
└── temp-processing/       # Temporary large file operations
```

### Usage Guidelines

- **daily-backups/**: Store database dumps, snapshots, and automated backups
- **logs/**: Centralized logging with automatic rotation and compression
- **temp-processing/**: Temporary workspace for data processing (auto-cleanup after 3 days)

## System Integration

### Log Management

Warm storage integrates with the system's log management through logrotate:

**Configuration**: `/etc/logrotate.d/warm-storage`
```
/data/warm-storage/logs/*/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
```

### Automatic Cleanup

Temporary files are automatically cleaned up via cron job:

**Configuration**: `/etc/crontab`
```
0 2 * * * root find /data/warm-storage/temp-processing -mtime +3 -delete
```

## Monitoring and Health Checks

### Health Check Script

Use the provided health check script to monitor storage health:

```bash
# Basic health check
scripts/sata-health-check.sh

# Verbose output
scripts/sata-health-check.sh --verbose

# JSON output for integration
scripts/sata-health-check.sh --json

# Enable alerts
scripts/sata-health-check.sh --alert
```

### Key Metrics to Monitor

1. **Disk Usage**: Warning at 80%, Critical at 90%
2. **Mount Status**: Ensure filesystem is properly mounted
3. **Compression Efficiency**: Verify zstd compression is active
4. **Directory Structure**: Confirm all required directories exist
5. **I/O Performance**: Basic read/write performance validation

### Alert Integration

The health check script can send notifications via Telegram when issues are detected. Ensure the notification system is configured for automatic monitoring.

## Performance Optimization

### btrfs Mount Options

The warm storage uses optimized mount options for performance:

- `compress=zstd:3`: Balanced compression ratio and speed
- `autodefrag`: Maintains performance over time
- `noatime`: Reduces metadata writes for better performance

### Compression Benefits

btrfs with zstd:3 compression typically provides:
- **Space Savings**: 40-60% reduction in storage usage
- **Performance**: Minimal impact on I/O operations
- **Flexibility**: Transparent compression/decompression

### Sequential I/O Optimization

SATA drives are optimized for sequential operations, making them ideal for:
- Database backup operations
- Log file writes
- Large file processing

## Backup and Recovery

### btrfs Snapshots

The warm storage supports btrfs snapshots for point-in-time recovery:

```bash
# Create snapshot
sudo btrfs subvolume snapshot /data/warm-storage /data/warm-storage/.snapshots/$(date +%Y%m%d_%H%M%S)

# List snapshots
sudo btrfs subvolume list /data/warm-storage

# Restore from snapshot (if needed)
# sudo btrfs subvolume delete /data/warm-storage
# sudo btrfs subvolume snapshot /data/warm-storage/.snapshots/TIMESTAMP /data/warm-storage
```

### Backup Strategy

The warm storage itself should be backed up to cold storage:
1. Daily backup of critical data in daily-backups/
2. Log rotation and archival to cold storage
3. Snapshot-based recovery for rapid restoration

## Troubleshooting

### Common Issues

1. **Mount Failures**:
   ```bash
   # Check device status
   lsblk /dev/sda2
   
   # Verify fstab entry
   grep "/data/warm-storage" /etc/fstab
   
   # Manual mount test
   sudo mount -t btrfs /dev/sda2 /data/warm-storage
   ```

2. **Compression Not Working**:
   ```bash
   # Check mount options
   mount | grep warm-storage
   
   # Test compression
   dd if=/dev/zero of=/data/warm-storage/test bs=1M count=10
   du -sh /data/warm-storage/test
   ls -lh /data/warm-storage/test
   rm /data/warm-storage/test
   ```

3. **Permission Issues**:
   ```bash
   # Fix ownership
   sudo chown -R root:root /data/warm-storage
   
   # Fix permissions
   sudo chmod -R 755 /data/warm-storage
   ```

4. **High Disk Usage**:
   ```bash
   # Check space usage by directory
   sudo du -sh /data/warm-storage/*
   
   # Clean old logs
   sudo find /data/warm-storage/logs -name "*.log.gz" -mtime +30 -delete
   
   # Clean temp files
   sudo find /data/warm-storage/temp-processing -mtime +3 -delete
   ```

### Recovery Procedures

1. **Filesystem Corruption**:
   ```bash
   # Unmount filesystem
   sudo umount /data/warm-storage
   
   # Check filesystem
   sudo btrfs check /dev/sda2
   
   # Repair if needed (use with caution)
   sudo btrfs check --repair /dev/sda2
   ```

2. **Complete Reinstallation**:
   If the warm storage needs to be completely reset, follow the setup procedure again. Ensure all data is backed up before reformatting.

## Integration with JTS Services

### Backup Scripts

JTS services can use the warm storage for backup operations:

```bash
# PostgreSQL backup example
pg_dump jts_trading > /data/warm-storage/daily-backups/postgresql/jts_trading_$(date +%Y%m%d).sql

# ClickHouse backup example  
clickhouse-client --query "BACKUP TABLE market_data TO Disk('warm_storage', 'daily-backups/clickhouse/market_data_$(date +%Y%m%d)')"
```

### Log Configuration

Configure JTS services to write logs to warm storage:

```javascript
// NestJS logging configuration example
{
  file: {
    filename: '/data/warm-storage/logs/application/jts-trading.log',
    maxsize: 10485760, // 10MB
    maxFiles: 30,
    format: format.combine(
      format.timestamp(),
      format.json()
    )
  }
}
```

## Maintenance Schedule

### Daily
- Automated backup operations
- Log rotation and compression
- Temporary file cleanup

### Weekly  
- Health check script execution
- Disk usage monitoring
- Performance validation

### Monthly
- Full filesystem health check
- Snapshot creation for critical data
- Cleanup of old backup files
- Review and optimize compression settings

## Security Considerations

1. **Access Control**: Limit access to warm storage directories based on service requirements
2. **Backup Encryption**: Consider encrypting sensitive backup data
3. **Audit Logging**: Monitor access to backup and log directories
4. **Network Security**: Ensure secure access when warm storage is used by remote services

## Support and Maintenance

For issues with warm storage setup or operation:

1. Check the execution logs in the context file
2. Run the health check script with verbose output
3. Review system logs for filesystem errors
4. Consult btrfs documentation for advanced troubleshooting

The warm storage tier is designed to be self-managing with minimal intervention required once properly configured.