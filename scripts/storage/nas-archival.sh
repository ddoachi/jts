#!/bin/bash
# Generated from spec: E01-F01-T06 (Tiered Storage Management)
# Spec ID: 08fe2621

set -euo pipefail

NAS_BASE="/mnt/synology/jts"
DATE=$(date +%Y%m%d_%H%M%S)

archive_development_data() {
    echo "📋 Syncing development resources to NAS"
    
    if [[ -d "$NAS_BASE" ]]; then
        # Create development directory structure
        mkdir -p "$NAS_BASE/development/notebooks" "$NAS_BASE/development/datasets"
        
        # Sync Jupyter notebooks if directory exists
        [[ -d "/home/joohan/notebooks" ]] && rsync -av --delete /home/joohan/notebooks/ "$NAS_BASE/development/notebooks/" || true
        
        # Sync development datasets if directory exists
        [[ -d "/home/joohan/dev/datasets" ]] && rsync -av --delete /home/joohan/dev/datasets/ "$NAS_BASE/development/datasets/" || true
        
        echo "✅ Development sync completed"
    else
        echo "⚠️ NAS not available - skipping development data sync"
    fi
}

backup_configurations() {
    echo "📋 Backing up system configurations to NAS"
    
    if [[ -d "$NAS_BASE" ]]; then
        mkdir -p "$NAS_BASE/archives/configs/$DATE"
        
        # Backup important configs
        cp -r /etc/fstab "$NAS_BASE/archives/configs/$DATE/" 2>/dev/null || true
        [[ -d "/home/joohan/dev/project-jts/jts/configs" ]] && cp -r /home/joohan/dev/project-jts/jts/configs/ "$NAS_BASE/archives/configs/$DATE/" || true
        
        echo "✅ Configuration backup completed"
    else
        echo "⚠️ NAS not available - skipping configuration backup"
    fi
}

case "${1:-all}" in
    development)
        archive_development_data
        ;;
    configs)
        backup_configurations
        ;;
    all)
        archive_development_data
        backup_configurations
        ;;
    *)
        echo "Usage: $0 {development|configs|all}"
        exit 1
        ;;
esac