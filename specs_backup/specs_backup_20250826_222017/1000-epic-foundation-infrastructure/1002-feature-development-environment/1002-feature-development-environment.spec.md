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
children: [] # Child spec IDs (if any)
epic: '1000' # Root epic ID for this work
domain: 'infrastructure' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low
assignee: '' # Who's working on this
reviewer: '' # Who should review (optional)

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
branch: '' # Git branch name
worktree: '' # Worktree path (optional)
files: [
    '.vscode/settings.json',
    '.vscode/extensions.json',
    'package.json',
    '.env.example',
    'docker-compose.dev.yml',
    'docs/DEVELOPMENT.md',
  ] # Key files to modify

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

- [ ] **Node.js Environment**: Node.js 20+ with npm/yarn package manager
- [ ] **IDE Configuration**: VS Code and WebStorm configured with project-specific settings
- [ ] **Development Tools**: Docker Desktop, Git, and CLI tools installed
- [ ] **Environment Variables**: Secure secrets management with `.env` templates
- [ ] **Local Development**: Working docker-compose setup for all services
- [ ] **Code Quality Tools**: Pre-commit hooks, linting, and formatting configured
- [ ] **Database Tools**: Database clients and management tools installed
- [ ] **Documentation**: Complete developer onboarding guide
- [ ] **Platform Support**: Setup instructions for Linux, macOS, and Windows
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

- **Linux (Primary)**: Ubuntu 22.04+ or equivalent
- **macOS**: macOS 12+ with Apple Silicon or Intel
- **Windows**: Windows 11 with WSL2 for Linux compatibility

### Required Tools and SDKs

#### Core Development Tools

```bash
# Node.js and Package Managers
Node.js: 20.x LTS
npm: 10.x
yarn: 4.x (optional alternative)

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

**macOS Setup**:

```bash
#!/bin/bash
# install-dev-tools-macos.sh

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install development tools
brew install node@20 git docker docker-compose
brew install postgresql@15 mongodb/brew/mongodb-community redis
brew install gh jq httpie

# Install GUI applications
brew install --cask docker visual-studio-code webstorm
brew install --cask pgadmin4 mongodb-compass redis-stack-redisinsight

# Link Node.js 20
brew unlink node || true
brew link --force --overwrite node@20
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
choco install postgresql pgadmin4 mongodb mongodb-compass redis-desktop-manager -y
choco install gh jq httpie postman -y

# Install IDEs
choco install vscode webstorm -y

# Enable WSL2 for Linux compatibility
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

### IDE Configuration

#### VS Code Setup

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
  "unwantedRecommendations": ["ms-vscode.vscode-typescript"]
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

#### WebStorm Configuration

**Project Settings** (`.idea/workspace.xml`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="PropertiesComponent">
    <property name="nodejs_interpreter_path.value" value="node" />
    <property name="nodejs_package_manager_path.value" value="npm" />
    <property name="ts.external.directory.path" value="$PROJECT_DIR$/node_modules/typescript/lib" />
    <property name="javascript.nodejs.core.library.configured.version" value="20.5.0" />
    <property name="javascript.nodejs.core.library.typings.version" value="20.5.0" />
  </component>
  <component name="TypeScriptGeneratedFilesManager">
    <option name="version" value="3" />
  </component>
</project>
```

### Environment Variables and Secrets Management

#### Environment File Templates

**Development Environment** (`.env.development`):

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

# Logging
LOG_LEVEL=debug
LOG_FORMAT=combined

# External API Keys (Development/Sandbox)
CREON_API_KEY=dev_creon_key
KIS_API_KEY=dev_kis_key
KIS_SECRET_KEY=dev_kis_secret
BINANCE_API_KEY=dev_binance_key
BINANCE_SECRET_KEY=dev_binance_secret
UPBIT_ACCESS_KEY=dev_upbit_access
UPBIT_SECRET_KEY=dev_upbit_secret

# Development Features
ENABLE_SWAGGER=true
ENABLE_DEBUG_ROUTES=true
ENABLE_MOCK_DATA=true
```

**Production Template** (`.env.production.template`):

```env
# Application Configuration
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Database URLs (CHANGE THESE)
DATABASE_URL=postgresql://username:password@host:5432/database
CLICKHOUSE_URL=http://username:password@host:8123/database
MONGODB_URL=mongodb://username:password@host:27017/database
REDIS_URL=redis://host:6379

# Kafka Configuration
KAFKA_BROKERS=broker1:9092,broker2:9092,broker3:9092
KAFKA_CLIENT_ID=jts-production
KAFKA_GROUP_ID=jts-trading-prod

# JWT Configuration (CHANGE THESE)
JWT_SECRET=your-256-bit-secret-change-this
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=24h

# Rate Limiting
RATE_LIMIT_WINDOW=60000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# External API Keys (CHANGE THESE)
CREON_API_KEY=your_production_creon_key
KIS_API_KEY=your_production_kis_key
KIS_SECRET_KEY=your_production_kis_secret
BINANCE_API_KEY=your_production_binance_key
BINANCE_SECRET_KEY=your_production_binance_secret
UPBIT_ACCESS_KEY=your_production_upbit_access
UPBIT_SECRET_KEY=your_production_upbit_secret

# Production Features
ENABLE_SWAGGER=false
ENABLE_DEBUG_ROUTES=false
ENABLE_MOCK_DATA=false
```

#### Secrets Management Strategy

```bash
# Local Development Secrets (.env.local - gitignored)
# Copy from .env.development and customize for your setup
cp .env.development .env.local

# Production Secrets Management
# Use environment-specific secret managers:
# - AWS Secrets Manager
# - Azure Key Vault
# - HashiCorp Vault
# - Kubernetes Secrets
```

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
      - '5432:5432'
    environment:
      POSTGRES_DB: jts_trading_dev
      POSTGRES_USER: jts_admin
      POSTGRES_PASSWORD: dev_password
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U jts_admin -d jts_trading_dev']
      interval: 10s
      timeout: 5s
      retries: 5

  clickhouse:
    image: clickhouse/clickhouse-server:23.8
    container_name: jts-clickhouse-dev
    restart: unless-stopped
    ports:
      - '8123:8123'
      - '9000:9000'
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
      - '27017:27017'
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
      - '6379:6379'
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
      - '9092:9092'
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
      - '8080:8080'
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
      - '5050:80'
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
  pgladmin_dev_data:

networks:
  default:
    name: jts-dev-network
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

    "db:migrate": "npm run db:migrate:postgres && npm run db:migrate:clickhouse",
    "db:migrate:postgres": "npx prisma migrate deploy",
    "db:migrate:clickhouse": "node scripts/migrate-clickhouse.js",
    "db:seed": "npm run db:seed:postgres && npm run db:seed:clickhouse",
    "db:seed:postgres": "npx prisma db seed",
    "db:seed:clickhouse": "node scripts/seed-clickhouse.js",
    "db:reset": "npm run db:reset:postgres && npm run db:reset:clickhouse",

    "services:health": "node scripts/check-services-health.js",
    "services:start": "concurrently \"npm run start:gateway\" \"npm run start:strategy\" \"npm run start:risk\" \"npm run start:order\" \"npm run start:market-data\"",
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
npm install

# Copy environment file
if [ ! -f .env.local ]; then
    echo "🔧 Creating .env.local from template..."
    cp .env.development .env.local
    echo "⚠️  Please review and update .env.local with your local settings"
fi

# Start infrastructure services
echo "🐳 Starting infrastructure services..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
npm run services:health

# Run database migrations
echo "🗄️  Running database migrations..."
sleep 10  # Give databases time to fully start
npm run db:migrate

# Seed development data
echo "🌱 Seeding development data..."
npm run db:seed

echo "✅ Development environment setup complete!"
echo ""
echo "🎯 Next steps:"
echo "  1. Review .env.local settings"
echo "  2. Start development servers: npm run services:start"
echo "  3. Open http://localhost:3000 for API Gateway"
echo "  4. Access Kafka UI at http://localhost:8080"
echo "  5. Access pgAdmin at http://localhost:5050"
echo ""
echo "📚 Useful commands:"
echo "  npm run dev:status    - Check service status"
echo "  npm run dev:logs      - View service logs"
echo "  npm run dev:stop      - Stop all services"
echo "  npm run dev:clean     - Clean up everything"
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

## Implementation Steps

1. **Prerequisites Installation (1 hour)**
   - Install Node.js 20 LTS
   - Install Docker Desktop
   - Install Git and GitHub CLI
   - Install database client tools

2. **IDE Configuration (1 hour)**
   - Configure VS Code with extensions and settings
   - Set up WebStorm project configuration
   - Configure debugging environments

3. **Environment Setup (2 hours)**
   - Create environment file templates
   - Set up docker-compose.dev.yml
   - Configure local service discovery
   - Create development scripts

4. **Database Tools Setup (1 hour)**
   - Install and configure pgAdmin
   - Install MongoDB Compass
   - Install Redis Insight
   - Set up ClickHouse client

5. **Code Quality Setup (1 hour)**
   - Configure ESLint and Prettier
   - Set up pre-commit hooks
   - Configure Jest testing environment
   - Set up TypeScript type checking

6. **Documentation Creation (2 hours)**
   - Write developer onboarding guide
   - Create troubleshooting documentation
   - Document local workflow processes
   - Create platform-specific setup guides

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
- `.env.development` - Development environment template
- `.env.local.example` - Local customization template
- `docker-compose.dev.yml` - Local development services
- `.pre-commit-config.yaml` - Code quality hooks
- `scripts/setup-dev-env.sh` - Automated setup script

## Notes

- Prioritize developer experience and productivity
- Ensure consistency across different operating systems
- Focus on automation to reduce setup friction
- Include comprehensive documentation for troubleshooting
- Consider using development containers (devcontainers) for future enhancement

## Status Updates

- **2025-08-24**: Feature specification created
