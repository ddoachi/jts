---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '1005' # Numeric ID for stable reference
title: 'Database Infrastructure'
type: 'feature' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '1000' # Parent spec ID
children: [] # Child spec IDs (if any)
epic: '1000' # Root epic ID for this work
domain: 'infrastructure' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low

# === TRACKING ===
created: '2025-08-24' # YYYY-MM-DD
updated: '2025-08-24' # YYYY-MM-DD
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 20 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: ['1012'] # Must be done before this (spec IDs) - Database mount integration must be ready
blocks: ['1007', '2000', '3000'] # This blocks these specs (spec IDs)
related: ['1003', '1006'] # Related but not blocking (spec IDs)

# === IMPLEMENTATION ===
pull_requests: [] # GitHub PR numbers
commits: [] # Key implementation commits
context_file: "context.md" # Implementation journal
files: ['infrastructure/databases/', 'docker-compose.databases.yml', 'migrations/', 'scripts/db-setup/', 'libs/shared/database/'] # Key files to modify

# === METADATA ===
tags: ['database', 'postgresql', 'clickhouse', 'mongodb', 'redis', 'migrations', 'schemas', 'optimization'] # Searchable tags
effort: 'large' # small | medium | large | epic
risk: 'medium' # low | medium | high

# ============================================================================
---

# Database Infrastructure

## Overview

Establish a comprehensive, multi-database infrastructure architecture for the JTS automated trading system. This feature implements PostgreSQL for transactional data, ClickHouse for time-series market data analytics, MongoDB for flexible configuration storage, and Redis for high-performance caching and session management. Each database is optimized for its specific role in high-frequency trading operations with proper security, backup strategies, and performance tuning.

## Acceptance Criteria

- [ ] **PostgreSQL Setup**: Production-ready PostgreSQL 15+ with optimized configuration for SSD storage, connection pooling, and ACID compliance for trading transactions
- [ ] **ClickHouse Deployment**: ClickHouse cluster optimized for time-series data ingestion, compression, and high-performance analytics queries
- [ ] **MongoDB Configuration**: MongoDB replica set with proper sharding for configuration data, strategy parameters, and flexible document storage
- [ ] **Redis Optimization**: Redis cluster with persistence, memory optimization, pub/sub capabilities, and distributed caching
- [ ] **Database Schemas**: Complete initial schema definitions with proper indexing strategies optimized for trading workloads
- [ ] **Migration System**: Robust database migration framework with rollback capabilities and version control
- [ ] **Security Implementation**: Database users, roles, SSL/TLS encryption, and access controls following principle of least privilege
- [ ] **Backup & Recovery**: Automated backup solutions with point-in-time recovery, retention policies, and disaster recovery procedures
- [ ] **Performance Monitoring**: Comprehensive monitoring setup with metrics, alerting, and performance optimization recommendations
- [ ] **Connection Management**: Optimized connection pooling, load balancing, and failover configurations for all database connections

## Technical Approach

### Multi-Database Architecture Strategy

Implement a specialized database architecture where each system is purpose-built for specific data patterns and access requirements in algorithmic trading:

**Database Allocation by Function:**
- **PostgreSQL**: ACID-compliant transactions, user management, order lifecycle, portfolio positions
- **ClickHouse**: High-frequency market data, analytics aggregations, backtesting datasets  
- **MongoDB**: Dynamic strategy configurations, API credentials, system preferences
- **Redis**: Real-time caching, session state, distributed locks, pub/sub messaging

### Key Components

#### 1. PostgreSQL - Transactional Core
**Purpose**: ACID-compliant transactional data requiring strong consistency
**Storage Allocation**: 800GB dedicated LVM volume with ext4 filesystem
**Key Features**:
- User authentication and authorization
- Trading strategy definitions and configurations
- Order execution history with full audit trail
- Portfolio positions and P&L calculations
- Risk management rules and compliance data
- System audit logs and regulatory reporting

**Optimization Strategy**:
```sql
-- Performance tuning for SSD storage
shared_buffers = 8GB                    -- 25% of available RAM
effective_cache_size = 24GB             -- 75% of available RAM  
maintenance_work_mem = 2GB              -- For large operations
work_mem = 256MB                        -- Per-query memory
wal_buffers = 16MB                      -- WAL buffer size
checkpoint_completion_target = 0.9      -- Spread checkpoints
random_page_cost = 1.1                  -- SSD optimization
effective_io_concurrency = 200          -- Concurrent I/O operations
```

#### 2. ClickHouse - Time-Series Analytics Engine
**Purpose**: High-performance analytics for time-series market data
**Storage Allocation**: 2TB dedicated LVM volume with ext4 filesystem
**Key Features**:
- Real-time market data ingestion (prices, volume, order book)
- Historical market data for backtesting and analysis
- Trading performance metrics and analytics
- System monitoring and observability data
- High-frequency event logging and audit trails

**Optimization Strategy**:
```xml
<!-- ClickHouse configuration optimizations -->
<max_memory_usage>16000000000</max_memory_usage>  <!-- 16GB -->
<max_server_memory_usage_to_ram_ratio>0.5</max_server_memory_usage_to_ram_ratio>
<mark_cache_size>5368709120</mark_cache_size>  <!-- 5GB -->
<uncompressed_cache_size>8589934592</uncompressed_cache_size>  <!-- 8GB -->
<max_concurrent_queries>100</max_concurrent_queries>
<background_pool_size>32</background_pool_size>
```

#### 3. MongoDB - Configuration Management
**Purpose**: Flexible schema for configurations and evolving data structures
**Storage Allocation**: 200GB dedicated LVM volume with ext4 filesystem
**Key Features**:
- Dynamic trading strategy parameters
- API keys and broker-specific configurations
- User preferences and dashboard customizations
- System-wide configuration settings
- Temporary calculation states and intermediate results

**Optimization Strategy**:
```javascript
// MongoDB optimization settings
{
  "storage": {
    "wiredTiger": {
      "engineConfig": {
        "cacheSizeGB": 4,
        "directoryForIndexes": true
      },
      "collectionConfig": {
        "blockCompressor": "zstd"
      }
    }
  }
}
```

#### 4. Redis - High-Performance Caching
**Purpose**: Ultra-low latency caching and real-time data distribution
**Storage Allocation**: 50GB dedicated LVM volume with ext4 filesystem
**Key Features**:
- Session management and JWT token storage
- Real-time price caching and distribution
- Rate limiting counters for API throttling
- Distributed locks for order execution synchronization
- Pub/sub messaging for real-time updates

**Optimization Strategy**:
```conf
# Redis performance configuration
maxmemory 8gb
maxmemory-policy allkeys-lru
save 900 1              # Background saves
save 300 10
save 60 10000
appendonly yes          # AOF persistence
appendfsync everysec    # Balance performance/durability
tcp-keepalive 300       # Connection management
```

### Implementation Steps

#### Phase 1: Storage and Base Configuration (Days 1-3)

1. **LVM Volume Setup**
```bash
# Create dedicated logical volumes for each database
lvcreate -L 800G -n lv_postgres vg_jts
lvcreate -L 2000G -n lv_clickhouse vg_jts  
lvcreate -L 200G -n lv_mongodb vg_jts
lvcreate -L 50G -n lv_redis vg_jts

# Format with optimized filesystems
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/vg_jts/lv_postgres
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/vg_jts/lv_clickhouse
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/vg_jts/lv_mongodb
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/vg_jts/lv_redis

# Create mount points with optimized options
mkdir -p /var/lib/{postgresql,clickhouse,mongodb,redis}
```

2. **Docker Compose Database Services**
```yaml
# docker-compose.databases.yml
version: '3.8'

services:
  postgresql:
    image: postgres:15-alpine
    container_name: jts-postgresql
    restart: unless-stopped
    ports:
      - "5432:5432"
    volumes:
      - /var/lib/postgresql:/var/lib/postgresql/data
      - ./infrastructure/databases/postgresql/init:/docker-entrypoint-initdb.d
      - ./infrastructure/databases/postgresql/config/postgresql.conf:/etc/postgresql/postgresql.conf
    environment:
      POSTGRES_DB: jts_trading
      POSTGRES_USER: jts_admin
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_INITDB_ARGS: "--data-checksums --encoding=UTF8"
    command: >
      postgres
      -c config_file=/etc/postgresql/postgresql.conf
      -c shared_buffers=8GB
      -c effective_cache_size=24GB
      -c maintenance_work_mem=2GB
      -c work_mem=256MB
      -c checkpoint_completion_target=0.9
      -c wal_buffers=16MB
      -c random_page_cost=1.1
      -c effective_io_concurrency=200
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U jts_admin -d jts_trading"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-database-network

  clickhouse:
    image: clickhouse/clickhouse-server:23.8-alpine
    container_name: jts-clickhouse  
    restart: unless-stopped
    ports:
      - "8123:8123"
      - "9000:9000"
    volumes:
      - /var/lib/clickhouse:/var/lib/clickhouse
      - ./infrastructure/databases/clickhouse/config:/etc/clickhouse-server
      - ./infrastructure/databases/clickhouse/init:/docker-entrypoint-initdb.d
    environment:
      CLICKHOUSE_DB: jts_market_data
      CLICKHOUSE_USER: jts_ch_admin
      CLICKHOUSE_PASSWORD: ${CLICKHOUSE_PASSWORD}
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT: 1
    ulimits:
      nofile: 262144
    healthcheck:
      test: ["CMD", "clickhouse", "client", "--query", "SELECT 1"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-database-network

  mongodb:
    image: mongo:7.0
    container_name: jts-mongodb
    restart: unless-stopped
    ports:
      - "27017:27017"
    volumes:
      - /var/lib/mongodb:/data/db
      - ./infrastructure/databases/mongodb/init:/docker-entrypoint-initdb.d
    environment:
      MONGO_INITDB_ROOT_USERNAME: jts_mongo_admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGODB_PASSWORD}
      MONGO_INITDB_DATABASE: jts_config
    command: ["--replSet", "jts-rs0", "--bind_ip_all"]
    healthcheck:
      test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s  
      retries: 3
    networks:
      - jts-database-network

  redis:
    image: redis:7-alpine
    container_name: jts-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - /var/lib/redis:/data
      - ./infrastructure/databases/redis/config/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    environment:
      REDIS_PASSWORD: ${REDIS_PASSWORD}
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-database-network

networks:
  jts-database-network:
    driver: bridge
```

#### Phase 2: Schema Design and Migrations (Days 4-6)

3. **PostgreSQL Schema Design**
```sql
-- infrastructure/databases/postgresql/init/01-create-schemas.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schemas for logical separation
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS trading;
CREATE SCHEMA IF NOT EXISTS portfolio;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS risk;

-- Users and authentication
CREATE TABLE users.accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    mfa_secret VARCHAR(255),
    role VARCHAR(20) NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN', 'TRADER', 'ANALYST')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trading strategies
CREATE TABLE trading.strategies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users.accounts(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    strategy_type VARCHAR(50) NOT NULL,
    parameters JSONB NOT NULL,
    risk_parameters JSONB NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    is_paper_trading BOOLEAN NOT NULL DEFAULT TRUE,
    max_daily_loss DECIMAL(15,2) NOT NULL DEFAULT 0,
    max_position_size DECIMAL(15,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- Orders with complete lifecycle tracking
CREATE TABLE trading.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    strategy_id UUID NOT NULL REFERENCES trading.strategies(id) ON DELETE CASCADE,
    symbol VARCHAR(20) NOT NULL,
    exchange VARCHAR(20) NOT NULL,
    side VARCHAR(4) NOT NULL CHECK (side IN ('BUY', 'SELL')),
    order_type VARCHAR(15) NOT NULL CHECK (order_type IN ('MARKET', 'LIMIT', 'STOP', 'STOP_LIMIT')),
    quantity DECIMAL(18,8) NOT NULL CHECK (quantity > 0),
    price DECIMAL(18,8),
    stop_price DECIMAL(18,8),
    status VARCHAR(15) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SUBMITTED', 'ACCEPTED', 'PARTIAL', 'FILLED', 'CANCELLED', 'REJECTED', 'EXPIRED')),
    time_in_force VARCHAR(10) NOT NULL DEFAULT 'GTC' CHECK (time_in_force IN ('GTC', 'IOC', 'FOK', 'DAY')),
    broker_order_id VARCHAR(100),
    filled_quantity DECIMAL(18,8) NOT NULL DEFAULT 0,
    average_price DECIMAL(18,8),
    commission DECIMAL(10,4) NOT NULL DEFAULT 0,
    commission_currency VARCHAR(10),
    error_message TEXT,
    submitted_at TIMESTAMPTZ,
    executed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Portfolio positions
CREATE TABLE portfolio.positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users.accounts(id) ON DELETE CASCADE,
    symbol VARCHAR(20) NOT NULL,
    exchange VARCHAR(20) NOT NULL,
    quantity DECIMAL(18,8) NOT NULL DEFAULT 0,
    average_cost DECIMAL(18,8) NOT NULL DEFAULT 0,
    market_value DECIMAL(18,8) NOT NULL DEFAULT 0,
    unrealized_pnl DECIMAL(18,8) NOT NULL DEFAULT 0,
    realized_pnl DECIMAL(18,8) NOT NULL DEFAULT 0,
    total_commission DECIMAL(10,4) NOT NULL DEFAULT 0,
    last_price DECIMAL(18,8),
    last_update TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, symbol, exchange)
);

-- Performance optimized indexes
CREATE INDEX idx_orders_strategy_created ON trading.orders(strategy_id, created_at DESC);
CREATE INDEX idx_orders_symbol_exchange ON trading.orders(symbol, exchange);
CREATE INDEX idx_orders_status_created ON trading.orders(status, created_at DESC) WHERE status IN ('PENDING', 'SUBMITTED', 'ACCEPTED');
CREATE INDEX idx_orders_executed_at ON trading.orders(executed_at DESC) WHERE executed_at IS NOT NULL;
CREATE INDEX idx_positions_user_symbol ON portfolio.positions(user_id, symbol, exchange);
CREATE INDEX idx_strategies_user_active ON trading.strategies(user_id, is_active) WHERE is_active = true;

-- Audit triggers for change tracking
CREATE OR REPLACE FUNCTION audit.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER users_accounts_update_timestamp
    BEFORE UPDATE ON users.accounts
    FOR EACH ROW EXECUTE FUNCTION audit.update_timestamp();

CREATE TRIGGER trading_strategies_update_timestamp  
    BEFORE UPDATE ON trading.strategies
    FOR EACH ROW EXECUTE FUNCTION audit.update_timestamp();

CREATE TRIGGER trading_orders_update_timestamp
    BEFORE UPDATE ON trading.orders  
    FOR EACH ROW EXECUTE FUNCTION audit.update_timestamp();
```

4. **ClickHouse Market Data Schema**
```sql
-- infrastructure/databases/clickhouse/init/01-market-data-schema.sql
CREATE DATABASE IF NOT EXISTS jts_market_data;

-- Real-time price data optimized for high-frequency ingestion
CREATE TABLE jts_market_data.price_ticks (
    timestamp DateTime64(3) DEFAULT now64(),
    symbol LowCardinality(String),
    exchange LowCardinality(String),
    price Decimal64(8),
    volume Decimal64(8),
    bid_price Nullable(Decimal64(8)),
    ask_price Nullable(Decimal64(8)),
    bid_size Nullable(Decimal64(8)),
    ask_size Nullable(Decimal64(8)),
    trade_count UInt32 DEFAULT 1,
    vwap Nullable(Decimal64(8))
) ENGINE = ReplacingMergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (symbol, exchange, timestamp)
SETTINGS index_granularity = 8192;

-- OHLCV aggregated data for charting and analysis
CREATE TABLE jts_market_data.ohlcv_1min (
    timestamp DateTime,
    symbol LowCardinality(String), 
    exchange LowCardinality(String),
    open Decimal64(8),
    high Decimal64(8),
    low Decimal64(8),
    close Decimal64(8),
    volume Decimal64(8),
    trade_count UInt32,
    vwap Decimal64(8)
) ENGINE = ReplacingMergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (symbol, exchange, timestamp)
SETTINGS index_granularity = 8192;

-- Order book snapshots for market microstructure analysis
CREATE TABLE jts_market_data.orderbook_snapshots (
    timestamp DateTime64(3),
    symbol LowCardinality(String),
    exchange LowCardinality(String), 
    bids Array(Tuple(price Decimal64(8), size Decimal64(8))),
    asks Array(Tuple(price Decimal64(8), size Decimal64(8))),
    spread Decimal64(8),
    mid_price Decimal64(8)
) ENGINE = ReplacingMergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (symbol, exchange, timestamp)
TTL timestamp + INTERVAL 30 DAY;

-- Trading execution records
CREATE TABLE jts_market_data.trade_executions (
    timestamp DateTime64(3),
    order_id UUID,
    strategy_id UUID,
    symbol LowCardinality(String),
    exchange LowCardinality(String),
    side Enum8('BUY' = 1, 'SELL' = 2),
    quantity Decimal64(8),
    price Decimal64(8),
    commission Decimal64(8),
    slippage Decimal64(8),
    latency_ms UInt32
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (strategy_id, timestamp);

-- Performance analytics aggregations
CREATE MATERIALIZED VIEW jts_market_data.strategy_performance_daily
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (strategy_id, date)
AS SELECT
    strategy_id,
    toDate(timestamp) as date,
    sum(case when side = 'SELL' then quantity * price - commission else -quantity * price - commission end) as pnl,
    count() as trade_count,
    sum(commission) as total_commission,
    avg(slippage) as avg_slippage,
    max(latency_ms) as max_latency
FROM jts_market_data.trade_executions
GROUP BY strategy_id, toDate(timestamp);
```

#### Phase 3: Connection Management and Security (Days 7-9)

5. **Database Connection Configuration**
```typescript
// libs/shared/database/src/lib/database.config.ts
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

export class DatabaseConfigService {
  constructor(private configService: ConfigService) {}

  getPostgresConfig(): TypeOrmModuleOptions {
    return {
      type: 'postgres',
      host: this.configService.get<string>('POSTGRES_HOST', 'localhost'),
      port: this.configService.get<number>('POSTGRES_PORT', 5432),
      username: this.configService.get<string>('POSTGRES_USER', 'jts_admin'),
      password: this.configService.get<string>('POSTGRES_PASSWORD'),
      database: this.configService.get<string>('POSTGRES_DB', 'jts_trading'),
      entities: ['dist/**/*.entity{.ts,.js}'],
      migrations: ['dist/migrations/*{.ts,.js}'],
      synchronize: false,
      logging: this.configService.get<string>('NODE_ENV') === 'development',
      ssl: this.configService.get<string>('NODE_ENV') === 'production' ? {
        rejectUnauthorized: false
      } : false,
      extra: {
        connectionLimit: this.configService.get<number>('POSTGRES_CONNECTION_LIMIT', 20),
        acquireTimeout: 60000,
        timeout: 60000,
        reconnect: true,
        ssl: this.configService.get<string>('NODE_ENV') === 'production'
      },
      pool: {
        min: 5,
        max: 20,
        acquireTimeoutMillis: 30000,
        createTimeoutMillis: 30000,
        destroyTimeoutMillis: 5000,
        idleTimeoutMillis: 30000,
        reapIntervalMillis: 1000,
        createRetryIntervalMillis: 200
      }
    };
  }

  getClickHouseConfig() {
    return {
      host: this.configService.get<string>('CLICKHOUSE_HOST', 'localhost'),
      port: this.configService.get<number>('CLICKHOUSE_PORT', 8123),
      username: this.configService.get<string>('CLICKHOUSE_USER', 'jts_ch_admin'),
      password: this.configService.get<string>('CLICKHOUSE_PASSWORD'),
      database: this.configService.get<string>('CLICKHOUSE_DB', 'jts_market_data'),
      queryOptions: {
        database: 'jts_market_data',
        format: 'JSON',
        readonly: false
      },
      max_execution_time: 300,
      session_timeout: 60,
      output_format_json_quote_64bit_integers: 0,
      enable_http_compression: 1
    };
  }

  getMongoConfig() {
    const uri = this.configService.get<string>('MONGODB_URI') || 
      `mongodb://${this.configService.get<string>('MONGODB_USER', 'jts_mongo_admin')}:${this.configService.get<string>('MONGODB_PASSWORD')}@${this.configService.get<string>('MONGODB_HOST', 'localhost')}:${this.configService.get<number>('MONGODB_PORT', 27017)}/jts_config?authSource=admin`;
    
    return {
      uri,
      useNewUrlParser: true,
      useUnifiedTopology: true,
      maxPoolSize: 20,
      minPoolSize: 5,
      maxIdleTimeMS: 30000,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      bufferMaxEntries: 0,
      retryWrites: true,
      w: 'majority'
    };
  }

  getRedisConfig() {
    return {
      host: this.configService.get<string>('REDIS_HOST', 'localhost'),
      port: this.configService.get<number>('REDIS_PORT', 6379),
      password: this.configService.get<string>('REDIS_PASSWORD'),
      family: 4,
      keepAlive: 30000,
      maxRetriesPerRequest: 3,
      retryDelayOnFailover: 100,
      lazyConnect: true,
      db: 0
    };
  }
}
```

6. **Database Migration System**
```typescript
// libs/shared/database/src/lib/migration.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { readdir, readFile } from 'fs/promises';
import { join } from 'path';

@Injectable()
export class DatabaseMigrationService {
  private readonly logger = new Logger(DatabaseMigrationService.name);

  constructor(
    @InjectConnection() private connection: Connection
  ) {}

  async runMigrations(): Promise<void> {
    try {
      this.logger.log('Starting database migrations...');
      
      // Ensure migration table exists
      await this.createMigrationTable();
      
      // Get applied migrations
      const appliedMigrations = await this.getAppliedMigrations();
      
      // Get migration files
      const migrationFiles = await this.getMigrationFiles();
      
      // Apply pending migrations
      for (const file of migrationFiles) {
        if (!appliedMigrations.includes(file)) {
          await this.applyMigration(file);
        }
      }
      
      this.logger.log('Database migrations completed successfully');
    } catch (error) {
      this.logger.error('Failed to run database migrations', error);
      throw error;
    }
  }

  private async createMigrationTable(): Promise<void> {
    const query = `
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        migration_name VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `;
    await this.connection.query(query);
  }

  private async getAppliedMigrations(): Promise<string[]> {
    const result = await this.connection.query(
      'SELECT migration_name FROM schema_migrations ORDER BY applied_at'
    );
    return result.map((row: any) => row.migration_name);
  }

  private async getMigrationFiles(): Promise<string[]> {
    const migrationPath = join(process.cwd(), 'migrations');
    const files = await readdir(migrationPath);
    return files
      .filter(file => file.endsWith('.sql'))
      .sort();
  }

  private async applyMigration(filename: string): Promise<void> {
    try {
      this.logger.log(`Applying migration: ${filename}`);
      
      const migrationPath = join(process.cwd(), 'migrations', filename);
      const sql = await readFile(migrationPath, 'utf-8');
      
      await this.connection.transaction(async manager => {
        // Execute migration SQL
        await manager.query(sql);
        
        // Record migration as applied
        await manager.query(
          'INSERT INTO schema_migrations (migration_name) VALUES ($1)',
          [filename]
        );
      });
      
      this.logger.log(`Migration applied successfully: ${filename}`);
    } catch (error) {
      this.logger.error(`Failed to apply migration: ${filename}`, error);
      throw error;
    }
  }
}
```

#### Phase 4: Monitoring and Backup (Days 10-12)

7. **Database Health Monitoring**
```typescript
// libs/shared/database/src/lib/database-health.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { HealthIndicator, HealthIndicatorResult, HealthCheckError } from '@nestjs/terminus';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { Redis } from 'ioredis';
import { MongoClient } from 'mongodb';

@Injectable()
export class DatabaseHealthService extends HealthIndicator {
  private readonly logger = new Logger(DatabaseHealthService.name);

  constructor(
    @InjectConnection() private readonly postgresConnection: Connection,
    private readonly redis: Redis,
    private readonly mongoClient: MongoClient
  ) {
    super();
  }

  async checkPostgresHealth(key: string): Promise<HealthIndicatorResult> {
    try {
      await this.postgresConnection.query('SELECT 1');
      
      // Check connection pool status
      const poolSize = this.postgresConnection.driver.pool?.totalCount || 0;
      const activeConnections = this.postgresConnection.driver.pool?.acquiredCount || 0;
      
      return this.getStatus(key, true, {
        poolSize,
        activeConnections,
        status: 'connected'
      });
    } catch (error) {
      this.logger.error('PostgreSQL health check failed', error);
      throw new HealthCheckError('PostgreSQL health check failed', error);
    }
  }

  async checkRedisHealth(key: string): Promise<HealthIndicatorResult> {
    try {
      const result = await this.redis.ping();
      const info = await this.redis.info('memory');
      const memoryUsage = this.parseRedisMemoryInfo(info);
      
      if (result !== 'PONG') {
        throw new Error('Redis ping failed');
      }
      
      return this.getStatus(key, true, {
        status: 'connected',
        memoryUsage: memoryUsage,
        connectedClients: await this.redis.client('LIST').then(list => list.split('\n').length - 1)
      });
    } catch (error) {
      this.logger.error('Redis health check failed', error);
      throw new HealthCheckError('Redis health check failed', error);
    }
  }

  async checkMongoHealth(key: string): Promise<HealthIndicatorResult> {
    try {
      const adminDb = this.mongoClient.db('admin');
      const result = await adminDb.admin().ping();
      
      if (result.ok !== 1) {
        throw new Error('MongoDB ping failed');
      }
      
      const serverStatus = await adminDb.admin().serverStatus();
      
      return this.getStatus(key, true, {
        status: 'connected',
        connections: serverStatus.connections,
        uptime: serverStatus.uptime
      });
    } catch (error) {
      this.logger.error('MongoDB health check failed', error);
      throw new HealthCheckError('MongoDB health check failed', error);
    }
  }

  private parseRedisMemoryInfo(info: string): any {
    const lines = info.split('\r\n');
    const memoryInfo: any = {};
    
    lines.forEach(line => {
      if (line.includes(':')) {
        const [key, value] = line.split(':');
        if (key.includes('memory')) {
          memoryInfo[key] = value;
        }
      }
    });
    
    return memoryInfo;
  }
}
```

8. **Automated Backup System**
```bash
#!/bin/bash
# scripts/db-setup/backup-databases.sh

set -e

BACKUP_DIR="/backup/databases"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

# PostgreSQL backup
echo "Starting PostgreSQL backup..."
pg_dump -h localhost -U jts_admin -d jts_trading > "$BACKUP_DIR/postgresql_${DATE}.sql"
gzip "$BACKUP_DIR/postgresql_${DATE}.sql"

# ClickHouse backup
echo "Starting ClickHouse backup..."
clickhouse-client --host localhost --user jts_ch_admin --password $CLICKHOUSE_PASSWORD \
  --query "BACKUP DATABASE jts_market_data TO Disk('default', 'clickhouse_${DATE}.zip')"

# MongoDB backup  
echo "Starting MongoDB backup..."
mongodump --host localhost:27017 --username jts_mongo_admin --password $MONGODB_PASSWORD \
  --authenticationDatabase admin --out "$BACKUP_DIR/mongodb_${DATE}"
tar -czf "$BACKUP_DIR/mongodb_${DATE}.tar.gz" -C "$BACKUP_DIR" "mongodb_${DATE}"
rm -rf "$BACKUP_DIR/mongodb_${DATE}"

# Redis backup
echo "Starting Redis backup..."
redis-cli --rdb "$BACKUP_DIR/redis_${DATE}.rdb"
gzip "$BACKUP_DIR/redis_${DATE}.rdb"

# Cleanup old backups
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.zip" -mtime +$RETENTION_DAYS -delete

echo "Database backups completed successfully"
```

### Security Implementation

**Database User Management:**
```sql
-- Create application-specific users with minimal privileges
CREATE USER jts_app_user WITH PASSWORD 'secure_app_password';
CREATE USER jts_readonly_user WITH PASSWORD 'secure_readonly_password';
CREATE USER jts_analytics_user WITH PASSWORD 'secure_analytics_password';

-- Grant appropriate permissions
GRANT CONNECT ON DATABASE jts_trading TO jts_app_user;
GRANT USAGE ON SCHEMA users, trading, portfolio TO jts_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA users, trading, portfolio TO jts_app_user;

-- Read-only access for analytics
GRANT CONNECT ON DATABASE jts_trading TO jts_readonly_user;
GRANT USAGE ON ALL SCHEMAS IN DATABASE jts_trading TO jts_readonly_user;
GRANT SELECT ON ALL TABLES IN DATABASE jts_trading TO jts_readonly_user;
```

**SSL/TLS Configuration:**
```yaml
# SSL configuration for all databases
postgresql:
  environment:
    POSTGRES_SSL_MODE: require
    POSTGRES_SSL_CERT: /certs/postgresql.crt  
    POSTGRES_SSL_KEY: /certs/postgresql.key
    POSTGRES_SSL_CA: /certs/ca.crt

clickhouse:
  environment:
    CLICKHOUSE_SSL_ENABLED: 1
    CLICKHOUSE_SSL_CERT: /certs/clickhouse.crt
    CLICKHOUSE_SSL_KEY: /certs/clickhouse.key
    
mongodb:
  command: ["--sslMode", "requireSSL", "--sslPEMKeyFile", "/certs/mongodb.pem"]
  
redis:
  command: ["--tls-port", "6380", "--tls-cert-file", "/certs/redis.crt", "--tls-key-file", "/certs/redis.key"]
```

## Dependencies

- **1001**: Storage Infrastructure - Required for LVM volume setup and filesystem optimization

## Testing Plan

### Database Functionality Testing
- **Connection Testing**: Verify all database connections work with proper authentication
- **Schema Validation**: Confirm all schemas, indexes, and constraints are created correctly
- **Migration Testing**: Test migration system with rollback capabilities
- **CRUD Operations**: Validate basic database operations across all systems

### Performance Testing
- **Load Testing**: Test each database under realistic trading workloads
- **Concurrent Connection Testing**: Validate connection pooling under high concurrency
- **Query Performance**: Test critical queries meet latency requirements
- **Backup/Restore Performance**: Test backup and restore procedures under load

### Security Testing
- **Authentication Testing**: Verify user authentication and access controls
- **SSL/TLS Testing**: Confirm encrypted connections are working properly
- **Permission Testing**: Validate least-privilege access is enforced
- **Injection Testing**: Test SQL injection and other database attack vectors

### Reliability Testing
- **Failover Testing**: Test database failover and recovery scenarios
- **Data Integrity Testing**: Verify ACID compliance and data consistency
- **Monitoring Testing**: Confirm all health checks and alerts work correctly
- **Disaster Recovery Testing**: Test complete backup and restore procedures

## Claude Code Instructions

```
When implementing this feature:
1. Create docker-compose.databases.yml with all database services and optimized configurations
2. Set up LVM volumes with proper filesystem optimization for each database
3. Create comprehensive database schemas with appropriate indexes for trading workloads
4. Implement robust connection pooling and health monitoring for all databases
5. Set up automated backup scripts with retention policies and compression
6. Configure database-specific security settings including SSL/TLS and user management
7. Create migration system with rollback capabilities and version control
8. Implement comprehensive monitoring and alerting for database performance
9. Create database initialization scripts for development environment setup
10. Document all optimization settings with rationale and tuning guidelines
11. Test all database connections and verify performance under load
12. Implement proper error handling and retry logic in all database interactions
```

## Notes

- Each database is specifically optimized for its role in the trading system architecture
- Proper indexing strategies are critical for high-frequency trading performance requirements
- SSL/TLS encryption is mandatory for production deployments with sensitive financial data
- Backup and disaster recovery procedures must be regularly tested and validated
- Database monitoring should include both technical metrics and business-specific KPIs
- Consider implementing read replicas if query load becomes a bottleneck
- All database configurations should be externalized for different environments
- Migration rollback procedures should be thoroughly tested before production deployment

## Status Updates

- **2025-08-24**: Feature specification created with comprehensive database architecture design