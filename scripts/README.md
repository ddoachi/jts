# JTS Scripts Directory

This directory contains all scripts used for the JTS automated trading system, organized by functionality for better maintainability and discoverability.

## Directory Structure

```
scripts/
├── build/             # Build and compilation scripts
├── database/          # Database management and initialization scripts
├── deployment/        # Deployment and infrastructure scripts
├── development/       # Development utilities and tools
├── maintenance/       # System maintenance and cleanup scripts
├── monitoring/        # System monitoring and health check scripts
└── utilities/         # General utility scripts and tools
```

## Directory Descriptions

### `/build/` - Build and Compilation Scripts
Scripts for building, installing dependencies, and preparing the development environment.

- `docker-setup.sh` - Docker installation and configuration for Linux/WSL
- `install-node-yarn-linux.sh` - Node.js and Yarn installation for Linux
- `install-node-yarn-windows.ps1` - Node.js and Yarn installation for Windows
- `install-node-yarn.sh` - Generic Node.js and Yarn installation script

### `/database/` - Database Management Scripts
Scripts for database initialization, user management, and data operations.

- `init-mongo.js` - MongoDB database initialization and configuration
- `init-postgres.sql` - PostgreSQL database initialization and schema setup
- `setup-database-users.sh` - Create and configure database service users
- `sync-database.ts` - Database synchronization utilities

### `/deployment/` - Deployment Scripts
Scripts for production deployment and credential management.

- `creon-launcher.bat` - Creon trading platform auto-login wrapper
- `decrypt-and-run.ps1` - PowerShell script for secure credential decryption
- `encrypt-credentials.ps1` - PowerShell script for credential encryption

### `/development/` - Development Utilities
Scripts for development environment setup and service management.

- `check-services-health.js` - Health check for all development services
- `dev-services.sh` - Docker service management for development environment
- `setup-dev-env.sh` - Complete development environment setup
- `setup-env.sh` - Environment configuration and validation
- `validate-env.js` - Environment variable validation utility

### `/maintenance/` - System Maintenance Scripts
Scripts for system maintenance, fixes, and cleanup operations.

- `configure-permissions.sh` - System permissions configuration and fixes
- `fix-test-issues.sh` - Automated fixes for common test issues
- `lvm-backup.sh` - Logical Volume Manager backup operations
- `nas-archival.sh` - Network storage archival operations
- `tiered-storage.sh` - Storage tier management and optimization

### `/monitoring/` - System Monitoring Scripts
Scripts for system health monitoring, performance benchmarking, and alerting.

- `hot-storage-monitor.sh` - Real-time monitoring for hot storage (NVMe)
- `jts-storage-monitor.sh` - Comprehensive JTS storage system monitoring
- `nas-health-check.sh` - Network storage health verification
- `performance-benchmark.sh` - Storage performance benchmarking suite
- `sata-health-check.sh` - SATA drive health monitoring
- `storage-health.sh` - General storage system health checks

### `/utilities/` - General Utility Scripts
General-purpose scripts for various system operations, testing, and validation.

- `fix-spec-ids.py` - Fix and update specification IDs
- `generate-index.ts` - Generate project index files
- `migrate-spec-structure.py` - Migrate specification structure
- `parse-specs.ts` - Parse and process specification files
- `revert-spec-links.ts` - Revert specification link changes
- `setup-hot-directories.sh` - Setup high-performance storage directories
- `setup-mount-points.sh` - Configure system mount points
- `setup-sata-storage.sh` - SATA storage configuration
- `ssd-optimization.sh` - SSD performance optimization
- `test-database-mounts.sh` - Test database storage mount points
- `test-summary.sh` - Generate test execution summaries
- `validate-database-mounts.sh` - Validate database mount configurations
- `validate-directories.sh` - Directory structure validation

## Usage Guidelines

### Execution Permissions
Most scripts maintain their original executable permissions. To run a script:

```bash
# For shell scripts (.sh)
./script-name.sh

# For Node.js scripts (.js)
node script-name.js

# For TypeScript scripts (.ts)
npx ts-node script-name.ts

# For Python scripts (.py)
python3 script-name.py
```

### Common Requirements
- **Linux/Unix environment**: Most shell scripts are designed for Linux/Unix systems
- **Node.js**: Required for JavaScript/TypeScript scripts
- **Python 3**: Required for Python scripts
- **Docker**: Required for containerized services
- **Appropriate permissions**: Some scripts may require `sudo` privileges

### Script Dependencies
Many scripts have dependencies on:
- Docker and Docker Compose
- Node.js and npm/yarn
- PostgreSQL, MongoDB, ClickHouse, Redis
- System utilities (lvm, mount, etc.)

## Development Notes

### Script Conventions
- Use `#!/bin/bash` shebang for shell scripts
- Include error handling with `set -e` or `set -euo pipefail`
- Use consistent color coding for output messages
- Include descriptive comments and usage instructions

### Adding New Scripts
When adding new scripts:
1. Place them in the appropriate directory based on functionality
2. Ensure proper executable permissions (`chmod +x`)
3. Follow existing naming conventions
4. Update this README if adding new categories

### Maintenance
- Regularly review and update script dependencies
- Test scripts in clean environments
- Keep documentation current with actual functionality
- Remove or deprecate unused scripts

## Troubleshooting

### Common Issues
1. **Permission Denied**: Check executable permissions with `ls -la`
2. **Command Not Found**: Ensure required dependencies are installed
3. **Path Issues**: Scripts may need to be run from specific directories
4. **Environment Variables**: Check that required environment variables are set

### Getting Help
- Check script headers for usage instructions
- Review error messages and logs
- Consult project documentation in the main repository
- Check related specification documents in the project

---

For more information about the JTS project structure and development guidelines, see the main project documentation.