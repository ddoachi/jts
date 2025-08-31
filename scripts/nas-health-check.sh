#!/bin/bash
# Generated from: specs/1000/1001/1014.md
# Context: specs/1000/1001/1014.context.md
# Created: 2025-08-26
# Purpose: Monitor cold storage (NAS) connectivity and performance

echo "🧊 JTS Cold Storage (NAS) Health Check - $(date)"
echo "============================================="

# Check NAS connectivity
echo "📡 NAS Connectivity:"
ping -c 2 192.168.1.101 >/dev/null 2>&1 && echo "✅ NAS reachable" || echo "❌ NAS unreachable"

# Check mount status
echo -e "\n💾 Mount Status:"
mount | grep synology || echo "❌ NAS not mounted"

# Check space usage
echo -e "\n📊 Storage Usage:"
df -h /mnt/synology | tail -1

# Check directory structure
echo -e "\n📁 Directory Structure:"
ls -la /mnt/synology/jts/ 2>/dev/null || echo "❌ JTS directory not found"

# Network performance test
echo -e "\n⚡ Network Performance Test:"
timeout 10s dd if=/dev/zero of=/mnt/synology/jts/development/speed_test bs=1M count=50 2>&1 | tail -1
rm -f /mnt/synology/jts/development/speed_test

echo -e "\n🏁 Health check completed at $(date)"