---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: T05 # Hierarchical position ID
title: Create Development Tooling and Generators
type: task
category: infrastructure

# === HIERARCHY ===
parent: F03
children: []
epic: E01
domain: infrastructure

# === WORKFLOW ===
status: draft
priority: medium
assignee: ''
reviewer: ''

# === TRACKING ===
created: '2025-08-28'
updated: '2025-08-28'
due_date: ''
estimated_hours: 2.5
actual_hours: 0

# === DEPENDENCIES ===
dependencies:
- T03
- T04
blocks:
- T06
related: []

# === IMPLEMENTATION ===
pull_requests: []
commits: []
context_file: 1003.context.md
worktree: ''
files:
- tools/generators/*
- tools/scripts/*
- package.json
- docker-compose.yml

# === METADATA ===
tags:
- generators
- tooling
- automation
- dx
- docker
effort: medium
risk: low
unique_id: a34bacf8 # Unique identifier (never changes)

---

# Task T05: Create Development Tooling and Generators

## Overview

Implement custom Nx generators for consistent service and library creation, create comprehensive development scripts for common tasks, set up Docker Compose for local development dependencies, and build utilities for service health monitoring.

## Acceptance Criteria

- [ ] Custom generator for NestJS services
- [ ] Custom generator for shared libraries
- [ ] Development scripts for common workflows
- [ ] Docker Compose configuration for databases
- [ ] Service health check utilities
- [ ] Automated setup script for new developers

## Technical Details

### 1. NestJS Service Generator

```typescript
// tools/generators/nestjs-service/index.ts
import {
  Tree,
  formatFiles,
  installPackagesTask,
  names,
  offsetFromRoot,
  generateFiles,
  joinPathFragments,
} from '@nx/devkit';
import { applicationGenerator } from '@nx/nest';

interface ServiceGeneratorSchema {
  name: string;
  directory?: string;
  tags?: string;
  port?: number;
}

export default async function (tree: Tree, options: ServiceGeneratorSchema) {
  const normalizedOptions = normalizeOptions(tree, options);
  
  // Generate NestJS application
  await applicationGenerator(tree, {
    name: normalizedOptions.projectName,
    directory: normalizedOptions.projectDirectory,
    tags: normalizedOptions.parsedTags.join(','),
    unitTestRunner: 'jest',
    linter: 'eslint',
  });

  // Add custom templates
  generateFiles(
    tree,
    joinPathFragments(__dirname, 'files'),
    normalizedOptions.projectRoot,
    {
      ...normalizedOptions,
      ...names(options.name),
      offsetFromRoot: offsetFromRoot(normalizedOptions.projectRoot),
      template: '',
    }
  );

  // Update configuration
  updateProjectConfiguration(tree, normalizedOptions);

  await formatFiles(tree);
  return () => {
    installPackagesTask(tree);
  };
}

function normalizeOptions(tree: Tree, options: ServiceGeneratorSchema) {
  const name = names(options.name).fileName;
  const projectDirectory = options.directory 
    ? `${names(options.directory).fileName}/${name}` 
    : name;
  const projectName = projectDirectory.replace(new RegExp('/', 'g'), '-');
  const projectRoot = `apps/${projectDirectory}`;
  const parsedTags = options.tags ? options.tags.split(',').map((s) => s.trim()) : ['scope:apps'];
  const port = options.port || E03 + Math.floor(Math.random() * E01);

  return {
    ...options,
    projectName,
    projectRoot,
    projectDirectory,
    parsedTags,
    port,
  };
}
```

### 2. Library Generator

```typescript
// tools/generators/jts-library/index.ts
import {
  Tree,
  formatFiles,
  installPackagesTask,
  libraryGenerator,
} from '@nx/devkit';

interface LibraryGeneratorSchema {
  name: string;
  directory: string;
  scope: 'shared' | 'domain' | 'infrastructure' | 'brokers';
  buildable?: boolean;
}

export default async function (tree: Tree, options: LibraryGeneratorSchema) {
  await libraryGenerator(tree, {
    name: options.name,
    directory: `${options.scope}/${options.directory}`,
    tags: `scope:${options.scope}`,
    buildable: options.buildable ?? true,
    importPath: `@jts/${options.scope}/${options.name}`,
    unitTestRunner: 'jest',
    linter: 'eslint',
  });

  // Add standard exports
  generateStandardExports(tree, options);

  await formatFiles(tree);
  return () => {
    installPackagesTask(tree);
  };
}
```

### 3. Development Scripts

```bash
#!/bin/bash
# tools/scripts/setup-dev.sh

echo "🚀 Setting up JTS development environment..."

# Check prerequisites
check_prerequisites() {
  echo "Checking prerequisites..."
  
  if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    exit 1
  fi
  
  if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
  fi
  
  echo "✅ Prerequisites satisfied"
}

# Install dependencies
install_dependencies() {
  echo "Installing dependencies..."
  npm install
  echo "✅ Dependencies installed"
}

# Setup databases
setup_databases() {
  echo "Starting database services..."
  docker-compose up -d postgres clickhouse mongodb redis
  
  # Wait for services
  echo "Waiting for databases to be ready..."
  sleep 10
  
  # Run migrations
  npm run db:migrate
  echo "✅ Databases ready"
}

# Setup environment
setup_environment() {
  echo "Setting up environment..."
  if [ ! -f .env.local ]; then
    cp .env.example .env.local
    echo "⚠️  Please update .env.local with your credentials"
  fi
  echo "✅ Environment configured"
}

# Main execution
check_prerequisites
install_dependencies
setup_databases
setup_environment

echo "✨ Development environment ready!"
echo "Run 'npm run dev' to start developing"
```

### 4. Docker Compose Configuration

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: jts_user
      POSTGRES_PASSWORD: jts_pass
      POSTGRES_DB: jts_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U jts_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  clickhouse:
    image: clickhouse/clickhouse-server:23-alpine
    ports:
      - "8123:8123"
      - "E09:E09"
    volumes:
      - clickhouse_data:/var/lib/clickhouse
    environment:
      CLICKHOUSE_DB: jts_timeseries
      CLICKHOUSE_USER: jts_user
      CLICKHOUSE_PASSWORD: jts_pass
    healthcheck:
      test: ["CMD", "clickhouse-client", "--query", "SELECT 1"]
      interval: 10s
      timeout: 5s
      retries: 5

  mongodb:
    image: mongo:7-jammy
    environment:
      MONGO_INITDB_ROOT_USERNAME: jts_user
      MONGO_INITDB_ROOT_PASSWORD: jts_pass
      MONGO_INITDB_DATABASE: jts_config
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    ports:
      - "9092:9092"
    volumes:
      - kafka_data:/var/lib/kafka/data

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: E02
    ports:
      - "2181:2181"
    volumes:
      - zookeeper_data:/var/lib/zookeeper/data

volumes:
  postgres_data:
  clickhouse_data:
  mongodb_data:
  redis_data:
  kafka_data:
  zookeeper_data:
```

### 5. Health Check Utilities

```typescript
// tools/scripts/check-services-health.js
const axios = require('axios');

const services = [
  { name: 'PostgreSQL', url: 'http://localhost:5432', type: 'tcp' },
  { name: 'ClickHouse', url: 'http://localhost:8123/ping' },
  { name: 'MongoDB', url: 'http://localhost:27017', type: 'tcp' },
  { name: 'Redis', url: 'http://localhost:6379', type: 'tcp' },
  { name: 'Kafka', url: 'http://localhost:9092', type: 'tcp' },
];

async function checkHealth() {
  console.log('🔍 Checking service health...\n');
  
  for (const service of services) {
    try {
      if (service.type === 'tcp') {
        // TCP check implementation
        console.log(`✅ ${service.name}: Healthy`);
      } else {
        await axios.get(service.url, { timeout: E05 });
        console.log(`✅ ${service.name}: Healthy`);
      }
    } catch (error) {
      console.log(`❌ ${service.name}: Unhealthy`);
    }
  }
}

checkHealth();
```

### 6. NPM Scripts

```json
// package.json additions
{
  "scripts": {
    // Development
    "dev:setup": "./tools/scripts/setup-dev.sh",
    "dev:services": "docker-compose up -d",
    "dev:services:down": "docker-compose down",
    "dev:services:logs": "docker-compose logs -f",
    "dev:health": "node tools/scripts/check-services-health.js",
    
    // Generators
    "g:service": "nx g ./tools/generators/nestjs-service",
    "g:lib": "nx g ./tools/generators/jts-library",
    
    // Workspace
    "workspace:clean": "nx reset && rm -rf dist tmp coverage .nx",
    "workspace:setup": "npm install && npm run build:all",
    "workspace:reset": "npm run workspace:clean && npm install",
    
    // Analysis
    "analyze:deps": "nx graph",
    "analyze:affected": "nx affected:graph",
    "analyze:circular": "nx lint --check-circular-deps"
  }
}
```

## Implementation Steps

1. **Create service generator** (45 min)
   - Implement NestJS service generator
   - Add custom templates
   - Test generation process

2. **Create library generator** (30 min)
   - Implement library generator
   - Configure scope-based generation
   - Add standard exports

3. **Set up Docker Compose** (30 min)
   - Create docker-compose.yml
   - Configure all database services
   - Add health checks

4. **Create development scripts** (30 min)
   - Write setup script
   - Create health check utility
   - Add helper scripts

5. **Update npm scripts** (15 min)
   - Add generator shortcuts
   - Add development workflows
   - Add analysis commands

## Testing

```bash
# Test generators
npm run g:service -- --name=test-service --port=3100
npm run g:lib -- --name=test-lib --scope=shared

# Test Docker services
npm run dev:services
npm run dev:health

# Test setup script
npm run dev:setup

# Test workspace commands
npm run analyze:deps
npm run workspace:clean
```

## Success Metrics

- Generators create consistent project structures
- All Docker services start successfully
- Health checks report all services healthy
- Setup script completes in <5 minutes
- Development workflow is streamlined

## Notes

- Generators ensure consistency across services
- Docker Compose simplifies local development
- Health checks prevent debugging service issues
- Automation reduces onboarding time
- Consider adding generator for specific service types (API, worker, etc.)