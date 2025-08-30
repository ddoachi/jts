#!/bin/bash
# Generated from spec: E01-F01-T06 (Tiered Storage Management)
# Spec ID: 08fe2621

set -euo pipefail

HOT_TIER="/var/lib"
WARM_TIER="/data/warm-storage"
COLD_TIER="/mnt/synology/jts"

migrate_logs_to_warm() {
    echo "📎 Moving old logs to warm storage"
    
    if [[ -d "$WARM_TIER" ]]; then
        # Create logs directory if it doesn't exist
        mkdir -p "$WARM_TIER/logs"
        
        # Move logs older than 7 days to warm tier
        find /var/log -name "*.log" -mtime +7 -exec mv {} "$WARM_TIER/logs/" \; 2>/dev/null || true
        
        # Compress moved logs
        find "$WARM_TIER/logs/" -name "*.log" -exec gzip {} \; 2>/dev/null || true
        
        echo "✅ Log migration to warm tier completed"
    else
        echo "⚠️ Warm tier not available - skipping log migration"
    fi
}

migrate_backups_to_cold() {
    echo "📎 Moving old backups to cold storage"
    
    if [[ -d "$COLD_TIER" && -d "$WARM_TIER" ]]; then
        # Create archives directory if it doesn't exist
        mkdir -p "$COLD_TIER/archives" "$WARM_TIER/daily-backups"
        
        # Move backups older than 30 days to cold tier
        find "$WARM_TIER/daily-backups/" -mtime +30 -exec mv {} "$COLD_TIER/archives/" \; 2>/dev/null || true
        
        echo "✅ Backup migration to cold tier completed"
    else
        echo "⚠️ Cold or warm tier not available - skipping backup migration"
    fi
}

cleanup_temp_files() {
    echo "🧹 Cleaning up temporary files"
    
    # Clean up temp processing files older than 3 days
    if [[ -d "$WARM_TIER/temp-processing" ]]; then
        find "$WARM_TIER/temp-processing/" -mtime +3 -delete 2>/dev/null || true
    fi
    
    # Clean up Docker temp files if Docker is available
    if command -v docker >/dev/null 2>&1; then
        docker system prune -f --volumes 2>/dev/null || true
    fi
    
    echo "✅ Temporary file cleanup completed"
}

case "${1:-check}" in
    migrate)
        migrate_logs_to_warm
        migrate_backups_to_cold
        ;;
    cleanup)
        cleanup_temp_files
        ;;
    all)
        migrate_logs_to_warm
        migrate_backups_to_cold
        cleanup_temp_files
        ;;
    *)
        echo "Usage: $0 {migrate|cleanup|all}"
        exit 1
        ;;
esac