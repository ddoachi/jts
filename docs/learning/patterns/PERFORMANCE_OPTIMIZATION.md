# JTS Storage Performance Optimization Guide

_From: E01-F01-T05 Storage Performance Optimization_  
_Version: 1.0_  
_Date: 2025-08-30_

## Overview

This document provides comprehensive guidance for implementing and maintaining storage performance optimizations for the JTS trading system. These optimizations are critical for achieving the sub-millisecond response times required for algorithmic trading operations.

## Quick Start

### 1. Deploy Configuration Files

```bash
# Copy udev rules for I/O scheduler optimization
sudo cp configs/60-ssd-scheduler.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules

# Copy systemd service and timer for automated TRIM
sudo cp configs/fstrim-all.service /etc/systemd/system/
sudo cp configs/fstrim-all.timer /etc/systemd/system/

# Enable and start the TRIM timer
sudo systemctl daemon-reload
sudo systemctl enable fstrim-all.timer
sudo systemctl start fstrim-all.timer
```

### 2. Run Performance Validation

```bash
# Quick performance check
./scripts/performance-benchmark.sh --quick

# Full performance benchmark
./scripts/performance-benchmark.sh --full

# Check optimization status
./scripts/ssd-optimization.sh --check
```

## Performance Optimization Components

### 1. I/O Scheduler Optimization

**Purpose**: Configure optimal I/O schedulers for NVMe drives to minimize latency.

**Configuration**: `60-ssd-scheduler.rules`

- Sets NVMe drives to use the 'none' scheduler
- Eliminates unnecessary CPU overhead for NVMe devices
- Applied automatically via udev rules

**Benefits**:

- Reduced I/O latency for trading operations
- Lower CPU utilization for storage operations
- Immediate performance improvement

**Verification**:

```bash
cat /sys/block/nvme0n1/queue/scheduler
# Should show: [none] mq-deadline
```

### 2. Automated TRIM Support

**Purpose**: Maintain SSD performance over time through regular TRIM operations.

**Configuration**:

- `fstrim-all.service` - TRIM service definition
- `fstrim-all.timer` - Weekly execution schedule

**Schedule**: Every Sunday at 2:00 AM with 5-minute randomization

**Target Filesystems**:

- `/var/lib/postgresql` - Database storage
- `/var/lib/clickhouse` - Time-series data
- `/var/lib/kafka` - Message logs
- `/var/lib/mongodb` - Document storage
- `/var/lib/redis` - Cache storage
- `/var/lib/docker-jts` - Container storage
- `/data/local-backup` - Backup storage

**Benefits**:

- Prevents SSD performance degradation
- Extends SSD lifespan
- Automated operation with minimal system impact

### 3. Performance Monitoring

**Benchmark Script**: `performance-benchmark.sh`

**Features**:

- Sequential and random I/O testing across all storage tiers
- Performance threshold validation for trading requirements
- Support for quick and full testing modes
- Automated pass/fail validation against trading system requirements

**Usage**:

```bash
# Quick test (256MB)
./performance-benchmark.sh --quick

# Full test (1GB)
./performance-benchmark.sh --full
```

**Optimization Monitor**: `ssd-optimization.sh`

**Features**:

- Real-time optimization status checking
- Automated issue detection and resolution
- Comprehensive system health reporting
- Integration with monitoring systems via exit codes

**Usage**:

```bash
# Check status
./ssd-optimization.sh --check

# Attempt automatic fixes
./ssd-optimization.sh --fix

# Generate detailed report
./ssd-optimization.sh --report
```

## Performance Requirements

### Trading System Thresholds

| Storage Tier | Min Throughput | Min IOPS | Use Case               |
| ------------ | -------------- | -------- | ---------------------- |
| Hot (NVMe)   | 1,000 MB/s     | 50,000   | Real-time trading data |
| Warm (SATA)  | 500 MB/s       | 10,000   | Backups and logs       |
| Cold (NAS)   | 100 MB/s       | N/A      | Archival storage       |

### Performance Validation

The benchmark script automatically validates performance against these thresholds:

- **Exit Code 0**: All requirements met
- **Exit Code 1**: Critical performance issues detected
- **Exit Code 2**: Validation incomplete (missing mounts)

## Installation Instructions

### Prerequisites

1. **Root Access**: Required for system-level optimizations
2. **NVMe Drives**: Optimizations target NVMe storage devices
3. **Systemd**: Required for automated TRIM operations
4. **Optional Tools**:
   - `fio` - For advanced IOPS testing
   - `iostat` - For I/O statistics monitoring

### Step-by-Step Installation

#### 1. Install Configuration Files

```bash
# Navigate to deliverables directory
# All deliverables are now in their natural locations

# Install udev rules
sudo cp config/60-ssd-scheduler.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# Install systemd files
sudo cp config/fstrim-all.service /etc/systemd/system/
sudo cp config/fstrim-all.timer /etc/systemd/system/
sudo systemctl daemon-reload
```

#### 2. Enable Automated Services

```bash
# Enable and start TRIM timer
sudo systemctl enable fstrim-all.timer
sudo systemctl start fstrim-all.timer

# Verify timer is active
sudo systemctl status fstrim-all.timer
sudo systemctl list-timers fstrim-all.timer
```

#### 3. Verify Installation

```bash
# Check I/O scheduler (should show [none])
cat /sys/block/nvme*/queue/scheduler

# Test TRIM service manually
sudo systemctl start fstrim-all.service
sudo journalctl -u fstrim-all.service --no-pager

# Run optimization check
./scripts/ssd-optimization.sh --check
```

## Troubleshooting

### Common Issues

#### I/O Scheduler Not Set to 'none'

**Symptoms**: Performance monitoring shows scheduler is not 'none'

**Solutions**:

1. Check if udev rules are installed: `ls -la /etc/udev/rules.d/60-ssd-scheduler.rules`
2. Reload udev rules: `sudo udevadm control --reload-rules && sudo udevadm trigger`
3. Manually set scheduler: `echo none | sudo tee /sys/block/nvme0n1/queue/scheduler`

#### TRIM Timer Not Running

**Symptoms**: `systemctl status fstrim-all.timer` shows inactive

**Solutions**:

1. Check service file exists: `ls -la /etc/systemd/system/fstrim-all.*`
2. Reload systemd: `sudo systemctl daemon-reload`
3. Enable timer: `sudo systemctl enable --now fstrim-all.timer`

#### Performance Below Thresholds

**Symptoms**: Benchmark script exits with code 1

**Solutions**:

1. Check for background I/O processes: `iostat -x 1 5`
2. Verify mount options include `noatime,discard`: `mount | grep nvme`
3. Check system load: `htop` or `top`
4. Verify SSD health: `smartctl -a /dev/nvme0n1`

#### Permission Denied Errors

**Symptoms**: Scripts fail with permission errors

**Solutions**:

1. Run optimization scripts as root: `sudo ./ssd-optimization.sh --fix`
2. Check file permissions: `ls -la scripts/`
3. Make scripts executable: `chmod +x scripts/*.sh`

### Performance Debugging

#### Low Throughput Issues

1. **Check I/O Scheduler**:

   ```bash
   cat /sys/block/nvme*/queue/scheduler
   ```

2. **Verify Mount Options**:

   ```bash
   mount | grep -E "(postgresql|clickhouse|kafka)"
   ```

3. **Check System Load**:

   ```bash
   iostat -x 1 5
   uptime
   ```

4. **Test Raw Device Performance**:
   ```bash
   sudo fio --name=test --ioengine=libaio --iodepth=32 --rw=read --bs=1M \
     --direct=1 --size=1G --numjobs=1 --filename=/dev/nvme0n1
   ```

#### High Latency Issues

1. **Check Queue Depth Settings**:

   ```bash
   cat /sys/block/nvme*/queue/nr_requests
   ```

2. **Monitor Real-time I/O**:

   ```bash
   iotop -ao
   ```

3. **Check CPU Frequency Scaling**:
   ```bash
   cat /proc/cpuinfo | grep MHz
   cpupower frequency-info
   ```

## Monitoring and Maintenance

### Automated Monitoring

#### Integration with Monitoring Systems

The scripts provide exit codes suitable for monitoring system integration:

```bash
# Cron job example
0 6 * * * /path/to/ssd-optimization.sh --check || echo "SSD optimization issues detected"

# Systemd service monitoring
ExecStart=/path/to/performance-benchmark.sh --quick
ExecStartPost=/bin/bash -c 'if [ $? -ne 0 ]; then systemctl --user start alert-service; fi'
```

#### Log Monitoring

Monitor systemd journal for TRIM operations:

```bash
# View recent TRIM operations
journalctl -u fstrim-all.service --since="1 week ago"

# Monitor TRIM timer
journalctl -u fstrim-all.timer --since="1 month ago"
```

### Regular Maintenance Tasks

#### Daily

- Monitor I/O performance via `iostat` or system monitoring
- Check for storage-related alerts

#### Weekly

- Automated TRIM operations (configured via systemd timer)
- Review TRIM operation logs

#### Monthly

- Run full performance benchmark
- Review and update performance baselines
- Check SSD health status via SMART data

#### Quarterly

- Review and update performance thresholds
- Evaluate hardware upgrade needs
- Audit optimization configuration

## Integration with Trading System

### Performance Impact

The optimizations provide immediate benefits for trading operations:

- **Order Execution**: Reduced database I/O latency
- **Market Data Processing**: Faster ClickHouse time-series operations
- **Risk Management**: Improved real-time calculation performance
- **Backup Operations**: Optimized backup and restore times

### Monitoring Integration

Integrate performance monitoring with trading system alerts:

```bash
# Example: Alert if performance drops below trading thresholds
if ! ./performance-benchmark.sh --quick; then
    curl -X POST "$ALERT_WEBHOOK" -d "SSD performance below trading requirements"
fi
```

### Disaster Recovery Considerations

- All optimization settings are applied via configuration files
- Settings persist across system reboots and updates
- Configuration can be version controlled and deployed automatically
- No risk of data loss from performance optimizations

## Security Considerations

### File Permissions

All configuration files use appropriate permissions:

- Udev rules: `644` (readable by all, writable by root)
- Systemd files: `644` (readable by all, writable by root)
- Scripts: `755` (executable by all, writable by root)

### System Changes

- All optimizations are non-invasive and reversible
- No modifications to critical system files
- No network-accessible services introduced
- Minimal additional system attack surface

### Audit Trail

- All changes logged via systemd journal
- Configuration files tracked in version control
- Performance metrics available for audit purposes

---

## Conclusion

This performance optimization implementation provides a comprehensive solution for maximizing storage performance in the JTS trading system. The combination of I/O scheduler optimization, automated TRIM operations, and continuous monitoring ensures optimal and sustained performance for trading operations.

Regular use of the monitoring scripts and adherence to the maintenance schedule will help maintain peak system performance and identify potential issues before they impact trading operations.
