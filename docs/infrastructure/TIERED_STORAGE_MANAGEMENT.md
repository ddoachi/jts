# Tiered Storage Management

<!-- Generated from spec: E01-F01-T06 (Tiered Storage Management) -->
<!-- Spec ID: 08fe2621 -->

## Overview

The JTS Tiered Storage Management system provides automated management for the three-tier storage infrastructure, including data lifecycle management, automated archival processes, cross-tier health monitoring, and intelligent data movement between storage tiers.

## Architecture

### Storage Tiers

1. **Hot Tier (NVMe)**: `/var/lib` - High-performance storage for active data
2. **Warm Tier (SATA)**: `/data/warm-storage` - Medium-performance for recent data  
3. **Cold Tier (NAS)**: `/mnt/synology/jts` - Long-term archival storage

## Components

### Scripts

#### `storage-health.sh`
Multi-tier health monitoring script that checks:
- Hot tier (LVM) status and usage
- Warm tier (SATA) filesystem status
- Cold tier (NAS) connectivity and usage
- Usage alerts with configurable thresholds

**Usage:**
```bash
./storage-health.sh
```

#### `tiered-storage.sh`
Automated data movement and cleanup script supporting:
- Log migration from hot to warm storage (7+ days old)
- Backup migration from warm to cold storage (30+ days old)
- Temporary file cleanup across all tiers
- Docker system cleanup

**Usage:**
```bash
./tiered-storage.sh {migrate|cleanup|all}
```

#### `nas-archival.sh`
NAS-specific backup and archival management:
- Development data synchronization (notebooks, datasets)
- System configuration backups with timestamps
- Rsync-based incremental updates

**Usage:**
```bash
./nas-archival.sh {development|configs|all}
```

#### `lvm-backup.sh`
LVM snapshot management for database backups:
- Creates snapshots for PostgreSQL, ClickHouse, MongoDB
- Automated cleanup of snapshots older than 7 days
- Handles LVM unavailability gracefully

**Usage:**
```bash
./lvm-backup.sh {create|cleanup}
```

### Systemd Integration

#### Service: `tiered-storage.service`
- **Type**: oneshot
- **Execution**: Runs `tiered-storage.sh all`
- **Logging**: Journal output for monitoring

#### Timer: `tiered-storage.timer`
- **Schedule**: Daily execution
- **Persistence**: Maintains schedule across reboots
- **Target**: `timers.target`

### Installation

1. **Copy Scripts**:
   ```bash
   sudo cp scripts/storage/* /usr/local/bin/
   sudo chmod +x /usr/local/bin/{storage-health,tiered-storage,nas-archival,lvm-backup}.sh
   ```

2. **Install Systemd Units**:
   ```bash
   sudo cp configs/storage/tiered-storage.{service,timer} /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable tiered-storage.timer
   sudo systemctl start tiered-storage.timer
   ```

3. **Verify Installation**:
   ```bash
   sudo systemctl status tiered-storage.timer
   ```

## Monitoring

### Health Checks

Run regular health checks:
```bash
storage-health.sh
```

Expected output shows status for all three tiers:
- ✅ Tier operational
- ⚠️ Tier unavailable (graceful degradation)
- 🚨 Critical usage alerts (>90%)
- ⚠️ Warning usage alerts (>80%)

### Log Monitoring

Monitor automated execution:
```bash
journalctl -u tiered-storage.service -f
```

## Troubleshooting

### Common Issues

1. **NAS Unreachable**: Check network connectivity and mount status
2. **LVM Unavailable**: Verify volume group exists and is active
3. **Warm Storage Full**: Review data movement policies and manual cleanup
4. **Permission Errors**: Ensure scripts run with appropriate privileges

### Manual Operations

Force immediate data movement:
```bash
sudo tiered-storage.sh migrate
```

Emergency cleanup:
```bash
sudo tiered-storage.sh cleanup
```

Create manual snapshots:
```bash
sudo lvm-backup.sh create
```

## Performance Impact

- **Scheduled Operations**: Run during low-activity periods (daily)
- **Resource Usage**: Minimal CPU/memory impact during normal operation  
- **Network Impact**: NAS operations may use significant bandwidth during sync
- **Storage Impact**: Temporary space requirements during data movement

## Security Considerations

- All scripts handle missing tiers gracefully
- No data movement without destination verification
- Comprehensive error logging for audit trails
- Read-only operations for health monitoring

## Maintenance

### Regular Tasks

- Monitor usage alerts and respond to capacity warnings
- Review backup retention policies and adjust as needed
- Verify systemd timer execution via journal logs
- Test recovery procedures using tiered backups

### Configuration Updates

Modify systemd timer schedule:
```bash
sudo systemctl edit tiered-storage.timer
```

Update script parameters by editing the scripts directly in `/usr/local/bin/`.

## Recovery Procedures

### Data Recovery

1. **From LVM Snapshots**: Mount and copy from `/dev/vg_jts/snap_*`
2. **From Warm Storage**: Access archived data in `/data/warm-storage/`
3. **From Cold Storage**: Retrieve from NAS archival directories

### System Recovery

Use configuration backups from NAS:
```bash
ls /mnt/synology/jts/archives/configs/
```

## Integration Points

- **Dependencies**: Requires T03 (Warm Storage) and T04 (Cold Storage)
- **Monitoring**: Integrates with existing infrastructure monitoring
- **Backup Systems**: Coordinates with database-specific backup procedures
- **Trading System**: Scheduled during maintenance windows to avoid impact