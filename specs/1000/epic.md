---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '1000' # Numeric ID for stable reference
title: 'Foundation & Infrastructure Setup'
type: 'epic' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '' # Parent spec ID (leave empty for top-level)
children: ["1001", "1002", "1003", "1004", "1005", "1006", "1007", "1008", "1009", "1010"] # Child spec IDs (if any)
epic: '1000' # Root epic ID for this work
domain: 'infrastructure' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low

# === TRACKING ===
created: '2025-08-24' # YYYY-MM-DD
updated: '2025-08-24' # YYYY-MM-DD
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 80 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: [] # Must be done before this (spec IDs)
blocks: ['2000', '3000', '4000', '5000', '6000', '7000', '8000', '9000', '10000', '11000'] # This blocks these specs (1002, 1004, 1005 now blocked by specific storage tasks)
related: [] # Related but not blocking (spec IDs)

# === IMPLEMENTATION ===
pull_requests: ["#18", "#19"] # GitHub PR numbers for major milestones  
commits: ["08e4cc5", "e5381ea", "2da9f8d"] # Key milestone commits
context_file: "context.md" # Epic implementation journal
files: ['package.json', 'nx.json', 'docker-compose.yml', 'infrastructure/', 'libs/shared/'] # Key files to modify

# === METADATA ===
tags: ['infrastructure', 'architecture', 'setup', 'monorepo', 'docker', 'database'] # Searchable tags
effort: 'epic' # small | medium | large | epic
risk: 'medium' # low | medium | high

# ============================================================================
---

# Foundation & Infrastructure Setup

## Overview

Establish the core system infrastructure for the JTS automated trading platform, including system architecture design, monorepo setup, database infrastructure, messaging systems, and containerization. This epic provides the foundational layer upon which all other system components will be built.

## Acceptance Criteria

- [ ] **Frontend Infrastructure**: Next.js 14+ app with Tailwind CSS, PWA configuration, and WebSocket support
- [ ] **Backend Services**: 5 NestJS microservices deployed (api-gateway, strategy-engine, risk-management, order-execution, market-data-collector)
- [ ] **Storage Setup**: 4TB SSD partitioned with LVM (2TB ClickHouse, 800GB PostgreSQL, 600GB Kafka, 200GB MongoDB, 50GB Redis, 350GB system/backup)
- [ ] **Database Deployment**: All databases running with optimized configurations for SSD performance
- [ ] **Kafka Streaming**: Configured with 1GB segments, LZ4 compression, 7-day retention, 16 I/O threads
- [ ] **Redis Caching**: Configured with 8GB memory limit, AOF persistence, LRU eviction policy
- [ ] **API Gateway**: Express gateway with JWT auth, rate limiting (100 req/min), and gRPC support
- [ ] **Docker Infrastructure**: docker-compose.yml with all services, health checks, and volume mappings
- [ ] **Shared Libraries**: DTOs, interfaces, and utilities in libs/shared with TypeScript definitions
- [ ] **Development Environment**: Complete setup documentation with LVM commands and configuration files

## Technical Approach

### System Architecture Design
Design and document the complete microservices architecture following the layered approach outlined in the PRD. Create clear service boundaries, define communication protocols (HTTP/gRPC/Kafka), and establish data flow patterns.

#### JTS System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                            │
│                 (PWA with Service Workers + Mobile)              │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                      Gateway Layer                               │
│              (API Gateway with Auth & Rate Limiting)             │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                    Business Layer                                │
├────────────────┬────────────────┬────────────────┬───────────────┤
│    Strategy    │   Risk         │    Portfolio   │    Order      │
│    Engine      │   Management   │    Tracker     │    Execution  │
└────────────────┴────────────────┴────────────────┴───────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                   Integration Layer                              │
├───────────────────────────────┬──────────────────────────────────┤
│     Market Data Collector     │     Notification Service         │
└───────────────────────────────┴──────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                    Messaging Layer                               │
├───────────────────────────────┬──────────────────────────────────┤
│      Kafka (Event Stream)     │     Redis (Cache/Lock/Session)   │
└───────────────────────────────┴──────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                     Brokers Layer                                │
├─────────────┬─────────────┬─────────────┬───────────────────────┤
│Creon Service│ KIS Service │Binance Serv.│    Upbit Service      │
│ (Windows)   │  (Linux)    │  (Linux)    │     (Linux)           │
│Rate: 15s/60 │Rate: 1s/20  │Rate: 1m/1200│   Rate: 1s/10         │
└─────────────┴─────────────┴─────────────┴───────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                      Data Layer                                  │
├──────────────┬──────────────┬──────────────┬────────────────────┤
│ PostgreSQL   │ ClickHouse   │   MongoDB    │   File Storage     │
│(Transactions)│(Time Series) │(Configuration)│  (Logs/Backups)   │
└──────────────┴──────────────┴──────────────┴────────────────────┘
```

#### Architecture Principles
- **Microservices**: Each layer contains independent, scalable services
- **Clear Separation**: Well-defined boundaries between layers and services
- **Protocol Optimization**: HTTP/REST for external APIs, gRPC for internal services, Kafka for events
- **Fault Isolation**: Service failures don't cascade through the system
- **Independent Scaling**: Each service can be scaled based on demand
- **Platform Agnostic**: Services communicate through standardized interfaces

### Key Components

1. **Frontend Stack (Next.js + Tailwind CSS)**
   - Next.js 14+ with App Router for the presentation layer
   - Tailwind CSS for utility-first styling
   - Progressive Web App (PWA) configuration
   - WebSocket integration for real-time updates
   - Required packages:
     ```json
     {
       "@tanstack/react-query": "^5.0.0",     // Efficient data fetching
       "zustand": "^4.4.0",                    // State management
       "socket.io-client": "^4.5.0",          // WebSocket connections
       "lightweight-charts": "^4.0.0",         // TradingView charts
       "next-pwa": "^5.6.0"                   // PWA capabilities
     }
     ```

2. **Backend Architecture (NestJS Microservices)**
   - NestJS framework for all core services
   - TypeScript throughout the stack
   - Microservices communication via gRPC
   - Redis-backed Bull queues for job processing
   - Required modules:
     ```typescript
     BullModule,           // Job queues
     ThrottlerModule,      // Rate limiting
     WebSocketModule,      // Real-time data
     GrpcModule           // Inter-service communication
     ```

3. **Database Infrastructure with LVM**
   - **Storage Configuration (4TB SSD with LVM)**:
     ```bash
     lv_system: 200GB      # System & Docker
     lv_postgres: 800GB    # PostgreSQL (ext4, noatime)
     lv_clickhouse: 2000GB # ClickHouse (ext4, noatime)
     lv_kafka: 600GB       # Kafka (XFS, noatime)
     lv_mongodb: 200GB     # MongoDB (ext4)
     lv_redis: 50GB        # Redis (ext4)
     lv_backup: 150GB      # Local backups
     ```
   - PostgreSQL optimization for SSD (shared_buffers: 8GB, effective_cache_size: 24GB)
   - ClickHouse for time-series with 16GB memory allocation
   - MongoDB for configuration and strategy storage
   - Redis for caching with AOF persistence

4. **Messaging Infrastructure**
   - Kafka cluster with XFS filesystem for optimal performance
   - Configuration: 1GB segments, LZ4 compression, 7-day retention
   - Redis pub/sub for real-time price updates
   - Message schema definitions with Protocol Buffers
   - Performance tuning: 16 I/O threads, 8 network threads

5. **API Gateway & Containerization**
   - Express-based gateway with rate limiting
   - JWT authentication middleware
   - Docker Compose with service definitions
   - Health check endpoints for all services
   - Platform-specific containers (Windows for Creon COM objects)

### Nx Monorepo Workspace Structure

```
jts/
├── apps/                           # Applications
│   ├── presentation/              # UI Layer
│   │   └── web-app/              # Next.js PWA Frontend
│   ├── gateway/                  # API Gateway Layer
│   │   └── api-gateway/          # Express/Kong Gateway
│   ├── business/                 # Business Logic Layer
│   │   ├── strategy-engine/     # NestJS Strategy Service
│   │   ├── risk-management/     # NestJS Risk Service
│   │   ├── portfolio-tracker/   # NestJS Portfolio Service
│   │   └── order-execution/     # NestJS Order Service
│   ├── integration/              # Integration Services
│   │   ├── market-data-collector/  # NestJS Market Data Service
│   │   └── notification-service/   # NestJS Notification Service
│   ├── brokers/                 # Broker Integration Layer
│   │   ├── creon-service/       # Windows Python FastAPI
│   │   ├── kis-service/         # Linux NestJS
│   │   ├── binance-service/     # Linux NestJS
│   │   └── upbit-service/       # Linux NestJS
│   └── platform/                # Platform Services
│       ├── monitoring-service/  # Prometheus/Grafana integration
│       └── configuration-service/# Centralized config management
├── libs/                          # Shared Libraries
│   ├── shared/
│   │   ├── dto/                 # Data Transfer Objects
│   │   ├── interfaces/          # TypeScript Interfaces
│   │   ├── types/               # Type Definitions
│   │   ├── utils/               # Utility Functions
│   │   ├── constants/           # Application Constants
│   │   └── config/              # Configuration Utilities
│   ├── domain/
│   │   ├── trading/             # Trading Domain Logic
│   │   ├── market-data/         # Market Data Domain
│   │   ├── portfolio/           # Portfolio Domain
│   │   ├── risk/                # Risk Management Domain
│   │   └── strategy/            # Strategy Domain
│   ├── infrastructure/
│   │   ├── database/            # Database Utilities
│   │   ├── messaging/           # Kafka/Redis Utilities
│   │   ├── http/                # HTTP Client Utilities
│   │   ├── logging/             # Logging Infrastructure
│   │   └── monitoring/          # Monitoring Utilities
│   └── brokers/
│       ├── creon/               # Creon API Integration
│       ├── kis/                 # KIS API Integration
│       ├── binance/             # Binance API Integration
│       └── upbit/               # Upbit API Integration
├── infrastructure/                # Infrastructure Configuration
│   ├── docker/                  # Docker Configurations
│   ├── kubernetes/              # K8s Manifests (future)
│   ├── databases/               # Database Schemas
│   ├── kafka/                   # Kafka Configuration
│   └── monitoring/              # Monitoring Setup
├── tools/                        # Development Tools
│   ├── generators/              # Custom Nx Generators
│   ├── executors/               # Custom Nx Executors
│   ├── scripts/                 # Build and Deployment Scripts
│   └── workspace-plugin/        # Custom Workspace Plugin
├── docs/                         # Documentation
│   ├── architecture/            # Architecture Documentation
│   ├── development/             # Development Guides
│   └── deployment/              # Deployment Documentation
├── nx.json                       # Nx configuration
├── package.json                  # Root package.json
├── tsconfig.base.json            # TypeScript base config
├── .eslintrc.json                # ESLint configuration
├── jest.config.ts                # Jest testing configuration
└── docker-compose.yml            # Docker services
```

### Implementation Steps

1. **Storage Infrastructure Setup (Day 1-2)**
   ```bash
   # Create LVM structure on 4TB SSD
   pvcreate /dev/nvme0n1
   vgcreate vg_jts /dev/nvme0n1
   
   # Create logical volumes
   lvcreate -L 200G -n lv_system vg_jts
   lvcreate -L 800G -n lv_postgres vg_jts
   lvcreate -L 2000G -n lv_clickhouse vg_jts
   lvcreate -L 600G -n lv_kafka vg_jts
   lvcreate -L 200G -n lv_mongodb vg_jts
   lvcreate -L 50G -n lv_redis vg_jts
   lvcreate -L 150G -n lv_backup vg_jts
   
   # Format with optimized filesystems
   mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/vg_jts/lv_postgres
   mkfs.xfs -f /dev/vg_jts/lv_kafka  # XFS for Kafka
   ```

2. **Monorepo & Frontend Setup (Day 3-4)**
   ```bash
   # Initialize Nx workspace with NestJS preset
   npx create-nx-workspace@latest jts --preset=nest
   
   # Add Next.js application
   nx g @nrwl/next:app web-app
   
   # Install frontend dependencies
   npm install @tanstack/react-query zustand socket.io-client
   npm install -D tailwindcss @tailwindcss/typography
   
   # Configure PWA
   npm install next-pwa workbox-webpack-plugin
   ```

3. **Backend Services Creation (Day 5-6)**
   ```bash
   # Generate NestJS microservices
   nx g @nestjs/schematics:app api-gateway
   nx g @nestjs/schematics:app strategy-engine
   nx g @nestjs/schematics:app risk-management
   nx g @nestjs/schematics:app order-execution
   nx g @nestjs/schematics:app market-data-collector
   
   # Add shared libraries
   nx g @nrwl/workspace:lib shared/dto
   nx g @nrwl/workspace:lib shared/interfaces
   nx g @nrwl/workspace:lib shared/utils
   ```

4. **Database Configuration (Day 7-8)**
   ```yaml
   # docker-compose.yml database services
   services:
     postgres:
       image: postgres:15-alpine
       volumes:
         - /var/lib/postgresql:/var/lib/postgresql/data
       environment:
         POSTGRES_DB: jts_trading
         POSTGRES_USER: jts_admin
         POSTGRES_PASSWORD: ${DB_PASSWORD}
       command: >
         -c shared_buffers=8GB
         -c effective_cache_size=24GB
         -c maintenance_work_mem=2GB
         -c random_page_cost=1.1
     
     clickhouse:
       image: clickhouse/clickhouse-server:23.8
       volumes:
         - /var/lib/clickhouse:/var/lib/clickhouse
       environment:
         CLICKHOUSE_DB: jts_market_data
         CLICKHOUSE_USER: jts_ch
         CLICKHOUSE_PASSWORD: ${CH_PASSWORD}
   ```

5. **Messaging Infrastructure (Day 9-10)**
   ```yaml
   # Kafka configuration
   kafka:
     image: confluentinc/cp-kafka:7.5.0
     volumes:
       - /var/lib/kafka:/var/kafka-logs
     environment:
       KAFKA_LOG_SEGMENT_BYTES: 1073741824  # 1GB
       KAFKA_LOG_RETENTION_HOURS: 168       # 7 days
       KAFKA_COMPRESSION_TYPE: lz4
       KAFKA_NUM_IO_THREADS: 16
       KAFKA_NUM_NETWORK_THREADS: 8
   
   redis:
     image: redis:7-alpine
     volumes:
       - /var/lib/redis:/data
     command: >
       --appendonly yes
       --appendfsync everysec
       --maxmemory 8gb
       --maxmemory-policy allkeys-lru
   ```

6. **API Gateway & Authentication (Day 11-12)**
   ```typescript
   // apps/api-gateway/src/main.ts
   import { NestFactory } from '@nestjs/core';
   import { Transport } from '@nestjs/microservices';
   
   async function bootstrap() {
     const app = await NestFactory.create(AppModule);
     
     // Configure gRPC microservice
     app.connectMicroservice({
       transport: Transport.GRPC,
       options: {
         package: 'jts',
         protoPath: join(__dirname, 'protos/jts.proto'),
       }
     });
     
     // Rate limiting
     app.use(rateLimit({
       windowMs: 60 * 1000, // 1 minute
       max: 100 // limit each IP to 100 requests per minute
     }));
     
     await app.startAllMicroservices();
     await app.listen(3000);
   }
   ```

## Dependencies

This epic has no dependencies as it forms the foundation layer. All other epics depend on this being completed first.

## Testing Plan

- Infrastructure deployment validation
- Database connectivity tests
- Message broker functionality tests
- API Gateway routing tests
- Docker container orchestration tests
- Development environment setup validation

## Configuration Files

### /etc/fstab (Mount Configuration)
```bash
# JTS Trading System - Optimized Mount Points
/dev/vg_jts/lv_system     /                    ext4  defaults                    0 1
/dev/vg_jts/lv_postgres   /var/lib/postgresql  ext4  noatime,data=writeback     0 2
/dev/vg_jts/lv_clickhouse /var/lib/clickhouse  ext4  noatime,data=ordered       0 2
/dev/vg_jts/lv_kafka      /var/lib/kafka       xfs   noatime,nobarrier,logbufs=8 0 2
/dev/vg_jts/lv_mongodb    /var/lib/mongodb     ext4  noatime                    0 2
/dev/vg_jts/lv_redis      /var/lib/redis       ext4  noatime,data=writeback     0 2
/dev/vg_jts/lv_backup     /backup              ext4  defaults                    0 2
```

### .env.production (Environment Variables)
```env
# Database Credentials
DB_PASSWORD=secure_postgres_password
CH_PASSWORD=secure_clickhouse_password
MONGO_PASSWORD=secure_mongo_password

# Kafka Configuration
KAFKA_BROKERS=localhost:9092
KAFKA_CLIENT_ID=jts-trading-system

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=secure_redis_password

# API Configuration
JWT_SECRET=your-256-bit-secret
API_RATE_LIMIT=100
API_RATE_WINDOW=60000

# Service Ports
GATEWAY_PORT=3000
STRATEGY_PORT=3001
RISK_PORT=3002
ORDER_PORT=3003
MARKET_DATA_PORT=3004
```

## Claude Code Instructions

```
When implementing this epic:
1. Start with LVM setup on the 4TB SSD using the provided commands
2. Initialize Nx workspace: npx create-nx-workspace@latest jts --preset=nest
3. Add Next.js app: nx g @nrwl/next:app web-app
4. Generate all NestJS microservices using nx commands
5. Create docker-compose.yml with all infrastructure services
6. Configure databases with the specific performance tuning parameters
7. Set up /etc/fstab with the optimized mount options
8. Implement health check endpoints for all services
9. Use the provided environment variables in .env.production
10. Document the complete setup process in README.md
```

## Notes

- This epic is critical path and blocks all other development
- Consider using Kubernetes for production deployment (future enhancement)
- Ensure cross-platform compatibility (Linux primary, Windows for Creon)
- Set up proper logging and monitoring from the start

### Storage Infrastructure Decomposition

Feature 1001 (Storage Infrastructure) has been decomposed into specialized tasks for better implementation management:

- **Task 1011**: Hot Storage (NVMe) Foundation - Core LVM infrastructure setup
- **Task 1012**: Database Mount Integration - Service-specific mount points and permissions
- **Task 1013**: Warm Storage (SATA) Setup - Independent SATA/btrfs implementation  
- **Task 1014**: Cold Storage (NAS) Integration - NFS optimization and directory structure
- **Task 1015**: Storage Performance Optimization - I/O schedulers and TRIM configuration
- **Task 1016**: Tiered Storage Management - Automation and lifecycle management

**Dependency Impact**: Feature 1005 (Database Infrastructure) now depends on Task 1012 (Database Mount Integration) rather than the entire storage coordination feature, enabling more precise dependency management and parallel execution.

## Status Updates

- **2025-08-24**: Epic created and documented