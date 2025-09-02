#!/bin/bash
echo "JTS Hot Storage Usage Report - $(date)"
echo "=================================="
du -sh /data/jts/hot/*/ | sort -hr
echo ""
echo "Available space on NVMe:"
df -h / | tail -1
