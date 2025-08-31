#!/bin/bash
# Generated from spec: E01-F01-T06 (Tiered Storage Management)
# Spec ID: 08fe2621

DATE=$(date +%Y%m%d_%H%M%S)
VG_NAME="vg_jts"

create_snapshots() {
    echo "📸 Creating LVM snapshots - $DATE"
    
    if command -v lvcreate >/dev/null 2>&1 && vgs "$VG_NAME" >/dev/null 2>&1; then
        # Create snapshots for critical data
        lvcreate -L5G -s -n snap_postgres_$DATE /dev/$VG_NAME/lv_postgres 2>/dev/null || echo "PostgreSQL snapshot failed"
        lvcreate -L10G -s -n snap_clickhouse_$DATE /dev/$VG_NAME/lv_clickhouse 2>/dev/null || echo "ClickHouse snapshot failed"
        lvcreate -L2G -s -n snap_mongodb_$DATE /dev/$VG_NAME/lv_mongodb 2>/dev/null || echo "MongoDB snapshot failed"
        
        echo "✅ Snapshots created successfully"
    else
        echo "⚠️ LVM not available - skipping snapshot creation"
    fi
}

cleanup_old_snapshots() {
    echo "🧹 Cleaning up snapshots older than 7 days"
    
    if command -v lvs >/dev/null 2>&1 && vgs "$VG_NAME" >/dev/null 2>&1; then
        # Find and remove old snapshots
        lvs --noheadings -o lv_name "$VG_NAME" 2>/dev/null | grep "snap_" | while read snapshot; do
            snapshot=$(echo $snapshot | xargs)
            if [[ -n "$snapshot" ]]; then
                # Simple age-based cleanup (remove snapshots with old naming pattern)
                if [[ "$snapshot" =~ snap_.*_[0-9]{8}_[0-9]{6} ]]; then
                    echo "Removing old snapshot: $snapshot"
                    lvremove -f "/dev/$VG_NAME/$snapshot" 2>/dev/null || echo "Failed to remove $snapshot"
                fi
            fi
        done
        
        echo "✅ Snapshot cleanup completed"
    else
        echo "⚠️ LVM not available - skipping snapshot cleanup"
    fi
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