# Cold Storage (NAS) Setup Guide

## Overview

This document provides setup instructions for the JTS Cold Storage tier using a 28TB Synology NAS for historical market data, long-term backups, and archival storage.

## System Configuration

### Network Optimization

1. **Apply Network Buffer Settings**:
   ```bash
   # Add to /etc/sysctl.conf
   net.core.rmem_default = 262144
   net.core.rmem_max = 16777216
   net.core.wmem_default = 262144
   net.core.wmem_max = 16777216
   
   # Apply settings
   sudo sysctl -p
   ```

2. **Enhanced NFS Mount**:
   ```bash
   # Update /etc/fstab with optimized mount
   192.168.1.101:/volume1/cocodev /mnt/synology nfs rw,hard,intr,rsize=1048576,wsize=1048576,timeo=600,retrans=2,_netdev 0 0
   
   # Remount
   sudo umount /mnt/synology
   sudo mount /mnt/synology
   ```

## Directory Structure

The NAS provides organized storage with the following structure:

```
/mnt/synology/jts/
├── archives/               # Long-term backups (3TB allocation)
│   ├── database/           # Database backup archives
│   ├── configs/            # Configuration snapshots
│   └── strategies/         # Trading strategy archives
├── market-data/            # Historical market data (10TB allocation)
│   ├── raw/                # Original tick data
│   ├── processed/          # Aggregated OHLCV data
│   └── indicators/         # Pre-calculated technical indicators
├── backtesting/            # Backtesting datasets (2TB allocation)
│   ├── datasets/           # Historical test datasets
│   ├── results/            # Backtest execution results
│   └── reports/            # Performance analysis reports
├── models/                 # ML models and training data (1TB allocation)
│   ├── training/           # Training datasets
│   ├── models/             # Trained model files
│   └── validation/         # Model validation results
└── development/            # Development resources (1TB allocation)
    ├── datasets/           # Development datasets
    ├── notebooks/          # Jupyter notebooks
    └── experiments/        # Experimental code and results
```

## Performance Metrics

- **NAS Capacity**: 28TB (17TB available)
- **Network Latency**: ~0.17ms average
- **Write Performance**: 1.0 GB/s
- **Read Performance**: 899 MB/s
- **Concurrent Access**: 340-350 MB/s per stream

## Health Monitoring

Use the provided health check script:

```bash
# Run health check
./scripts/nas-health-check.sh
```

The script monitors:
- NAS connectivity (ping test)
- Mount status verification
- Storage space usage
- Directory structure validation
- Network performance testing

## Integration Points

### Archival Scripts
- Directory structure ready for automated archival processes
- Proper permissions (755) set for all directories
- Integration points available in all data type categories

### Development Workflow
- `development/notebooks/` for Jupyter notebook storage
- `development/datasets/` for shared development data
- `development/experiments/` for experimental code and results

### Data Pipeline Integration
- `market-data/raw/` for original tick data storage
- `market-data/processed/` for aggregated data
- `market-data/indicators/` for technical indicators

## Troubleshooting

### Connection Issues
1. Check NAS connectivity: `ping 192.168.1.101`
2. Verify mount status: `mount | grep synology`
3. Test permissions: `ls -la /mnt/synology/jts/`

### Performance Issues
1. Check network buffers: `sysctl net.core.rmem_max`
2. Verify mount options: `mount | grep synology`
3. Run performance test: `./scripts/nas-health-check.sh`

### Space Management
1. Check usage: `df -h /mnt/synology`
2. Monitor directory sizes: `du -sh /mnt/synology/jts/*`

## Security Considerations

- NFS mount uses proper timeout and retry settings
- Directory permissions set to 755 (owner: read/write/execute, group/others: read/execute)
- Network access limited to internal network (192.168.1.0/24)
- Regular connectivity monitoring via health check script

## Next Steps

1. **Manual Configuration**: Apply sysctl and fstab changes with sudo privileges
2. **Archival Integration**: Implement automated archival processes
3. **Monitoring Setup**: Integrate health check into system monitoring
4. **Capacity Planning**: Monitor usage and plan for expansion