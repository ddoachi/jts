# Environment Configuration Guide

> Generated from spec: E01-F02-T04 (Environment Configuration and Secrets Management)  
> Spec ID: 021bbc7e

## Overview

This guide covers the environment configuration for the JTS (Joohan Trading System) project, including multi-account KIS broker setup, optional Creon integration, and secure credential management.

## Quick Start

1. **Run the setup script:**

   ```bash
   bash scripts/setup-env.sh
   ```

2. **Edit `.env.local` with your credentials**

3. **Validate your configuration:**
   ```bash
   node scripts/validate-env.js
   ```

## Environment Structure

The project uses a two-file environment strategy:

- **`.env.example`** - Template with dummy values (committed to git)
- **`.env.local`** - Your actual credentials (never committed)

## KIS Multi-Account Configuration

The system supports up to 5 KIS accounts. Currently configured for 2 accounts with room for expansion.

### Account Configuration

Each account requires:

```env
KIS_ACCOUNT_1_ID=KIS_001              # Unique identifier
KIS_ACCOUNT_1_NAME=Primary_Account     # Display name
KIS_ACCOUNT_1_APPKEY=your_app_key      # KIS API app key
KIS_ACCOUNT_1_APPSECRET=your_secret    # KIS API app secret
KIS_ACCOUNT_1_NUMBER=your_account_num   # Account number
KIS_ACCOUNT_1_ENABLED=true             # Enable/disable account
```

### Current Setup

- **Account 1 & 2**: Active and required
- **Account 3-5**: Reserved for future expansion

### Rate Limiting

- Per account: 20 requests/second, 200 requests/minute
- Automatically managed by the system

## Creon Configuration (Windows Only)

For Korean market access via Creon:

### Directory Structure

```
/secure/creon/
├── credentials/     # Encrypted credentials
├── scripts/        # Auto-login scripts
└── logs/          # Creon logs
```

### Configuration Variables

```env
CREON_ENABLED=true                                    # Enable Creon
CREON_SCRIPT_PATH=/secure/creon/scripts/creon-launcher.bat
CREON_AUTO_LOGIN_SCRIPT=auto-login.bat               # Your existing script
```

### Setup Steps

1. Create secure directories (automatically done by setup script)
2. Place your auto-login.bat script in `/secure/creon/scripts/`
3. Add encrypted credentials to `/secure/creon/credentials/`
4. Set `CREON_ENABLED=true` in `.env.local`

## Crypto APIs (Optional)

Reserved for future implementation:

### Binance

```env
BINANCE_ENABLED=false
BINANCE_API_KEY=your_key_when_available
BINANCE_SECRET_KEY=your_secret_when_available
```

### Upbit

```env
UPBIT_ENABLED=false
UPBIT_ACCESS_KEY=your_access_when_available
UPBIT_SECRET_KEY=your_secret_when_available
```

## Security Configuration

### Critical Security Variables

⚠️ **Always change these from defaults:**

```env
JWT_SECRET=use-strong-random-string-here
SESSION_SECRET=another-strong-random-string
ENCRYPTION_KEY=yet-another-strong-key
```

### Security Best Practices

1. **Never commit `.env.local`** - It's gitignored for a reason
2. **Use strong, unique passwords** - Avoid dictionary words
3. **Rotate keys regularly** - Especially after team changes
4. **Limit file permissions** - Keep credentials readable only by owner
5. **Use encryption** - Store sensitive data encrypted when possible

## Database Configuration

### Development Databases

```env
DATABASE_URL=postgresql://user:pass@localhost:5432/jts_dev
CLICKHOUSE_URL=http://user:pass@localhost:8123/jts_market
MONGODB_URL=mongodb://user:pass@localhost:27017/jts_config
REDIS_URL=redis://localhost:6379
```

### Test Databases

```env
TEST_DATABASE_URL=postgresql://user:pass@localhost:5432/jts_test
TEST_REDIS_URL=redis://localhost:6380
```

## Validation

Run the validation script to check your configuration:

```bash
node scripts/validate-env.js
```

The validator checks:

- File existence
- Required variables
- Security settings
- KIS account configuration
- Database connections

### Validation Output

- ✅ **Green**: Properly configured
- ⚠️ **Yellow**: Warnings (non-critical)
- ❌ **Red**: Errors (must fix)
- ℹ️ **Cyan**: Informational

## Troubleshooting

### Common Issues

1. **`.env.local` not found**

   ```bash
   cp .env.example .env.local
   ```

2. **KIS credentials not working**
   - Verify APP_KEY and APP_SECRET from KIS developer portal
   - Check account number format
   - Ensure account is enabled (`KIS_ACCOUNT_X_ENABLED=true`)

3. **Creon not connecting (Windows)**
   - Check if `/secure/creon/` directories exist
   - Verify auto-login.bat script permissions
   - Check Windows firewall settings

4. **JWT_SECRET warning**
   - Generate a strong secret: `openssl rand -base64 32`
   - Update in `.env.local`

### Environment Variables Reference

See `.env.example` for the complete list of available variables with descriptions.

## Files Created by This Spec

| File                      | Purpose              | Location     |
| ------------------------- | -------------------- | ------------ |
| `.env.example`            | Environment template | Project root |
| `scripts/setup-env.sh`    | Setup script         | `/scripts/`  |
| `scripts/validate-env.js` | Validation utility   | `/scripts/`  |
| `docs/ENVIRONMENT.md`     | This documentation   | `/docs/`     |
| `.gitignore` updates      | Security patterns    | Project root |

## Related Specifications

- **Parent**: E01-F02 (Broker Integration Foundation)
- **Blocks**: T05 (Broker Connection Manager), T06 (API Client Implementation)

## Support

For issues or questions about environment configuration, refer to:

1. This documentation
2. The validation script output
3. The project's issue tracker
