# JTS Hot Storage (NVMe) Setup Guide

## Overview

This guide covers the setup and management of the JTS hot storage tier using NVMe SSD technology. The hot storage tier provides ultra-fast access for real-time trading operations, active databases, and high-frequency data processing.

## Architecture

### Directory-Based Storage Design

The JTS hot storage uses a directory-based architecture that provides flexibility without the complexity and risks of disk partitioning:

```
/data/jts/hot/ (NVMe SSD Mount)
├── postgresql/          # PostgreSQL data (~800GB planned)
│   ├── data/           # Database files
│   ├── logs/           # Transaction logs
│   └── config/         # Configuration files
├── clickhouse/          # ClickHouse data (~1.5TB planned)
│   ├── data/           # Time-series data
│   ├── logs/           # Query and system logs
│   └── tmp/            # Temporary processing files
├── kafka/              # Kafka logs (~600GB planned)
│   ├── data/           # Topic partitions
│   └── logs/           # Broker logs
├── mongodb/            # MongoDB collections (~200GB planned)
│   ├── data/           # Document collections
│   ├── logs/           # MongoDB logs
│   └── config/         # Configuration files
├── redis/              # Redis persistence (~50GB planned)
│   ├── data/           # RDB snapshots and AOF
│   └── logs/           # Redis logs
├── docker/             # Docker volumes (~500GB planned)
│   ├── volumes/        # Named volumes
│   ├── containers/     # Container data
│   └── tmp/            # Temporary files
└── backup/             # Local backup staging (~350GB planned)
    ├── daily/          # Daily backups
    ├── snapshots/      # Database snapshots
    └── staging/        # Backup preparation area
```

### Service User Configuration

Each database service runs under its own dedicated system user for security isolation:

- **postgres**: PostgreSQL database service
- **clickhouse**: ClickHouse analytics database
- **kafka**: Apache Kafka message broker
- **mongodb**: MongoDB document database
- **redis**: Redis in-memory database
- **docker**: Docker container runtime (uses existing docker group)

## Installation

### Prerequisites

1. **Root Access**: Setup requires sudo/root privileges for user and directory management
2. **NVMe SSD**: At least 1TB of available space (4TB recommended)
3. **Operating System**: Linux with standard filesystem tools

### Quick Setup

Run the automated setup script:

```bash
# Clone or navigate to the JTS repository
cd /path/to/jts-repository

# Run the setup script with root privileges
sudo ./scripts/setup-hot-directories.sh
```

### Manual Setup Steps

If you prefer manual setup or need to troubleshoot:

#### 1. Create Service Users

```bash
sudo useradd -r -s /bin/false postgres
sudo useradd -r -s /bin/false clickhouse
sudo useradd -r -s /bin/false kafka
sudo useradd -r -s /bin/false mongodb
sudo useradd -r -s /bin/false redis
```

#### 2. Create Directory Structure

```bash
# Base directory
sudo mkdir -p /data/jts/hot

# Service directories
sudo mkdir -p /data/jts/hot/{postgresql,clickhouse,kafka,mongodb,redis,docker,backup}

# Service subdirectories
sudo mkdir -p /data/jts/hot/postgresql/{data,logs,config}
sudo mkdir -p /data/jts/hot/clickhouse/{data,logs,tmp}
sudo mkdir -p /data/jts/hot/kafka/{data,logs}
sudo mkdir -p /data/jts/hot/mongodb/{data,logs,config}
sudo mkdir -p /data/jts/hot/redis/{data,logs}
sudo mkdir -p /data/jts/hot/docker/{volumes,containers,tmp}
sudo mkdir -p /data/jts/hot/backup/{daily,snapshots,staging}
```

#### 3. Configure Permissions

```bash
# Set ownership
sudo chown -R postgres:postgres /data/jts/hot/postgresql/
sudo chown -R clickhouse:clickhouse /data/jts/hot/clickhouse/
sudo chown -R kafka:kafka /data/jts/hot/kafka/
sudo chown -R mongodb:mongodb /data/jts/hot/mongodb/
sudo chown -R redis:redis /data/jts/hot/redis/
sudo chown -R root:docker /data/jts/hot/docker/
sudo chown -R root:root /data/jts/hot/backup/

# Set permissions
sudo chmod 750 /data/jts/hot/{postgresql,clickhouse,kafka,mongodb,redis}/
sudo chmod 755 /data/jts/hot/{docker,backup}/
sudo chmod 755 /data/jts/hot/
```

## Validation

### Automated Validation

Use the validation script to verify your setup:

```bash
# Basic validation
./scripts/validate-directories.sh

# Verbose validation with detailed output
./scripts/validate-directories.sh -v

# JSON output for automation
./scripts/validate-directories.sh -j

# Quiet mode for scripts
./scripts/validate-directories.sh -q
```

### Manual Validation Checks

#### 1. Verify Users Exist
```bash
id postgres clickhouse kafka mongodb redis
```

#### 2. Check Directory Structure
```bash
ls -la /data/jts/hot/
tree /data/jts/hot/ -L 2
```

#### 3. Verify Permissions
```bash
ls -la /data/jts/hot/
ls -la /data/jts/hot/*/
```

#### 4. Test Write Access
```bash
sudo -u postgres touch /data/jts/hot/postgresql/test_write
sudo -u clickhouse touch /data/jts/hot/clickhouse/test_write
# Clean up
sudo rm -f /data/jts/hot/*/test_write
```

## Monitoring

### Storage Monitoring Script

The included monitoring script provides comprehensive storage usage reporting:

```bash
# Basic usage report
./scripts/jts-storage-monitor.sh

# Summary only
./scripts/jts-storage-monitor.sh -s

# JSON output for monitoring systems
./scripts/jts-storage-monitor.sh -j

# Custom warning/critical thresholds
./scripts/jts-storage-monitor.sh -w 75 -c 85
```

### Installing System Monitoring

To install the monitoring script system-wide:

```bash
# Copy to system location
sudo cp scripts/jts-storage-monitor.sh /usr/local/bin/

# Make executable
sudo chmod +x /usr/local/bin/jts-storage-monitor.sh

# Create symlink for convenience
sudo ln -s /usr/local/bin/jts-storage-monitor.sh /usr/local/bin/jts-storage
```

### Cron Monitoring

Add automated monitoring with cron:

```bash
# Edit crontab
sudo crontab -e

# Add monitoring job (every 6 hours)
0 */6 * * * /usr/local/bin/jts-storage-monitor.sh -s >> /var/log/jts-storage-monitor.log 2>&1

# Add daily detailed report
0 6 * * * /usr/local/bin/jts-storage-monitor.sh >> /var/log/jts-storage-daily.log 2>&1
```

## Database Integration

### PostgreSQL Configuration

Configure PostgreSQL to use the hot storage directory:

```postgresql
# In postgresql.conf
data_directory = '/data/jts/hot/postgresql/data'
log_directory = '/data/jts/hot/postgresql/logs'
```

### ClickHouse Configuration

Configure ClickHouse data paths:

```xml
<!-- In config.xml -->
<clickhouse>
    <path>/data/jts/hot/clickhouse/data/</path>
    <tmp_path>/data/jts/hot/clickhouse/tmp/</tmp_path>
    <logger>
        <log>/data/jts/hot/clickhouse/logs/clickhouse-server.log</log>
    </logger>
</clickhouse>
```

### Kafka Configuration

Configure Kafka broker:

```properties
# In server.properties
log.dirs=/data/jts/hot/kafka/data
```

### MongoDB Configuration

Configure MongoDB storage:

```yaml
# In mongod.conf
storage:
  dbPath: /data/jts/hot/mongodb/data
systemLog:
  destination: file
  path: /data/jts/hot/mongodb/logs/mongod.log
```

### Redis Configuration

Configure Redis persistence:

```redis
# In redis.conf
dir /data/jts/hot/redis/data
logfile /data/jts/hot/redis/logs/redis-server.log
```

### Docker Configuration

Configure Docker to use hot storage for volumes:

```json
{
  "data-root": "/data/jts/hot/docker",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  }
}
```

## Maintenance

### Regular Maintenance Tasks

#### 1. Monitor Disk Usage

```bash
# Check overall usage
df -h /data/jts/hot

# Detailed service usage
du -sh /data/jts/hot/*/ | sort -hr

# Use monitoring script
jts-storage-monitor.sh
```

#### 2. Clean Up Log Files

```bash
# Find large log files
find /data/jts/hot -name "*.log" -size +100M -ls

# Rotate logs (example for PostgreSQL)
sudo -u postgres pg_ctl reload -D /data/jts/hot/postgresql/data
```

#### 3. Backup Staging Cleanup

```bash
# Clean old backup staging files (older than 7 days)
find /data/jts/hot/backup/staging -type f -mtime +7 -delete

# Clean old snapshots (older than 30 days)
find /data/jts/hot/backup/snapshots -type f -mtime +30 -delete
```

### Performance Optimization

#### 1. Filesystem Tuning

For ext4 filesystems on NVMe:

```bash
# Disable access time updates
sudo mount -o remount,noatime /data/jts/hot

# Add to /etc/fstab for persistence
echo "/dev/nvmeXnY /data/jts/hot ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab
```

#### 2. I/O Scheduling

Optimize I/O scheduler for NVMe:

```bash
# Check current scheduler
cat /sys/block/nvme0n1/queue/scheduler

# Set none scheduler for NVMe (best for SSDs)
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler
```

#### 3. SSD Optimization

Enable TRIM support:

```bash
# Enable TRIM support
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# Manual TRIM
sudo fstrim /data/jts/hot
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied Errors

```bash
# Check ownership
ls -la /data/jts/hot/service_name/

# Fix ownership
sudo chown -R service_user:service_user /data/jts/hot/service_name/

# Fix permissions
sudo chmod 750 /data/jts/hot/service_name/
```

#### 2. Disk Space Issues

```bash
# Find largest directories
du -sh /data/jts/hot/*/ | sort -hr

# Find large files
find /data/jts/hot -size +1G -ls

# Clean up temporary files
find /data/jts/hot -name "*.tmp" -mtime +1 -delete
```

#### 3. Service Start Failures

```bash
# Check directory exists
ls -la /data/jts/hot/service_name/

# Check write permissions
sudo -u service_user touch /data/jts/hot/service_name/test_write
sudo -u service_user rm /data/jts/hot/service_name/test_write

# Check service logs
journalctl -u service_name -f
```

### Recovery Procedures

#### 1. Directory Structure Corruption

```bash
# Re-run setup script
sudo ./scripts/setup-hot-directories.sh

# Validate setup
./scripts/validate-directories.sh -v
```

#### 2. Permission Issues

```bash
# Reset all permissions
sudo chown -R postgres:postgres /data/jts/hot/postgresql/
sudo chown -R clickhouse:clickhouse /data/jts/hot/clickhouse/
sudo chown -R kafka:kafka /data/jts/hot/kafka/
sudo chown -R mongodb:mongodb /data/jts/hot/mongodb/
sudo chown -R redis:redis /data/jts/hot/redis/
sudo chown -R root:docker /data/jts/hot/docker/
sudo chown -R root:root /data/jts/hot/backup/

sudo chmod 750 /data/jts/hot/{postgresql,clickhouse,kafka,mongodb,redis}/
sudo chmod 755 /data/jts/hot/{docker,backup}/
```

## Security Considerations

### Access Control

1. **Service Isolation**: Each service runs under its own user account
2. **Directory Permissions**: Restrictive permissions prevent cross-service access
3. **No Shell Access**: Service users have `/bin/false` as shell
4. **Sudo Required**: Administrative changes require sudo privileges

### Best Practices

1. **Regular Audits**: Periodically run validation scripts
2. **Log Monitoring**: Monitor service logs for access patterns
3. **Backup Security**: Secure backup staging area access
4. **Network Security**: Ensure proper firewall rules for database ports

## Integration with JTS Services

### Service Configuration Files

Update your JTS service configurations to point to the hot storage directories:

```yaml
# jts-config.yaml (example)
database:
  postgresql:
    data_directory: /data/jts/hot/postgresql/data
  clickhouse:
    data_path: /data/jts/hot/clickhouse/data
  kafka:
    log_dirs: /data/jts/hot/kafka/data
  mongodb:
    db_path: /data/jts/hot/mongodb/data
  redis:
    data_dir: /data/jts/hot/redis/data

docker:
  data_root: /data/jts/hot/docker

backup:
  staging_dir: /data/jts/hot/backup/staging
  daily_dir: /data/jts/hot/backup/daily
```

### Environment Variables

Set environment variables for JTS applications:

```bash
export JTS_HOT_STORAGE_ROOT="/data/jts/hot"
export JTS_POSTGRESQL_DATA="/data/jts/hot/postgresql/data"
export JTS_CLICKHOUSE_DATA="/data/jts/hot/clickhouse/data"
export JTS_KAFKA_LOGS="/data/jts/hot/kafka/data"
export JTS_MONGODB_DATA="/data/jts/hot/mongodb/data"
export JTS_REDIS_DATA="/data/jts/hot/redis/data"
export JTS_BACKUP_STAGING="/data/jts/hot/backup/staging"
```

## Next Steps

After successful hot storage setup:

1. **Database Mount Integration** (Task 1012): Configure database services to use hot storage
2. **Storage Performance Optimization** (Task 1015): Implement advanced performance tuning
3. **Tiered Storage Management** (Task 1016): Set up warm and cold storage tiers

## Support and References

### Documentation

- [JTS Architecture Guide](../plan/jts_improved_architecture.md)
- [Storage Infrastructure Spec](../specs/1000-epic-foundation-infrastructure/1001-feature-storage-infrastructure/)
- [Database Integration Guide](./DATABASE_INTEGRATION.md) *(to be created)*

### Monitoring and Alerts

- Use the included monitoring scripts for regular health checks
- Integrate with your monitoring system using JSON output
- Set up alerts for disk usage thresholds
- Monitor service logs for access pattern anomalies

### Support

For issues or questions:
1. Run validation script with verbose output: `./scripts/validate-directories.sh -v`
2. Check system logs: `journalctl -xe`
3. Review service-specific logs in their respective directories
4. Consult the troubleshooting section above