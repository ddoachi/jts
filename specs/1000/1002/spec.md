---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '1002' # Numeric ID for stable reference
title: 'Development Environment Setup'
type: 'feature' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '1000' # Parent spec ID (leave empty for top-level)
children: ['1021', '1022', '1023', '1024', '1025', '1026'] # Task breakdowns
epic: '1000' # Root epic ID for this work
domain: 'infrastructure' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low

# === TRACKING ===
created: '2025-08-24' # YYYY-MM-DD
updated: '2025-08-24' # YYYY-MM-DD
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 8 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: [] # Must be done before this (spec IDs)
blocks: ['1003', '1004', '1005'] # This blocks these specs
related: ['1001'] # Related but not blocking (spec IDs)

# === IMPLEMENTATION ===
pull_requests: [] # GitHub PR numbers
commits: [] # Key implementation commits
context_file: "context.md" # Implementation journal
files: ['.vscode/settings.json', '.vscode/extensions.json', 'package.json', '.env.example', 'docker-compose.dev.yml', 'docs/DEVELOPMENT.md'] # Key files to modify

# === METADATA ===
tags: ['development', 'setup', 'ide', 'tools', 'workflow'] # Searchable tags
effort: 'medium' # small | medium | large | epic
risk: 'low' # low | medium | high

# ============================================================================
---

# Development Environment Setup

## Overview

Establish a standardized development environment for the JTS automated trading system to ensure consistent tooling, configuration, and workflows across all developers. This includes workstation setup, IDE configuration, required tools installation, secrets management, and local development processes.

## Acceptance Criteria

- [ ] **Node.js Environment**: Node.js 20+ with Yarn package manager
- [ ] **IDE Configuration**: VS Code configured with project-specific settings and extensions
- [ ] **Development Tools**: Docker Desktop, Git, and CLI tools installed
- [ ] **Environment Variables**: Secure secrets management with `.env` templates
- [ ] **Local Development**: Working docker-compose setup for all services
- [ ] **Code Quality Tools**: Pre-commit hooks, linting, and formatting configured
- [ ] **Database Tools**: Database clients and management tools installed
- [ ] **Documentation**: Complete developer onboarding guide
- [ ] **Platform Support**: Setup instructions for Linux and Windows (WSL2)
- [ ] **Service Discovery**: Local service registry and health monitoring

## Technical Approach

### Developer Workstation Requirements

#### System Requirements
```yaml
Minimum Specifications:
  CPU: 8 cores (Intel i7 or AMD Ryzen 7)
  RAM: 16GB DDR4 (32GB recommended)
  Storage: 500GB SSD (1TB recommended)
  Network: Stable internet connection for market data

Recommended for Performance:
  CPU: 12+ cores (Intel i9 or AMD Ryzen 9)
  RAM: 32GB DDR4
  Storage: 1TB NVMe SSD
  GPU: Dedicated GPU for chart rendering (optional)
```

#### Operating System Support
- **Linux (Primary)**: Ubuntu 22.04+ or equivalent for main development
- **Windows (Secondary)**: Windows 11 with WSL2 for Creon API integration

### Required Tools and SDKs

#### Core Development Tools
```bash
# Node.js and Package Managers
Node.js: 20.x LTS
Yarn: 4.x (Berry) - Primary package manager

# Version Control
Git: 2.40+
GitHub CLI: 2.30+ (gh)

# Containerization
Docker Desktop: 4.20+ with Compose V2
Docker Engine: 24.0+ (Linux)

# Database Tools
pgAdmin: 4.30+ (PostgreSQL)
MongoDB Compass: 1.35+ (MongoDB)
ClickHouse Client: 23.8+ (CLI)
Redis Insight: 2.30+ (Redis GUI)

# Development Utilities
curl/wget: HTTP testing
jq: JSON processing
HTTPie: API testing
Postman: API development (optional)
```

#### Platform-Specific Installation Scripts

**Linux/Ubuntu Setup**:
```bash
#!/bin/bash
# install-dev-tools-linux.sh

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Yarn 4 (Berry)
corepack enable
yarn set version stable

# Install Docker
sudo apt-get install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Install additional tools
sudo apt-get install -y git curl wget jq httpie postgresql-client-common redis-tools

# Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh
```

**Windows Setup (PowerShell)**:
```powershell
# install-dev-tools-windows.ps1
# Requires PowerShell as Administrator

# Install Chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install development tools
choco install nodejs-lts git docker-desktop -y

# Install Yarn 4
corepack enable
corepack prepare yarn@stable --activate
choco install postgresql pgadmin4 mongodb mongodb-compass redis-desktop-manager -y
choco install gh jq httpie postman -y

# Install IDEs
choco install vscode webstorm -y

# Enable WSL2 for Linux compatibility
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

### IDE Configuration

**VS Code Setup** (Primary Development Environment)

**Extensions Configuration** (`.vscode/extensions.json`):
```json
{
  "recommendations": [
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-json",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-vscode.vscode-docker",
    "redhat.vscode-yaml",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "ms-vscode.vscode-jest",
    "rangav.vscode-thunder-client",
    "ms-vscode.vscode-postgres",
    "mongodb.mongodb-vscode",
    "cweijan.vscode-redis-client",
    "nrwl.angular-console",
    "ms-vscode.vscode-npm-dependency-links"
  ],
  "unwantedRecommendations": [
    "ms-vscode.vscode-typescript"
  ]
}
```

**Workspace Settings** (`.vscode/settings.json`):
```json
{
  "typescript.preferences.importModuleSpecifier": "relative",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "files.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.nx": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.nx": true
  },
  "emmet.includeLanguages": {
    "typescript": "html",
    "typescriptreact": "html"
  },
  "tailwindCSS.includeLanguages": {
    "typescript": "html",
    "typescriptreact": "html"
  },
  "docker.defaultRegistryPath": "localhost:5000",
  "jest.jestCommandLine": "npx nx test",
  "mongodb.connectionSaving": "Workspace",
  "thunder-client.workspaceRelativePath": "thunder-tests"
}
```

**Debug Configuration** (`.vscode/launch.json`):
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug API Gateway",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/dist/apps/api-gateway/main.js",
      "env": {
        "NODE_ENV": "development"
      },
      "console": "integratedTerminal",
      "restart": true,
      "runtimeArgs": ["--nolazy"],
      "sourceMaps": true,
      "cwd": "${workspaceFolder}",
      "protocol": "inspector"
    },
    {
      "name": "Debug Strategy Engine",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/dist/apps/strategy-engine/main.js",
      "env": {
        "NODE_ENV": "development"
      },
      "console": "integratedTerminal",
      "restart": true
    },
    {
      "name": "Debug Tests",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/node_modules/.bin/jest",
      "args": ["--runInBand"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen",
      "disableOptimisticBPs": true,
      "windows": {
        "program": "${workspaceFolder}/node_modules/jest/bin/jest"
      }
    }
  ]
}
```

### Environment Variables and Secrets Management

#### Two-File Strategy

We use a simple two-file approach for environment configuration:
- `.env.example` - Template with dummy values (committed to repository)
- `.env.local` - Your actual credentials (gitignored, never committed)

#### Environment File Templates

**Example Template** (`.env.example`):
```env
# Application Configuration
NODE_ENV=development
PORT=3000
API_VERSION=v1

# Database URLs (Local Development)
DATABASE_URL=postgresql://jts_admin:dev_password@localhost:5432/jts_trading_dev
CLICKHOUSE_URL=http://jts_ch:dev_password@localhost:8123/jts_market_data_dev
MONGODB_URL=mongodb://jts_mongo:dev_password@localhost:27017/jts_config_dev
REDIS_URL=redis://localhost:6379

# Kafka Configuration
KAFKA_BROKERS=localhost:9092
KAFKA_CLIENT_ID=jts-dev
KAFKA_GROUP_ID=jts-trading-dev

# JWT Configuration (Development Only)
JWT_SECRET=dev-jwt-secret-key-not-for-production
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Rate Limiting
RATE_LIMIT_WINDOW=60000
RATE_LIMIT_MAX_REQUESTS=1000

# KIS Rate Limiting Configuration
KIS_RATE_LIMIT_PER_ACCOUNT_PER_SECOND=20
KIS_RATE_LIMIT_PER_ACCOUNT_PER_15SEC=60
KIS_TOTAL_ACCOUNTS=2

# Logging
LOG_LEVEL=debug
LOG_FORMAT=combined

# Creon Configuration (Windows - uses batch script)
CREON_SCRIPT_PATH=/secure/creon/scripts/creon-launcher.bat
CREON_CREDENTIALS_PATH=/secure/creon/credentials/account.encrypted
CREON_LOG_PATH=/secure/creon/logs/

# KIS API Keys (Development/Sandbox) - Account 1
KIS_ACCOUNT_1_ID=KIS_001
KIS_ACCOUNT_1_APPKEY=dev_kis_appkey_1
KIS_ACCOUNT_1_APPSECRET=dev_kis_appsecret_1
KIS_ACCOUNT_1_NUMBER=12345678-01

# KIS API Keys (Development/Sandbox) - Account 2
KIS_ACCOUNT_2_ID=KIS_002
KIS_ACCOUNT_2_APPKEY=dev_kis_appkey_2
KIS_ACCOUNT_2_APPSECRET=dev_kis_appsecret_2
KIS_ACCOUNT_2_NUMBER=12345678-02
BINANCE_API_KEY=dev_binance_key
BINANCE_SECRET_KEY=dev_binance_secret
UPBIT_ACCESS_KEY=dev_upbit_access
UPBIT_SECRET_KEY=dev_upbit_secret

# Development Features
ENABLE_SWAGGER=true
ENABLE_DEBUG_ROUTES=true
ENABLE_MOCK_DATA=true
```

**Local Configuration** (`.env.local` - copy from `.env.example` and customize):
```env
# Copy this from .env.example and add your real credentials
# This file is gitignored and should never be committed

# Application Configuration
NODE_ENV=development
PORT=3000
API_VERSION=v1

# Database URLs (Add your local credentials)
DATABASE_URL=postgresql://your_user:your_password@localhost:5432/jts_trading_dev
CLICKHOUSE_URL=http://your_user:your_password@localhost:8123/jts_market_data_dev
MONGODB_URL=mongodb://your_user:your_password@localhost:27017/jts_config_dev
REDIS_URL=redis://localhost:6379

# Kafka Configuration
KAFKA_BROKERS=localhost:9092
KAFKA_CLIENT_ID=jts-dev
KAFKA_GROUP_ID=jts-trading-dev

# JWT Configuration (Use your own secret)
JWT_SECRET=your-dev-jwt-secret-key-here
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Rate Limiting
RATE_LIMIT_WINDOW=60000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# Creon Configuration (CHANGE THESE)
CREON_SCRIPT_PATH=/secure/creon/scripts/creon-launcher.bat
CREON_CREDENTIALS_PATH=/secure/creon/credentials/account.encrypted
CREON_LOG_PATH=/secure/creon/logs/

# KIS API Keys (CHANGE THESE) - Account 1
KIS_ACCOUNT_1_ID=KIS_PROD_001
KIS_ACCOUNT_1_APPKEY=your_production_kis_appkey_1
KIS_ACCOUNT_1_APPSECRET=your_production_kis_appsecret_1
KIS_ACCOUNT_1_NUMBER=your_account_number_1

# KIS API Keys (CHANGE THESE) - Account 2
KIS_ACCOUNT_2_ID=KIS_PROD_002
KIS_ACCOUNT_2_APPKEY=your_production_kis_appkey_2
KIS_ACCOUNT_2_APPSECRET=your_production_kis_appsecret_2
KIS_ACCOUNT_2_NUMBER=your_account_number_2
BINANCE_API_KEY=your_production_binance_key
BINANCE_SECRET_KEY=your_production_binance_secret
UPBIT_ACCESS_KEY=your_production_upbit_access
UPBIT_SECRET_KEY=your_production_upbit_secret

# Development Features
ENABLE_SWAGGER=true
ENABLE_DEBUG_ROUTES=true
ENABLE_MOCK_DATA=true
```

#### Secrets Management Strategy

```bash
# Initial Setup - Create your local configuration
cp .env.example .env.local

# Edit .env.local with your actual credentials
# This file is gitignored and never committed

# Configuration Loading Priority:
# 1. .env.local (if exists) - Your actual credentials
# 2. .env.example (fallback) - Template with dummy values

# For Production Environments:
# Use proper secret managers (AWS Secrets Manager, HashiCorp Vault, etc.)
# Never use .env files in production
```

**Why Two Files?**
- `.env.example` serves as documentation for required variables
- `.env.local` keeps your real credentials safe from accidental commits
- Easy onboarding - new developers just copy and customize
- Clean separation between template and actual configuration

### Secure Creon Authentication

Since Creon uses COM objects on Windows and requires login credentials instead of API keys, we need a secure approach:

**Directory Structure**:
```bash
/secure/creon/
├── credentials/
│   └── account.encrypted    # Encrypted ID/password (never in plain text)
├── scripts/
│   ├── creon-launcher.bat  # Template batch script
│   └── decrypt-and-run.ps1 # PowerShell wrapper for secure execution
└── logs/
    └── auth-audit.log      # Authentication audit trail
```

**Secure Batch Script Template** (`creon-launcher.bat`):
```batch
@echo off
REM This is a template - actual credentials are injected at runtime
set CREON_ID=%1
set CREON_PW=%2
start /wait creon.exe /ID:%CREON_ID% /PW:%CREON_PW% /AUTOSTART
```

**PowerShell Security Wrapper** (`decrypt-and-run.ps1`):
```powershell
# Decrypt credentials from secure storage
$encryptedPath = "$env:CREON_CREDENTIALS_PATH"
$credentials = Decrypt-SecureString -Path $encryptedPath

# Run Creon with decrypted credentials
$process = Start-Process "creon-launcher.bat" -ArgumentList $credentials.Id, $credentials.Password -Wait

# Log authentication attempt
Add-Content -Path "$env:CREON_LOG_PATH/auth-audit.log" -Value "$(Get-Date): Creon authentication attempted"

# Clear credentials from memory
$credentials = $null
```

**Security Notes**:
- Never store Creon credentials in plain text
- Use Windows Credential Manager or encrypted files
- Audit all authentication attempts
- Run on isolated Windows machine for additional security

### Local Development Workflow

#### Docker Compose Development Setup

**Development Services** (`docker-compose.dev.yml`):
```yaml
version: '3.8'

services:
  # Database Services
  postgres:
    image: postgres:15-alpine
    container_name: jts-postgres-dev
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: jts_trading_dev
      POSTGRES_USER: jts_admin
      POSTGRES_PASSWORD: dev_password
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U jts_admin -d jts_trading_dev"]
      interval: 10s
      timeout: 5s
      retries: 5

  clickhouse:
    image: clickhouse/clickhouse-server:23.8
    container_name: jts-clickhouse-dev
    restart: unless-stopped
    ports:
      - "8123:8123"
      - "9000:9000"
    environment:
      CLICKHOUSE_DB: jts_market_data_dev
      CLICKHOUSE_USER: jts_ch
      CLICKHOUSE_PASSWORD: dev_password
    volumes:
      - clickhouse_dev_data:/var/lib/clickhouse
      - ./configs/clickhouse-config.xml:/etc/clickhouse-server/config.xml
    ulimits:
      nofile:
        soft: 262144
        hard: 262144

  mongodb:
    image: mongo:7
    container_name: jts-mongodb-dev
    restart: unless-stopped
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: jts_mongo
      MONGO_INITDB_ROOT_PASSWORD: dev_password
      MONGO_INITDB_DATABASE: jts_config_dev
    volumes:
      - mongodb_dev_data:/data/db
      - ./scripts/init-mongo.js:/docker-entrypoint-initdb.d/init-mongo.js

  redis:
    image: redis:7-alpine
    container_name: jts-redis-dev
    restart: unless-stopped
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes --requirepass dev_password
    volumes:
      - redis_dev_data:/data

  # Message Queue
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: jts-zookeeper-dev
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: jts-kafka-dev
    restart: unless-stopped
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: true
    volumes:
      - kafka_dev_data:/var/lib/kafka/data

  # Development Tools
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: jts-kafka-ui-dev
    restart: unless-stopped
    depends_on:
      - kafka
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: jts-dev
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:29092

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: jts-pgadmin-dev
    restart: unless-stopped
    depends_on:
      - postgres
    ports:
      - "5050:80"
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@jts.dev
      PGADMIN_DEFAULT_PASSWORD: dev_password
    volumes:
      - pgadmin_dev_data:/var/lib/pgadmin

volumes:
  postgres_dev_data:
  clickhouse_dev_data:
  mongodb_dev_data:
  redis_dev_data:
  kafka_dev_data:
  pgadmin_dev_data:

  # Multi-Account Monitoring (Optional)
  account-monitor:
    image: grafana/grafana:latest
    container_name: jts-account-monitor-dev
    restart: unless-stopped
    ports:
      - "3100:3000"  # Grafana UI for monitoring accounts
    environment:
      GF_SECURITY_ADMIN_PASSWORD: dev_password
      GF_INSTALL_PLUGINS: redis-datasource
    volumes:
      - grafana_dev_data:/var/lib/grafana
    depends_on:
      - redis

volumes:
  grafana_dev_data:

networks:
  default:
    name: jts-dev-network
```

**Redis Database Allocation for Multi-Account**:
```yaml
# Redis databases for different purposes
Redis DB Allocation:
  0: Session cache
  1: KIS account 1 rate limits
  2: KIS account 2 rate limits  
  3: Surge detection cache
  4: Order queue
  5: Account metrics
```

#### Development Scripts

**Package.json Scripts**:
```json
{
  "scripts": {
    "dev:setup": "scripts/setup-dev-env.sh",
    "dev:start": "docker-compose -f docker-compose.dev.yml up -d",
    "dev:stop": "docker-compose -f docker-compose.dev.yml down",
    "dev:clean": "docker-compose -f docker-compose.dev.yml down -v --remove-orphans",
    "dev:logs": "docker-compose -f docker-compose.dev.yml logs -f",
    "dev:status": "docker-compose -f docker-compose.dev.yml ps",
    
    "db:migrate": "yarn db:migrate:postgres && yarn db:migrate:clickhouse",
    "db:migrate:postgres": "yarn prisma migrate deploy",
    "db:migrate:clickhouse": "node scripts/migrate-clickhouse.js",
    "db:seed": "yarn db:seed:postgres && yarn db:seed:clickhouse",
    "db:seed:postgres": "yarn prisma db seed",
    "db:seed:clickhouse": "node scripts/seed-clickhouse.js",
    "db:reset": "yarn db:reset:postgres && yarn db:reset:clickhouse",
    
    "services:health": "node scripts/check-services-health.js",
    "services:start": "concurrently \"yarn start:gateway\" \"yarn start:strategy\" \"yarn start:risk\" \"yarn start:order\" \"yarn start:market-data\"",
    "start:gateway": "nx serve api-gateway",
    "start:strategy": "nx serve strategy-engine",
    "start:risk": "nx serve risk-management",
    "start:order": "nx serve order-execution",
    "start:market-data": "nx serve market-data-collector"
  }
}
```

**Setup Script** (`scripts/setup-dev-env.sh`):
```bash
#!/bin/bash
set -e

echo "🚀 Setting up JTS development environment..."

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "❌ Git is required"; exit 1; }

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
    echo "❌ Node.js 20+ is required (found: $(node -v))"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Install dependencies
echo "📦 Installing dependencies..."
yarn install

# Copy environment file
if [ ! -f .env.local ]; then
    echo "🔧 Creating .env.local from template..."
    cp .env.example .env.local
    echo "⚠️  Please review and update .env.local with your actual credentials"
fi

# Start infrastructure services
echo "🐳 Starting infrastructure services..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
yarn services:health

# Run database migrations
echo "🗄️  Running database migrations..."
sleep 10  # Give databases time to fully start
yarn db:migrate

# Seed development data
echo "🌱 Seeding development data..."
yarn db:seed

echo "✅ Development environment setup complete!"
echo ""
echo "🎯 Next steps:"
echo "  1. Review .env.local settings"
echo "  2. Start development servers: yarn services:start"
echo "  3. Open http://localhost:3000 for API Gateway"
echo "  4. Access Kafka UI at http://localhost:8080"
echo "  5. Access pgAdmin at http://localhost:5050"
echo ""
echo "📚 Useful commands:"
echo "  yarn dev:status    - Check service status"
echo "  yarn dev:logs      - View service logs"
echo "  yarn dev:stop      - Stop all services"
echo "  yarn dev:clean     - Clean up everything"
```

### Code Quality and Pre-commit Setup

#### Pre-commit Configuration (`.pre-commit-config.yaml`):
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: check-added-large-files
        args: ['--maxkb=500']

  - repo: local
    hooks:
      - id: eslint
        name: ESLint
        entry: npx eslint --fix
        language: node
        types: [javascript, typescript]
        require_serial: true

      - id: prettier
        name: Prettier
        entry: npx prettier --write
        language: node
        types_or: [javascript, typescript, json, yaml, markdown]
        require_serial: true

      - id: type-check
        name: TypeScript Type Check
        entry: npx nx run-many --target=type-check --all
        language: node
        pass_filenames: false
        require_serial: true

      - id: test-affected
        name: Run Affected Tests
        entry: npx nx affected --target=test --parallel=3
        language: node
        pass_filenames: false
        require_serial: true
```

## Implementation Tasks

The feature has been broken down into the following implementation tasks:

### 1. [Task 1021: Node.js and Yarn Environment Setup](1021.md)
**Estimated: 2 hours**
- Install Node.js 20 LTS and Yarn 4
- Configure package manager and workspaces
- Create installation scripts for Linux and Windows
- Set up monorepo structure

### 2. [Task 1022: VS Code IDE Configuration](1022.md)
**Estimated: 2 hours**
- Configure workspace settings for TypeScript/NestJS
- Set up recommended extensions
- Create debug configurations for all services
- Configure task automation

### 3. [Task 1023: Docker and Database Services Setup](1023.md)
**Estimated: 3 hours**
- Install Docker and Docker Compose
- Configure PostgreSQL, ClickHouse, MongoDB, Redis
- Set up Kafka messaging infrastructure
- Configure monitoring with Grafana (optional)

### 4. [Task 1024: Environment Configuration and Secrets Management](1024.md)
**Estimated: 2 hours**
- Implement two-file environment strategy (.env.example + .env.local)
- Set up secure Creon credential management
- Configure multi-account KIS settings
- Create validation and setup scripts

### 5. [Task 1025: Code Quality Tools and Git Hooks](1025.md)
**Estimated: 2 hours**
- Configure ESLint and Prettier for TypeScript
- Set up Husky pre-commit hooks
- Configure lint-staged and commitlint
- Implement automated code quality checks

### 6. [Task 1026: Development Scripts and Automation](1026.md)
**Estimated: 3 hours**
- Create master setup script for complete environment
- Implement service health monitoring
- Automate database migrations and seeding
- Write comprehensive developer documentation

**Total Estimated Time: 14 hours**

## Dependencies

This feature depends on having basic infrastructure components available for local development but doesn't require the full production infrastructure to be in place.

## Testing Plan

- Validate installation scripts on all supported platforms
- Test IDE configurations with sample projects
- Verify docker-compose services start correctly
- Test database connectivity and migrations
- Validate code quality tools and pre-commit hooks
- Test debugging configurations in IDEs

## Configuration Files Summary

The feature will create these key configuration files:
- `.vscode/settings.json` - VS Code workspace settings
- `.vscode/extensions.json` - Recommended extensions
- `.vscode/launch.json` - Debug configurations
- `.env.example` - Environment template with dummy values
- `.env.local` - Local credentials (gitignored)
- `docker-compose.dev.yml` - Local development services
- `.pre-commit-config.yaml` - Code quality hooks
- `scripts/setup-dev-env.sh` - Automated setup script

## Notes

- Prioritize developer experience and productivity
- Ensure consistency across different operating systems
- Focus on automation to reduce setup friction
- Include comprehensive documentation for troubleshooting
- Consider using development containers (devcontainers) for future enhancement

## Staging and Production Environment Planning

### Environment Separation Strategy

This spec focuses on the development environment. Staging and production environments will be addressed in separate specifications:

**Spec Organization**:
```yaml
Environment Specifications:
  1002: Development Environment Setup (this spec)
  1015: Staging Environment Setup (future)
  1020: Production Environment Deployment (future)
```

### Staging Environment (Spec 1015 - To Be Created)

**Purpose**: Pre-production testing with real broker APIs

**Key Differences from Development**:
- Use paper trading accounts for KIS and Creon
- Test with 2 KIS accounts initially
- Real-time market data but simulated trading
- Performance testing with actual data volumes
- Integration testing with all broker APIs

**Infrastructure**:
```yaml
Staging:
  Platform: Linux server (cloud or on-premise)
  Accounts: 2 KIS paper accounts
  Data: Real-time market data
  Trading: Paper trading only
  Monitoring: Basic metrics and logging
```

### Production Environment (Spec 1020 - To Be Created)

**Purpose**: Live trading with real money

**Key Differences from Staging**:
- 3 KIS accounts for full market coverage (1,800 symbols)
- Real money trading with strict risk limits
- High availability and disaster recovery
- Enhanced security and audit logging
- Professional monitoring and alerting

**Infrastructure**:
```yaml
Production:
  Platform: Dedicated Linux servers (redundant)
  Accounts: 3 KIS live accounts
  Windows VM: Creon API integration
  Data: Real-time with backup sources
  Trading: Live with risk management
  Monitoring: Full observability stack
  Security: Encrypted secrets, audit logs
  Backup: Automated backups, failover ready
```

### Migration Path

```mermaid
graph LR
    Dev[Development<br/>1-2 accounts<br/>Mock data] --> 
    Staging[Staging<br/>2 accounts<br/>Paper trading] --> 
    Prod[Production<br/>3 accounts<br/>Live trading]
```

### Account Scaling Strategy

1. **Development** (Current):
   - Start with 1 KIS account for basic testing
   - Add 2nd account when implementing multi-account features
   - Use mock data for surge detection testing

2. **Staging** (Phase 2):
   - 2 real KIS paper trading accounts
   - Test account failover and load balancing
   - Validate rate limiting across accounts

3. **Production** (Phase 3):
   - Scale to 3 KIS accounts
   - Full 1,800 symbol coverage
   - Implement account-level risk limits

## Status Updates

- **2025-08-24**: Feature specification created
- **2025-08-27**: Updated for multi-account architecture, removed macOS/WebStorm, added staging/production planning