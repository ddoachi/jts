# Configuration Directory Structure

This directory contains all configuration files for the JTS trading system, organized by category for better maintainability and clarity.

## Directory Structure

```
configs/
├── database/          # Database configurations
├── services/          # Service-specific configurations  
├── environment/       # Development environment configs
├── security/          # Security configs (non-sensitive)
├── monitoring/        # System monitoring and optimization
└── docker/            # Container and orchestration configs
```

## Directory Purpose

### `/database/`
Contains database configuration files:
- `clickhouse-config.xml` - ClickHouse time-series database configuration
- `redis.conf` - Redis cache and session store configuration

### `/services/`
Contains service-specific configuration files:
- `telegram.config.json` - Telegram bot integration settings
- `rollback_migration.sh` - Database migration rollback script
- `migration_log.json` - Migration execution log

### `/environment/`
Contains development environment and tooling configurations:
- `.pre-commit-config.yaml` - Pre-commit hooks configuration
- `eslint.config.js` - ESLint code quality rules
- `lint-staged.config.js` - Lint-staged configuration
- `gitignore.template` - Template for .gitignore files
- `package.json.template` - Template for package.json files

### `/security/`
Reserved for security-related configurations (certificates, keys - non-sensitive only).
Note: Sensitive keys and secrets should always be stored in environment variables or secure vaults.

### `/monitoring/`
Contains system monitoring, optimization and infrastructure configurations:
- `60-ssd-scheduler.rules` - SSD I/O scheduler optimization rules
- `sysctl-nas-optimization.conf` - System kernel parameter optimization
- `fstab-nas-mount.conf` - Network attached storage mount configuration
- `fstab.backup.*` - Backup of fstab configurations
- `fstrim-all.service` - Systemd service for SSD maintenance
- `fstrim-all.timer` - Systemd timer for automated SSD trimming
- `tiered-storage.service` - Systemd service for tiered storage management
- `tiered-storage.timer` - Systemd timer for tiered storage operations

### `/docker/`
Contains Docker and container orchestration configurations:
- `docker-compose.dev.yml` - Development environment Docker Compose configuration

## Usage Notes

1. **Environment-specific configs**: Use environment variables for sensitive data
2. **Template files**: Use `.template` suffix for template configurations
3. **Backup files**: Keep backup configurations with timestamp suffix
4. **Service configs**: Group related service configurations together
5. **Docker configs**: Separate development and production Docker configurations

## Configuration Loading Order

1. Default configurations from this directory
2. Environment-specific overrides (dev, staging, prod)
3. Local environment variables
4. Runtime configuration updates

## Security Guidelines

- Never commit sensitive data (passwords, API keys, certificates)
- Use environment variables for secrets
- Keep template files for documentation
- Regular backup of critical configurations