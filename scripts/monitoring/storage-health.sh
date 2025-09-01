#!/bin/bash
# Generated from spec: E01-F01-T06 (Tiered Storage Management)
# Spec ID: 08fe2621

echo "🔍 JTS Tiered Storage Health Check - $(date)"
echo "================================================"

# Hot tier (NVMe) status
echo "🔥 Hot Tier (NVMe) Status:"
if command -v vgdisplay >/dev/null 2>&1; then
    vgdisplay vg_jts | grep -E "(VG Name|VG Status|VG Size|Free)"
    echo -e "\nLogical Volume Usage:"
    df -h | grep -E "(Filesystem|vg_jts)" | column -t
else
    echo "LVM not available - Hot tier not configured"
fi

# Warm tier (SATA) status
echo -e "\n🌡️ Warm Tier (SATA) Status:"
if mountpoint -q "/data/warm-storage"; then
    df -h /data/warm-storage | tail -1
    btrfs filesystem show /data/warm-storage 2>/dev/null || echo "Btrfs info unavailable"
else
    echo "Warm storage not mounted"
fi

# Cold tier (NAS) status
echo -e "\n🧊 Cold Tier (NAS) Status:"
if mountpoint -q "/mnt/synology"; then
    df -h /mnt/synology | tail -1
    ping -c 2 192.168.1.101 >/dev/null 2>&1 && echo "✅ NAS reachable" || echo "❌ NAS unreachable"
else
    echo "NAS not mounted"
fi

# Usage alerts across all tiers
echo -e "\n⚠️ Usage Alerts:"
df -h | awk 'NR>1 && /vg_jts|warm-storage|synology/ {
    gsub(/%/, "", $5);
    if ($5 > 90) print "CRITICAL: " $6 " usage at " $5 "%"
    else if ($5 > 80) print "WARNING: " $6 " usage at " $5 "%"
}'