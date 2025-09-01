#!/bin/bash
# Rollback script for spec migration
# Generated: 2025-08-29T21:22:13.929428

echo "Rolling back spec migration..."

# Remove new structure
rm -rf specs/

# Restore backup
cp -r specs_backup_20250829_212213/ specs/

echo "Rollback complete!"
echo "Original structure restored from specs_backup_20250829_212213"
