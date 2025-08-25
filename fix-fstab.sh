#!/bin/bash
# Fix the malformed fstab entry

echo "Fixing /etc/fstab parsing error..."

# Create a corrected version
sudo cp /etc/fstab /etc/fstab.broken
sudo sed -i 's|0 0/dev/sda2|0 0\n/dev/sda2|' /etc/fstab

echo "Fixed fstab. Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Testing mount..."
sudo mount /data/warm-storage

echo "Fstab fixed successfully!"