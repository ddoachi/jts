# JTS Trading System - Docker Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Setup Walkthrough](#setup-walkthrough)
4. [Build and Deployment](#build-and-deployment)
5. [Service Architecture](#service-architecture)
6. [Security Best Practices](#security-best-practices)
7. [Performance Optimization](#performance-optimization)
8. [Troubleshooting](#troubleshooting)
9. [Example Commands & Workflows](#example-commands--workflows)
10. [Production Deployment](#production-deployment)

## Overview

The JTS (Job Trading System) is a comprehensive microservices-based automated trading platform built with Docker containers. This system provides real-time market data processing, algorithmic trading execution, risk management, and multi-broker integration for Korean and international markets.

### Key Features
- **6 Core Microservices**: API Gateway, Strategy Engine, Order Execution, Risk Management, Data Ingestion, Notification Service
- **Multi-Database Architecture**: PostgreSQL, ClickHouse, MongoDB, Redis
- **Event Streaming**: Apache Kafka with Zookeeper
- **Development Tools**: Grafana monitoring, MailHog email testing
- **Security**: Multi-stage builds, non-root users, distroless production images
- **High Availability**: Health checks, graceful shutdowns, circuit breakers

## Architecture

### System Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Client    │    │  Mobile App     │    │  External APIs  │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼───────────────┐
                    │      API Gateway            │
                    │        (Port 3000)          │
                    └─────────────┬───────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
          ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Strategy Engine │    │Order Execution  │    │Risk Management  │
│   (Port 3001)   │    │   (Port 3002)   │    │   (Port 3003)   │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └───────────────┬──────┴──────┬───────────────┘
                          │             │
                          ▼             ▼
                ┌─────────────────┐    ┌─────────────────┐
                │ Data Ingestion  │    │ Notification    │
                │   (Port 3004)   │    │   (Port 3005)   │
                └─────────────────┘    └─────────────────┘
```

### Data Layer Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   ClickHouse    │    │    MongoDB      │
│  Business Data  │    │ Time-Series     │    │  Configuration  │
│   (Port 5442)   │    │  (Port 8123)    │    │  (Port 27017)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼───────────────┐
                    │         Redis               │
                    │    Cache & Sessions         │
                    │       (Port 6379)           │
                    └─────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Kafka       │    │   Zookeeper     │    │    Grafana      │
│ Message Broker  │    │ Coordination    │    │   Monitoring    │
│  (Port 9092)    │    │  (Port 2181)    │    │  (Port 3100)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Setup Walkthrough

### Prerequisites

Ensure you have the following installed:

```bash
# Docker & Docker Compose
docker --version          # Docker 24.0+
docker-compose --version  # Docker Compose 2.0+

# System Requirements
# - 16GB RAM (minimum 8GB)
# - 4 CPU cores (minimum 2)
# - 50GB free disk space
# - Linux/macOS/Windows with WSL2
```

### Step 1: Clone and Setup Environment

```bash
# Clone the repository
git clone <repository-url>
cd jts-trading-system

# Copy environment template
cp .env.example .env.local

# Edit environment variables
vim .env.local  # or use your preferred editor
```

### Step 2: Environment Configuration

Edit `.env.local` with your specific configuration:

```bash
# === Core Configuration ===
NODE_ENV=development
LOG_LEVEL=debug

# === Database Credentials ===
POSTGRES_USER=jts_admin
POSTGRES_DB=jts_trading_dev
DEV_PASSWORD=your_secure_password_here

# === Broker Credentials (Required) ===
KIS_ACCOUNT_1_APPKEY=your_kis_api_key
KIS_ACCOUNT_1_APPSECRET=your_kis_secret
KIS_ACCOUNT_1_NUMBER=your_account_number

# === JWT Security ===
JWT_SECRET=your_super_secret_jwt_key_here
SESSION_SECRET=your_session_secret_here
```

### Step 3: Initial Setup

```bash
# Create required directories
mkdir -p logs/{api-gateway,strategy-engine,order-execution,risk-management,data-ingestion,notification-service}
mkdir -p data/temp
mkdir -p database/{postgres,clickhouse,mongodb}

# Set proper permissions
chmod -R 755 logs/
chmod -R 755 data/
```

### Step 4: Start Infrastructure Services

Start databases and message brokers first:

```bash
# Start infrastructure services
docker-compose -f docker-compose.dev.yml up -d postgres clickhouse mongodb redis kafka zookeeper

# Wait for services to be healthy
docker-compose -f docker-compose.dev.yml ps

# Check logs if any service fails
docker-compose -f docker-compose.dev.yml logs postgres
```

### Step 5: Initialize Databases

```bash
# Connect to PostgreSQL and create schemas
docker exec -it jts-postgres-dev psql -U jts_admin -d jts_trading_dev -c "
CREATE SCHEMA IF NOT EXISTS trading;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS audit;
"

# Verify ClickHouse connection
curl http://localhost:8123/ping

# Test Redis connection
docker exec -it jts-redis-dev redis-cli ping
```

### Step 6: Start Microservices

```bash
# Build and start all microservices
docker-compose -f docker-compose.dev.yml up -d

# Or start services individually
docker-compose -f docker-compose.dev.yml up -d api-gateway
docker-compose -f docker-compose.dev.yml up -d strategy-engine
docker-compose -f docker-compose.dev.yml up -d order-execution
docker-compose -f docker-compose.dev.yml up -d risk-management
docker-compose -f docker-compose.dev.yml up -d data-ingestion
docker-compose -f docker-compose.dev.yml up -d notification-service
```

### Step 7: Verify Installation

```bash
# Check all services are running
docker-compose -f docker-compose.dev.yml ps

# Test API Gateway
curl http://localhost:3000/health

# Access development tools
# Grafana: http://localhost:3100 (admin/dev_password)
# MailHog: http://localhost:8025
# API Docs: http://localhost:3000/api/docs
```

## Build and Deployment

### Multi-Stage Docker Build

The JTS system uses a sophisticated multi-stage build process with four distinct stages:

#### Stage 1: Base - Security Foundation
```dockerfile
FROM node:20.18.1-alpine3.20 AS base
# Minimal Alpine Linux with Node.js
# Security hardening with non-root user
# Essential dependencies only
```

#### Stage 2: Builder - Build Environment
```dockerfile
FROM base AS builder
# Full build toolchain (Python, make, g++)
# All dependencies including devDependencies
# Source code compilation and optimization
```

#### Stage 3: Development - Debug Environment
```dockerfile
FROM builder AS development
# Development tools (htop, curl, vim)
# Hot reloading support
# Debug ports exposed (9229)
# Source code volume mounting
```

#### Stage 4: Production - Minimal Runtime
```dockerfile
FROM gcr.io/distroless/nodejs20-debian12:nonroot AS production
# Distroless image (no shell, minimal attack surface)
# Only production dependencies
# Ultra-minimal image size
# Non-root user (UID 65532)
```

### Building Images

#### Development Build
```bash
# Build all services for development
docker-compose -f docker-compose.dev.yml build

# Build specific service
docker-compose -f docker-compose.dev.yml build api-gateway

# Build with no cache (clean build)
docker-compose -f docker-compose.dev.yml build --no-cache

# Build with parallel processing
docker-compose -f docker-compose.dev.yml build --parallel
```

#### Production Build
```bash
# Build production images
docker build --target production -t jts/api-gateway:latest ./apps/api-gateway
docker build --target production -t jts/strategy-engine:latest ./apps/strategy-engine
docker build --target production -t jts/order-execution:latest ./apps/order-execution
docker build --target production -t jts/risk-management:latest ./apps/risk-management
docker build --target production -t jts/data-ingestion:latest ./apps/data-ingestion
docker build --target production -t jts/notification-service:latest ./apps/notification-service

# Multi-architecture build (AMD64 + ARM64)
docker buildx build --platform linux/amd64,linux/arm64 --target production \
  -t jts/api-gateway:latest ./apps/api-gateway
```

#### Optimized Build Process
```bash
# Use BuildKit for enhanced performance
export DOCKER_BUILDKIT=1

# Build with custom build context
docker build -f docker/base/Dockerfile --target production \
  --build-arg NODE_ENV=production \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VCS_REF=$(git rev-parse --short HEAD) \
  -t jts/base:latest .

# Layer caching optimization
docker build --cache-from jts/base:cache --target production .
```

### Image Management

#### Tagging Strategy
```bash
# Semantic versioning
docker tag jts/api-gateway:latest jts/api-gateway:1.0.0
docker tag jts/api-gateway:latest jts/api-gateway:1.0
docker tag jts/api-gateway:latest jts/api-gateway:latest

# Environment-specific tags
docker tag jts/api-gateway:latest jts/api-gateway:dev
docker tag jts/api-gateway:latest jts/api-gateway:staging
docker tag jts/api-gateway:latest jts/api-gateway:prod

# Git-based tagging
GIT_SHA=$(git rev-parse --short HEAD)
docker tag jts/api-gateway:latest jts/api-gateway:${GIT_SHA}
```

#### Registry Operations
```bash
# Login to registry
docker login your-registry.com

# Push images
docker push jts/api-gateway:1.0.0
docker push jts/strategy-engine:1.0.0

# Pull images
docker pull jts/api-gateway:1.0.0

# Remove unused images
docker image prune -f
docker system prune -a
```

## Service Architecture

### API Gateway (Port 3000)

**Purpose**: Unified entry point for all client requests

**Key Features**:
- Authentication & authorization (JWT)
- Rate limiting (Redis-based)
- Request routing to microservices
- API versioning and documentation
- CORS handling

**Dependencies**:
- PostgreSQL (user data, sessions)
- Redis (rate limiting, caching)
- All backend microservices

**Configuration**:
```yaml
environment:
  STRATEGY_SERVICE_URL: http://strategy-engine:3001
  ORDER_SERVICE_URL: http://order-execution:3002
  RISK_SERVICE_URL: http://risk-management:3003
  DATA_SERVICE_URL: http://data-ingestion:3004
  NOTIFICATION_SERVICE_URL: http://notification-service:3005
  JWT_SECRET: ${JWT_SECRET}
  RATE_LIMIT_MAX_REQUESTS: 1000
  CORS_ORIGINS: http://localhost:3000,http://localhost:4200
```

**Health Check**:
```bash
curl http://localhost:3000/health
# Expected: {"status": "ok", "timestamp": "...", "services": {...}}
```

### Strategy Engine (Port 3001)

**Purpose**: Algorithmic trading brain and backtesting engine

**Key Features**:
- Real-time market data processing
- Strategy execution and signals generation
- Backtesting capabilities
- Mathematical computations for technical analysis
- Paper trading mode for development

**Dependencies**:
- PostgreSQL (strategy configurations)
- ClickHouse (historical market data)
- MongoDB (strategy parameters)
- Redis (real-time data caching)
- Kafka (market data streams)

**Resource Requirements**:
```yaml
deploy:
  resources:
    limits:
      memory: 4G
      cpus: 2.0
    reservations:
      memory: 2G
      cpus: 1.0
```

**Configuration**:
```yaml
environment:
  NODE_OPTIONS: --max-old-space-size=4096
  STRATEGY_EXECUTION_INTERVAL: 1000
  ENABLE_BACKTESTING: true
  ENABLE_PAPER_TRADING: true
  MAX_POSITION_SIZE: 10000
  MAX_DAILY_LOSS: 1000
```

### Order Execution (Port 3002)

**Purpose**: Trade execution and broker integration

**Key Features**:
- Multi-broker support (KIS, Creon)
- Order lifecycle management
- Circuit breaker pattern
- Retry logic with exponential backoff
- Real-time execution reporting

**Dependencies**:
- PostgreSQL (order history, audit)
- Redis (order caching, rate limiting)
- Kafka (execution events)

**Broker Configuration**:
```yaml
environment:
  # KIS Multi-Account Setup
  KIS_TOTAL_ACCOUNTS: 2
  KIS_API_BASE_URL: https://openapi.koreainvestment.com:9443
  KIS_PAPER_TRADING: true
  
  # Account 1
  KIS_ACCOUNT_1_APPKEY: ${KIS_ACCOUNT_1_APPKEY}
  KIS_ACCOUNT_1_APPSECRET: ${KIS_ACCOUNT_1_APPSECRET}
  KIS_ACCOUNT_1_NUMBER: ${KIS_ACCOUNT_1_NUMBER}
  
  # Rate Limiting
  KIS_RATE_LIMIT_PER_SECOND: 20
  KIS_RATE_LIMIT_PER_MINUTE: 200
```

### Risk Management (Port 3003)

**Purpose**: Real-time risk monitoring and controls

**Key Features**:
- Position-level risk monitoring
- Portfolio-level risk assessment
- VaR (Value at Risk) calculations
- Circuit breaker implementation
- Emergency liquidation controls

**Dependencies**:
- PostgreSQL (risk configurations)
- ClickHouse (risk metrics calculation)
- Redis (real-time risk data)
- Kafka (risk events)

**Risk Parameters**:
```yaml
environment:
  MAX_PORTFOLIO_VALUE: 100000
  MAX_POSITION_CONCENTRATION: 0.1    # 10%
  MAX_SECTOR_CONCENTRATION: 0.3      # 30%
  MAX_DAILY_LOSS: 2000
  RISK_CHECK_INTERVAL: 5000          # 5 seconds
  VAR_CONFIDENCE_LEVEL: 0.95
  CIRCUIT_BREAKER_LOSS_THRESHOLD: 0.05  # 5%
```

### Data Ingestion (Port 3004)

**Purpose**: Market data collection and processing

**Key Features**:
- Real-time data streaming
- Historical data collection
- Multi-source data aggregation
- High-throughput data processing
- Data normalization and validation

**Dependencies**:
- PostgreSQL (metadata, configuration)
- ClickHouse (time-series data storage)
- Redis (real-time data buffering)
- Kafka (data distribution)

**Data Sources**:
```yaml
environment:
  # KIS Market Data
  KIS_WEBSOCKET_URL: wss://openapi.koreainvestment.com:9443/websocket/v1
  
  # Yahoo Finance
  YAHOO_FINANCE_ENABLED: true
  
  # Data Collection Settings
  PRICE_UPDATE_INTERVAL: 1000        # 1 second
  VOLUME_UPDATE_INTERVAL: 5000       # 5 seconds
  ORDER_BOOK_UPDATE_INTERVAL: 500    # 500ms
  
  # Performance Settings
  NODE_OPTIONS: --max-old-space-size=8192
  BATCH_SIZE: 1000
  BUFFER_SIZE: 10000
```

### Notification Service (Port 3005)

**Purpose**: Multi-channel notification and alerting

**Key Features**:
- Multiple notification channels (email, Slack, webhooks)
- Alert routing based on severity
- Template-based notifications
- Rate limiting for notifications
- Delivery tracking and retries

**Dependencies**:
- PostgreSQL (notification history, templates)
- Redis (rate limiting, queuing)
- Kafka (notification events)
- MailHog (development email testing)

**Notification Channels**:
```yaml
environment:
  # Email (Development)
  EMAIL_ENABLED: true
  SMTP_HOST: mailhog
  SMTP_PORT: 1025
  
  # Slack Integration
  SLACK_ENABLED: true
  SLACK_WEBHOOK_URL: ${SLACK_WEBHOOK_URL}
  SLACK_CHANNEL: '#jts-dev-alerts'
  
  # Notification Rules
  ENABLE_RISK_ALERTS: true
  RISK_ALERT_THRESHOLD: 0.02         # 2%
  ENABLE_TRADE_ALERTS: true
  TRADE_ALERT_MIN_VALUE: 1000        # $1000
```

## Security Best Practices

### Container Security

#### 1. Non-Root User Execution
All containers run as non-root users to minimize security risks:

```dockerfile
# Development containers
USER jtsuser  # UID 1001

# Production containers (distroless)
USER 65532:65532  # nonroot user
```

#### 2. Minimal Base Images
```dockerfile
# Development: Alpine Linux (minimal)
FROM node:20.18.1-alpine3.20

# Production: Distroless (ultra-minimal)
FROM gcr.io/distroless/nodejs20-debian12:nonroot
```

#### 3. Security Scanning
```bash
# Install Trivy for security scanning
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan images for vulnerabilities
trivy image --severity HIGH,CRITICAL jts/api-gateway:latest
trivy image --severity HIGH,CRITICAL jts/strategy-engine:latest

# Scan during build process
docker build --target production -t jts/api-gateway:latest .
trivy image jts/api-gateway:latest
```

#### 4. Secret Management
```bash
# Use Docker secrets in production
echo "your_jwt_secret" | docker secret create jwt_secret -
echo "your_db_password" | docker secret create db_password -

# Reference in docker-compose.yml
services:
  api-gateway:
    secrets:
      - jwt_secret
      - db_password
    environment:
      JWT_SECRET_FILE: /run/secrets/jwt_secret
      DB_PASSWORD_FILE: /run/secrets/db_password

secrets:
  jwt_secret:
    external: true
  db_password:
    external: true
```

#### 5. Network Security
```yaml
networks:
  jts-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
    # Enable network encryption in production
    driver_opts:
      encrypted: "true"
```

#### 6. File System Security
```dockerfile
# Secure file permissions
RUN chmod 750 /app && \
    chmod 700 /app/tmp && \
    chmod 755 /app/logs && \
    chown -R jtsuser:jtsgroup /app

# Read-only file system in production
services:
  api-gateway:
    read_only: true
    tmpfs:
      - /tmp
      - /app/tmp
```

### Environment Security

#### 1. Environment Variable Management
```bash
# Never commit sensitive data
# Use .env.local (gitignored)
# Rotate secrets regularly

# Example secure .env.local
JWT_SECRET=$(openssl rand -hex 64)
SESSION_SECRET=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
```

#### 2. Database Security
```yaml
# PostgreSQL security
postgres:
  environment:
    POSTGRES_PASSWORD: ${SECURE_DB_PASSWORD}
  volumes:
    - ./configs/postgres/postgresql.conf:/etc/postgresql/postgresql.conf:ro
  command: >
    postgres
    -c ssl=on
    -c ssl_cert_file=/etc/ssl/certs/server.crt
    -c ssl_key_file=/etc/ssl/private/server.key
```

#### 3. TLS/SSL Configuration
```bash
# Generate TLS certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/C=US/ST=State/L=City/O=JTS/OU=IT/CN=jts.local"

# Use in nginx or API gateway
server {
    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/tls.crt;
    ssl_certificate_key /etc/ssl/private/tls.key;
}
```

## Performance Optimization

### Container Optimization

#### 1. Multi-Stage Build Optimization
```dockerfile
# Optimize layer caching
COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn install --immutable

# Copy source code last (changes frequently)
COPY . .
RUN yarn build
```

#### 2. Resource Limits and Reservations
```yaml
services:
  strategy-engine:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
    # Use memory swappiness for better performance
    sysctls:
      - vm.swappiness=10
```

#### 3. Volume Optimization
```yaml
volumes:
  # Use cached volumes for better performance
  - ./apps/api-gateway:/app/apps/api-gateway:cached
  - ./node_modules:/app/node_modules:cached
  
  # Use delegated volumes for write-heavy operations
  - ./logs:/app/logs:delegated
```

### Database Performance

#### 1. PostgreSQL Optimization
```yaml
postgres:
  command: >
    postgres
    -c max_connections=200
    -c shared_buffers=256MB
    -c effective_cache_size=1GB
    -c maintenance_work_mem=64MB
    -c checkpoint_completion_target=0.9
    -c wal_buffers=16MB
    -c default_statistics_target=100
    -c random_page_cost=1.1
    -c effective_io_concurrency=200
  volumes:
    - postgres_data:/var/lib/postgresql/data
  # Use performance-optimized storage
  volumes:
    postgres_data:
      driver: local
      driver_opts:
        type: 'none'
        o: 'bind'
        device: '/ssd/postgres-data'  # SSD storage
```

#### 2. ClickHouse Optimization
```yaml
clickhouse:
  environment:
    CLICKHOUSE_MAX_MEMORY_USAGE: 4000000000  # 4GB
    CLICKHOUSE_MAX_THREADS: 8
  ulimits:
    nofile:
      soft: 262144
      hard: 262144
  volumes:
    - clickhouse_data:/var/lib/clickhouse
    - ./configs/clickhouse/config.xml:/etc/clickhouse-server/config.xml:ro
```

#### 3. Redis Performance
```yaml
redis:
  command: redis-server /usr/local/etc/redis/redis.conf
  volumes:
    - ./configs/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
  # Redis configuration in redis.conf:
  # maxmemory 2gb
  # maxmemory-policy allkeys-lru
  # save ""  # Disable RDB for performance
  # appendonly yes  # Enable AOF for durability
```

### Network Performance

#### 1. Container Networking
```yaml
networks:
  jts-network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: jts-br0
      com.docker.network.driver.mtu: 9000  # Jumbo frames
```

#### 2. Service Communication Optimization
```bash
# Use internal network for service-to-service communication
STRATEGY_SERVICE_URL=http://strategy-engine:3001  # Internal
ORDER_SERVICE_URL=http://order-execution:3002     # Internal

# Avoid external network calls between services
```

### Application Performance

#### 1. Node.js Optimization
```yaml
environment:
  NODE_OPTIONS: "--max-old-space-size=4096 --enable-source-maps --optimize-for-size"
  UV_THREADPOOL_SIZE: 16  # Increase thread pool size
```

#### 2. Kafka Performance
```yaml
kafka:
  environment:
    KAFKA_MESSAGE_MAX_BYTES: 10485760      # 10MB
    KAFKA_REPLICA_FETCH_MAX_BYTES: 10485760
    KAFKA_NUM_PARTITIONS: 3                # Parallel processing
    KAFKA_HEAP_OPTS: "-Xmx2G -Xms2G"      # Fixed heap size
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Container Startup Issues

**Problem**: Container fails to start
```bash
# Check container logs
docker-compose -f docker-compose.dev.yml logs api-gateway

# Common issues:
# - Port conflicts
# - Missing environment variables
# - Database connection failures
```

**Solutions**:
```bash
# Check port conflicts
netstat -tulpn | grep :3000

# Verify environment variables
docker-compose -f docker-compose.dev.yml config

# Check database connectivity
docker exec -it jts-postgres-dev pg_isready -U jts_admin
```

#### 2. Database Connection Issues

**Problem**: Services cannot connect to databases
```bash
# Check database container status
docker-compose -f docker-compose.dev.yml ps postgres clickhouse mongodb redis

# Check network connectivity
docker exec -it jts-api-gateway-dev ping postgres
```

**Solutions**:
```bash
# Restart database containers
docker-compose -f docker-compose.dev.yml restart postgres

# Check database logs
docker-compose -f docker-compose.dev.yml logs postgres

# Verify credentials and connection strings
docker-compose -f docker-compose.dev.yml exec postgres psql -U jts_admin -d jts_trading_dev -c "SELECT 1;"
```

#### 3. Memory and Resource Issues

**Problem**: Containers running out of memory
```bash
# Monitor container resource usage
docker stats

# Check system resources
free -h
df -h
```

**Solutions**:
```bash
# Increase memory limits
services:
  strategy-engine:
    mem_limit: 4g
    mem_reservation: 2g

# Optimize Node.js memory usage
NODE_OPTIONS="--max-old-space-size=2048"

# Clean up unused containers and images
docker system prune -a
```

#### 4. Performance Issues

**Problem**: Slow application response
```bash
# Check container performance
docker stats --no-stream

# Monitor database performance
docker exec -it jts-postgres-dev psql -U jts_admin -c "
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC LIMIT 10;"
```

**Solutions**:
```bash
# Enable database query optimization
# Add indexes for frequently queried columns
# Increase database connection pools
# Use Redis caching for frequently accessed data
```

#### 5. Network Connectivity Issues

**Problem**: Services cannot communicate
```bash
# Test inter-service connectivity
docker exec -it jts-api-gateway-dev curl http://strategy-engine:3001/health

# Check network configuration
docker network ls
docker network inspect jts-dev-network
```

**Solutions**:
```bash
# Recreate network
docker network rm jts-dev-network
docker-compose -f docker-compose.dev.yml up -d

# Check service names and ports
docker-compose -f docker-compose.dev.yml ps
```

### Debugging Tools and Commands

#### 1. Container Debugging
```bash
# Access container shell
docker exec -it jts-api-gateway-dev sh

# Run temporary debug container
docker run --rm -it --network jts-dev-network alpine sh

# Attach to running container
docker attach jts-api-gateway-dev
```

#### 2. Log Analysis
```bash
# View real-time logs
docker-compose -f docker-compose.dev.yml logs -f api-gateway

# View logs with timestamps
docker-compose -f docker-compose.dev.yml logs -t api-gateway

# Search logs for errors
docker-compose -f docker-compose.dev.yml logs api-gateway | grep -i error

# Export logs to file
docker-compose -f docker-compose.dev.yml logs > jts-logs.txt
```

#### 3. Health Check Debugging
```bash
# Manual health checks
curl -f http://localhost:3000/health
curl -f http://localhost:3001/health

# Check Docker health status
docker inspect --format='{{.State.Health.Status}}' jts-api-gateway-dev

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' jts-api-gateway-dev
```

#### 4. Database Debugging
```bash
# PostgreSQL debugging
docker exec -it jts-postgres-dev psql -U jts_admin -d jts_trading_dev

# ClickHouse debugging
docker exec -it jts-clickhouse-dev clickhouse-client

# MongoDB debugging
docker exec -it jts-mongodb-dev mongosh mongodb://jts_mongo:dev_password@localhost:27017/jts_config_dev

# Redis debugging
docker exec -it jts-redis-dev redis-cli
```

## Example Commands & Workflows

### Development Workflows

#### 1. Full System Startup
```bash
# Start all services
./scripts/start-development.sh

# Or manually:
docker-compose -f docker-compose.dev.yml up -d

# Wait for all services to be healthy
./scripts/wait-for-services.sh

# Verify system status
./scripts/check-system-health.sh
```

#### 2. Single Service Development
```bash
# Start only infrastructure
docker-compose -f docker-compose.dev.yml up -d postgres clickhouse mongodb redis kafka zookeeper

# Start specific service for development
docker-compose -f docker-compose.dev.yml up api-gateway

# In another terminal, watch logs
docker-compose -f docker-compose.dev.yml logs -f api-gateway

# Restart after code changes
docker-compose -f docker-compose.dev.yml restart api-gateway
```

#### 3. Database Operations
```bash
# Initialize databases
./scripts/init-databases.sh

# Run migrations
docker exec -it jts-api-gateway-dev npm run migrate:dev

# Seed test data
docker exec -it jts-api-gateway-dev npm run seed:dev

# Backup databases
./scripts/backup-databases.sh

# Restore databases
./scripts/restore-databases.sh backup-2024-01-15.tar.gz
```

#### 4. Testing Workflows
```bash
# Run unit tests
docker exec -it jts-api-gateway-dev npm run test

# Run integration tests
docker exec -it jts-api-gateway-dev npm run test:integration

# Run all tests with coverage
docker exec -it jts-api-gateway-dev npm run test:coverage

# Run specific service tests
docker-compose -f docker-compose.dev.yml exec strategy-engine npm run test
```

### Monitoring and Maintenance

#### 1. System Monitoring
```bash
# Monitor all containers
watch docker-compose -f docker-compose.dev.yml ps

# Monitor resource usage
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Check container health
for service in $(docker-compose -f docker-compose.dev.yml ps --services); do
  echo "=== $service ==="
  docker-compose -f docker-compose.dev.yml ps $service
  docker exec -it jts-${service}-dev curl -f http://localhost:300${service#*-}/health || echo "Health check failed"
done
```

#### 2. Log Management
```bash
# Collect all logs
docker-compose -f docker-compose.dev.yml logs > logs/full-system-$(date +%Y%m%d-%H%M%S).log

# Rotate logs
./scripts/rotate-logs.sh

# Clean old logs
find logs/ -name "*.log" -mtime +7 -delete
```

#### 3. Performance Monitoring
```bash
# Database performance
docker exec -it jts-postgres-dev psql -U jts_admin -d jts_trading_dev -c "
SELECT schemaname,tablename,attname,n_distinct,correlation 
FROM pg_stats 
WHERE schemaname = 'trading' 
ORDER BY n_distinct DESC;
"

# Redis performance
docker exec -it jts-redis-dev redis-cli info stats

# Kafka performance
docker exec -it jts-kafka-dev kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

### Deployment Workflows

#### 1. Build and Tag Images
```bash
# Build all production images
./scripts/build-production.sh

# Tag images for deployment
docker tag jts/api-gateway:latest your-registry.com/jts/api-gateway:1.0.0
docker tag jts/strategy-engine:latest your-registry.com/jts/strategy-engine:1.0.0

# Push to registry
docker push your-registry.com/jts/api-gateway:1.0.0
docker push your-registry.com/jts/strategy-engine:1.0.0
```

#### 2. Environment Promotion
```bash
# Deploy to staging
./scripts/deploy-staging.sh

# Run integration tests against staging
./scripts/test-staging.sh

# Deploy to production (with approval)
./scripts/deploy-production.sh --require-approval
```

### Utility Commands

#### 1. System Cleanup
```bash
# Stop all services
docker-compose -f docker-compose.dev.yml down

# Remove volumes (destructive!)
docker-compose -f docker-compose.dev.yml down -v

# Clean system
docker system prune -a --volumes

# Remove all JTS containers and images
docker ps -a | grep jts | awk '{print $1}' | xargs docker rm
docker images | grep jts | awk '{print $3}' | xargs docker rmi
```

#### 2. Backup and Restore
```bash
# Backup all data
./scripts/backup-system.sh

# Backup specific database
docker exec jts-postgres-dev pg_dump -U jts_admin jts_trading_dev > backup-postgres-$(date +%Y%m%d).sql

# Restore from backup
./scripts/restore-system.sh backup-20240115.tar.gz
```

#### 3. Security Operations
```bash
# Security scan
./scripts/security-scan.sh

# Update base images
./scripts/update-base-images.sh

# Rotate secrets
./scripts/rotate-secrets.sh
```

## Production Deployment

### Production Architecture Considerations

#### 1. Container Orchestration
For production deployment, consider using Kubernetes or Docker Swarm:

**Kubernetes Deployment**:
```yaml
# k8s-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jts-api-gateway
spec:
  replicas: 3
  selector:
    matchLabels:
      app: jts-api-gateway
  template:
    metadata:
      labels:
        app: jts-api-gateway
    spec:
      containers:
      - name: api-gateway
        image: your-registry.com/jts/api-gateway:1.0.0
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jts-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Docker Swarm Deployment**:
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  api-gateway:
    image: your-registry.com/jts/api-gateway:1.0.0
    deploy:
      replicas: 3
      placement:
        constraints:
          - node.role == worker
      resources:
        limits:
          cpus: '0.5'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        order: start-first
    networks:
      - jts-prod-network
    secrets:
      - jwt_secret
      - db_password
```

#### 2. High Availability Setup

**Load Balancer Configuration** (Nginx):
```nginx
upstream api_gateway {
    least_conn;
    server api-gateway-1:3000 max_fails=3 fail_timeout=30s;
    server api-gateway-2:3000 max_fails=3 fail_timeout=30s;
    server api-gateway-3:3000 max_fails=3 fail_timeout=30s;
}

server {
    listen 443 ssl http2;
    server_name api.jts.com;
    
    ssl_certificate /etc/ssl/certs/jts.crt;
    ssl_certificate_key /etc/ssl/private/jts.key;
    
    location / {
        proxy_pass http://api_gateway;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Health check
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }
}
```

**Database High Availability**:
```yaml
# PostgreSQL with replication
postgres-master:
  image: postgres:15-alpine
  environment:
    POSTGRES_REPLICATION_MODE: master
    POSTGRES_REPLICATION_USER: replicator
    POSTGRES_REPLICATION_PASSWORD: ${REPLICATION_PASSWORD}
  volumes:
    - postgres_master_data:/var/lib/postgresql/data

postgres-slave:
  image: postgres:15-alpine
  environment:
    POSTGRES_REPLICATION_MODE: slave
    POSTGRES_REPLICATION_USER: replicator
    POSTGRES_REPLICATION_PASSWORD: ${REPLICATION_PASSWORD}
    POSTGRES_MASTER_HOST: postgres-master
  volumes:
    - postgres_slave_data:/var/lib/postgresql/data
```

#### 3. Security Hardening

**Production Security Configuration**:
```yaml
services:
  api-gateway:
    image: your-registry.com/jts/api-gateway:1.0.0
    # Run as non-root
    user: "65532:65532"
    # Read-only filesystem
    read_only: true
    # Minimal capabilities
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    # Security options
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
    tmpfs:
      - /tmp:noexec,nosuid,size=128m
      - /var/run:noexec,nosuid,size=128m
```

**Network Security**:
```yaml
networks:
  jts-prod-network:
    driver: overlay
    driver_opts:
      encrypted: "true"
    attachable: false
    internal: true
  
  jts-public-network:
    driver: overlay
    attachable: false
```

#### 4. Monitoring and Observability

**Prometheus Configuration**:
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'jts-services'
    static_configs:
      - targets:
        - api-gateway:3000
        - strategy-engine:3001
        - order-execution:3002
        - risk-management:3003
        - data-ingestion:3004
        - notification-service:3005
    metrics_path: /metrics
    scrape_interval: 10s
```

**Grafana Dashboards**:
```yaml
grafana:
  image: grafana/grafana:latest
  environment:
    GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
    GF_INSTALL_PLUGINS: grafana-piechart-panel,grafana-clock-panel
  volumes:
    - grafana_data:/var/lib/grafana
    - ./monitoring/dashboards:/etc/grafana/provisioning/dashboards:ro
    - ./monitoring/datasources:/etc/grafana/provisioning/datasources:ro
```

**Logging with ELK Stack**:
```yaml
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
  environment:
    discovery.type: single-node
    xpack.security.enabled: false
  volumes:
    - elasticsearch_data:/usr/share/elasticsearch/data

logstash:
  image: docker.elastic.co/logstash/logstash:8.11.0
  volumes:
    - ./configs/logstash/pipeline:/usr/share/logstash/pipeline:ro

kibana:
  image: docker.elastic.co/kibana/kibana:8.11.0
  environment:
    ELASTICSEARCH_HOSTS: http://elasticsearch:9200
  ports:
    - "5601:5601"
```

#### 5. Backup and Disaster Recovery

**Automated Backup Strategy**:
```bash
#!/bin/bash
# backup-production.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/jts-$DATE"

mkdir -p $BACKUP_DIR

# Database backups
docker exec jts-postgres-prod pg_dump -U jts_admin jts_trading_prod > $BACKUP_DIR/postgres.sql
docker exec jts-clickhouse-prod clickhouse-client --query="BACKUP DATABASE jts_market_data_prod" > $BACKUP_DIR/clickhouse.sql
docker exec jts-mongodb-prod mongodump --db jts_config_prod --out $BACKUP_DIR/mongodb/

# Configuration backups
cp -r /opt/jts/configs $BACKUP_DIR/configs/
cp -r /opt/jts/secrets $BACKUP_DIR/secrets/

# Container images
docker save jts/api-gateway:latest > $BACKUP_DIR/api-gateway.tar
docker save jts/strategy-engine:latest > $BACKUP_DIR/strategy-engine.tar

# Compress backup
tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR/
rm -rf $BACKUP_DIR/

# Upload to S3 or backup storage
aws s3 cp $BACKUP_DIR.tar.gz s3://jts-backups/production/

echo "Backup completed: $BACKUP_DIR.tar.gz"
```

**Disaster Recovery Plan**:
```bash
#!/bin/bash
# disaster-recovery.sh

BACKUP_FILE=$1
RECOVERY_DIR="/recovery/$(date +%Y%m%d_%H%M%S)"

mkdir -p $RECOVERY_DIR
cd $RECOVERY_DIR

# Download and extract backup
aws s3 cp s3://jts-backups/production/$BACKUP_FILE .
tar -xzf $BACKUP_FILE

# Restore databases
docker exec -i jts-postgres-prod psql -U jts_admin jts_trading_prod < postgres.sql
docker exec -i jts-clickhouse-prod clickhouse-client < clickhouse.sql
docker exec -i jts-mongodb-prod mongorestore mongodb/

# Restore configurations
cp -r configs/* /opt/jts/configs/
cp -r secrets/* /opt/jts/secrets/

# Load container images
docker load < api-gateway.tar
docker load < strategy-engine.tar

# Restart services
docker stack deploy -c docker-compose.prod.yml jts

echo "Disaster recovery completed"
```

### Production Deployment Checklist

#### Pre-Deployment
- [ ] Security scan completed
- [ ] All tests passed (unit, integration, e2e)
- [ ] Performance benchmarks validated
- [ ] Database migrations tested
- [ ] Secrets and certificates updated
- [ ] Monitoring and alerting configured
- [ ] Backup strategy verified
- [ ] Rollback plan documented

#### Deployment
- [ ] Blue-green deployment ready
- [ ] Health checks validated
- [ ] Service dependencies verified
- [ ] Configuration validated
- [ ] Performance monitoring active
- [ ] Error tracking enabled

#### Post-Deployment
- [ ] All services healthy
- [ ] Critical business flows tested
- [ ] Performance metrics within SLA
- [ ] Monitoring dashboards updated
- [ ] Documentation updated
- [ ] Team notification sent

---

## Additional Resources

### Documentation Links
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Node.js Docker Best Practices](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)
- [Container Security Guide](https://docs.docker.com/engine/security/)

### JTS-Specific Documentation
- [Architecture Overview](../architecture/README.md)
- [API Documentation](../api/README.md)
- [Development Guide](../development/README.md)
- [Deployment Guide](../deployment/README.md)

### Tools and Utilities
- [Development Scripts](../../scripts/)
- [Configuration Templates](../../configs/)
- [Monitoring Dashboards](../../monitoring/)
- [Security Policies](../../security/)

---

*This documentation is maintained by the JTS development team. For questions or improvements, please create an issue or submit a pull request.*