---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '1008' # Numeric ID for stable reference
title: 'Monitoring and Logging Foundation'
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
estimated_hours: 18 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: ['1003', '1005'] # Must be done before this (spec IDs)
blocks: ['2000', '3000', '4000', '5000', '6000'] # This blocks these specs (spec IDs)
related: ['1006', '1007'] # Related but not blocking (spec IDs)

# === IMPLEMENTATION ===
branch: 'feature/1008-monitoring-logging' # Git branch name
files: ['infrastructure/monitoring/', 'docker-compose.monitoring.yml', 'libs/shared/logging/', 'libs/shared/metrics/', 'infrastructure/grafana/', 'infrastructure/prometheus/'] # Key files to modify

# === METADATA ===
tags: ['monitoring', 'logging', 'elk-stack', 'prometheus', 'grafana', 'observability', 'alerts', 'tracing'] # Searchable tags
effort: 'large' # small | medium | large | epic
risk: 'medium' # low | medium | high

# ============================================================================
---

# Monitoring and Logging Foundation

## Overview

Establish a comprehensive monitoring, logging, and observability infrastructure for the JTS automated trading system. This feature implements the ELK stack (Elasticsearch, Logstash, Kibana) for centralized logging, Prometheus for metrics collection, Grafana for visualization dashboards, distributed tracing with Jaeger, and intelligent alerting systems. The monitoring foundation provides real-time visibility into system performance, trading operations, and business metrics critical for high-frequency trading operations.

## Acceptance Criteria

- [ ] **ELK Stack Deployment**: Production-ready Elasticsearch cluster with Logstash for log processing and Kibana for log visualization and analysis
- [ ] **Prometheus Metrics**: Comprehensive metrics collection infrastructure with custom trading metrics, system metrics, and application performance monitoring
- [ ] **Grafana Dashboards**: Pre-configured dashboards for system health, trading performance, market data analytics, and business KPIs
- [ ] **Distributed Tracing**: Jaeger implementation with request tracing across all microservices and external broker integrations
- [ ] **Alerting System**: Multi-channel alert configuration (email, Slack, webhooks) with intelligent thresholds for trading operations
- [ ] **Log Aggregation**: Structured logging with correlation IDs, log levels, and standardized formats across all services
- [ ] **Performance Monitoring**: APM integration with latency tracking, error rate monitoring, and throughput analysis
- [ ] **Security Monitoring**: Security event logging, audit trails, and anomaly detection for trading operations
- [ ] **Custom Metrics**: Trading-specific metrics including order latency, strategy performance, P&L tracking, and risk metrics
- [ ] **Retention Policies**: Automated log and metric retention with archival strategies optimized for regulatory compliance

## Technical Approach

### Comprehensive Observability Architecture

Implement a multi-layered observability stack designed specifically for high-frequency trading systems with strict latency and reliability requirements:

**Observability Stack Components:**
- **Logging**: ELK stack with structured JSON logging and correlation tracking
- **Metrics**: Prometheus with custom trading metrics and business KPIs
- **Tracing**: Jaeger for distributed request tracing across microservices
- **Visualization**: Grafana with trading-specific dashboards and real-time monitoring
- **Alerting**: AlertManager with intelligent thresholds and multi-channel notifications

### Key Components

#### 1. ELK Stack - Centralized Logging
**Purpose**: Centralized log aggregation, processing, and analysis for all system components
**Storage Allocation**: Shared with database infrastructure, leveraging ClickHouse for long-term log storage
**Key Features**:
- Structured JSON logging with correlation IDs for request tracing
- Log parsing and enrichment with trading context (strategy, symbol, exchange)
- Real-time log streaming and search capabilities
- Automated log forwarding to regulatory compliance systems
- Log-based alerting for critical system events

**ELK Configuration Strategy**:
```yaml
# Elasticsearch cluster configuration
elasticsearch:
  cluster.name: jts-logging-cluster
  node.name: jts-es-node-1
  discovery.type: single-node
  xpack.security.enabled: true
  xpack.monitoring.enabled: true
  indices.query.bool.max_clause_count: 10000
  bootstrap.memory_lock: true
  # Optimized for log ingestion
  index.refresh_interval: 30s
  index.number_of_replicas: 1
  index.number_of_shards: 3

# Logstash processing pipeline
logstash:
  pipeline.workers: 4
  pipeline.batch.size: 1000
  pipeline.batch.delay: 50
  queue.type: persisted
  queue.max_bytes: 4gb
```

#### 2. Prometheus Metrics Collection
**Purpose**: High-performance metrics collection and storage for system and business metrics
**Storage Strategy**: Integrated with existing infrastructure, short-term storage in Prometheus, long-term in ClickHouse
**Key Features**:
- Custom trading metrics (order latency, execution success rates, P&L)
- System metrics (CPU, memory, disk I/O, network throughput)
- Application metrics (request rates, error rates, response times)
- Business KPIs (daily volume, strategy performance, risk exposure)
- Real-time metric streaming to external systems

**Prometheus Configuration Strategy**:
```yaml
# Prometheus server configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'jts-trading'
    environment: 'production'

# Trading-specific metric collection
scrape_configs:
  - job_name: 'jts-api-gateway'
    static_configs:
      - targets: ['api-gateway:3000']
    scrape_interval: 5s
    metrics_path: '/metrics'
    
  - job_name: 'jts-strategy-engine'
    static_configs:
      - targets: ['strategy-engine:3001']
    scrape_interval: 2s  # High frequency for trading metrics
    
  - job_name: 'jts-order-execution'
    static_configs:
      - targets: ['order-execution:3003']
    scrape_interval: 1s  # Critical path monitoring
```

#### 3. Grafana Visualization Dashboards
**Purpose**: Real-time visualization and monitoring dashboards for trading operations
**Integration**: Connected to Prometheus, Elasticsearch, and ClickHouse data sources
**Key Features**:
- Real-time trading dashboard with P&L, positions, and order flow
- System health dashboard with infrastructure metrics
- Strategy performance dashboard with backtesting comparisons
- Market data dashboard with price feeds and order book analysis
- Alerting dashboard with current alerts and escalation status

**Dashboard Configuration Strategy**:
```json
{
  "dashboard": {
    "title": "JTS Trading Operations",
    "panels": [
      {
        "title": "Order Execution Latency",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, order_execution_duration_seconds_bucket)",
            "legendFormat": "95th percentile"
          }
        ],
        "thresholds": [
          {"value": 0.1, "color": "yellow"},
          {"value": 0.5, "color": "red"}
        ]
      }
    ]
  }
}
```

#### 4. Jaeger Distributed Tracing
**Purpose**: End-to-end request tracing across microservices and external integrations
**Storage**: Elasticsearch backend for trace storage and analysis
**Key Features**:
- Order lifecycle tracing from submission to execution
- Strategy execution tracing across all components
- Broker API interaction tracing with latency analysis
- Error propagation tracking and root cause analysis
- Performance bottleneck identification

**Jaeger Configuration Strategy**:
```yaml
# Jaeger configuration
jaeger:
  strategy: production
  collector:
    num-workers: 100
    queue-size: 2000
  storage:
    type: elasticsearch
    elasticsearch:
      server-urls: http://elasticsearch:9200
      index-prefix: jaeger
      username: jaeger
      password: ${JAEGER_PASSWORD}
```

### Implementation Steps

#### Phase 1: ELK Stack Deployment (Days 1-4)

1. **Elasticsearch Cluster Setup**
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: jts-elasticsearch
    restart: unless-stopped
    ports:
      - "9200:9200"
      - "9300:9300"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
      - ./infrastructure/monitoring/elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - ./infrastructure/monitoring/elasticsearch/config/jvm.options:/usr/share/elasticsearch/config/jvm.options
    environment:
      - cluster.name=jts-logging-cluster
      - node.name=jts-es-node-1
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
      - xpack.security.enabled=true
      - xpack.security.authc.api_key.enabled=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200/_cluster/health | grep -q '\"status\":\"\\(green\\|yellow\\)\"'"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-monitoring-network

  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    container_name: jts-logstash
    restart: unless-stopped
    ports:
      - "5044:5044"
      - "9600:9600"
    volumes:
      - ./infrastructure/monitoring/logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml
      - ./infrastructure/monitoring/logstash/pipeline:/usr/share/logstash/pipeline
    environment:
      - LS_JAVA_OPTS=-Xms2g -Xmx2g
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
    depends_on:
      elasticsearch:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9600/_node/stats"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-monitoring-network

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: jts-kibana
    restart: unless-stopped
    ports:
      - "5601:5601"
    volumes:
      - ./infrastructure/monitoring/kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
      - SERVER_NAME=jts-kibana
    depends_on:
      elasticsearch:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 200 OK'"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-monitoring-network
```

2. **Logstash Pipeline Configuration**
```ruby
# infrastructure/monitoring/logstash/pipeline/trading-logs.conf
input {
  beats {
    port => 5044
  }
  
  # Direct log input from applications
  tcp {
    port => 5000
    codec => json_lines
  }
  
  # Redis input for high-frequency logs
  redis {
    host => "redis"
    port => 6379
    password => "${REDIS_PASSWORD}"
    key => "trading-logs"
    data_type => "list"
    codec => json
  }
}

filter {
  # Add timestamp if missing
  if ![timestamp] {
    mutate {
      add_field => { "timestamp" => "%{@timestamp}" }
    }
  }
  
  # Parse trading-specific fields
  if [service] == "order-execution" {
    grok {
      match => { 
        "message" => "%{WORD:action} order %{WORD:order_id} for %{WORD:symbol} at %{NUMBER:price} quantity %{NUMBER:quantity}"
      }
    }
    
    mutate {
      convert => { 
        "price" => "float"
        "quantity" => "float"
      }
    }
  }
  
  # Add geolocation for IP addresses
  if [client_ip] {
    geoip {
      source => "client_ip"
      target => "geoip"
    }
  }
  
  # Calculate execution latency
  if [start_time] and [end_time] {
    ruby {
      code => "
        start_ms = event.get('start_time')
        end_ms = event.get('end_time')
        if start_ms && end_ms
          latency = end_ms - start_ms
          event.set('execution_latency_ms', latency)
        end
      "
    }
  }
  
  # Enrich with trading context
  if [strategy_id] {
    elasticsearch {
      hosts => ["elasticsearch:9200"]
      user => "logstash_user"
      password => "${ELASTIC_PASSWORD}"
      index => "trading-strategies"
      query => "id:%{strategy_id}"
      fields => {
        "strategy_name" => "strategy_name"
        "strategy_type" => "strategy_type"
      }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    user => "logstash_user"
    password => "${ELASTIC_PASSWORD}"
    index => "jts-logs-%{+YYYY.MM.dd}"
    template_name => "jts-logs"
    template_pattern => "jts-logs-*"
    template => "/usr/share/logstash/templates/jts-logs-template.json"
  }
  
  # Output critical errors to separate index
  if [level] == "ERROR" or [level] == "FATAL" {
    elasticsearch {
      hosts => ["elasticsearch:9200"]
      user => "logstash_user"
      password => "${ELASTIC_PASSWORD}"
      index => "jts-errors-%{+YYYY.MM.dd}"
    }
  }
  
  # Real-time alerts for trading errors
  if [service] == "order-execution" and [level] == "ERROR" {
    http {
      url => "http://alertmanager:9093/api/v1/alerts"
      http_method => "post"
      format => "json"
      mapping => {
        "alerts" => [
          {
            "labels" => {
              "alertname" => "OrderExecutionError"
              "service" => "%{service}"
              "severity" => "critical"
              "order_id" => "%{order_id}"
            }
            "annotations" => {
              "summary" => "Order execution failed"
              "description" => "%{message}"
            }
          }
        ]
      }
    }
  }
}
```

#### Phase 2: Prometheus and Metrics (Days 5-8)

3. **Prometheus Server Setup**
```yaml
# Continue docker-compose.monitoring.yml
  prometheus:
    image: prom/prometheus:v2.47.0
    container_name: jts-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - prometheus-data:/prometheus
      - ./infrastructure/monitoring/prometheus/config/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./infrastructure/monitoring/prometheus/rules:/etc/prometheus/rules
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
      - '--storage.tsdb.retention.time=30d'
      - '--storage.tsdb.retention.size=10GB'
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-monitoring-network

  alertmanager:
    image: prom/alertmanager:v0.25.0
    container_name: jts-alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - alertmanager-data:/alertmanager
      - ./infrastructure/monitoring/alertmanager/config/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9093/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-monitoring-network
```

4. **Custom Trading Metrics Implementation**
```typescript
// libs/shared/metrics/src/lib/trading-metrics.service.ts
import { Injectable } from '@nestjs/common';
import { register, Counter, Histogram, Gauge, Summary } from 'prom-client';

@Injectable()
export class TradingMetricsService {
  // Order execution metrics
  private readonly orderExecutionDuration = new Histogram({
    name: 'order_execution_duration_seconds',
    help: 'Duration of order execution in seconds',
    labelNames: ['strategy_id', 'symbol', 'exchange', 'side', 'order_type'],
    buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5]
  });

  private readonly orderExecutionTotal = new Counter({
    name: 'order_execution_total',
    help: 'Total number of order executions',
    labelNames: ['strategy_id', 'symbol', 'exchange', 'side', 'status']
  });

  private readonly orderExecutionErrors = new Counter({
    name: 'order_execution_errors_total',
    help: 'Total number of order execution errors',
    labelNames: ['strategy_id', 'symbol', 'exchange', 'error_type']
  });

  // Strategy performance metrics
  private readonly strategyPnl = new Gauge({
    name: 'strategy_pnl_total',
    help: 'Total P&L for each strategy',
    labelNames: ['strategy_id', 'strategy_name', 'user_id']
  });

  private readonly strategyDrawdown = new Gauge({
    name: 'strategy_drawdown_current',
    help: 'Current drawdown for each strategy',
    labelNames: ['strategy_id', 'strategy_name']
  });

  private readonly strategyWinRate = new Gauge({
    name: 'strategy_win_rate',
    help: 'Win rate percentage for each strategy',
    labelNames: ['strategy_id', 'strategy_name']
  });

  // Market data metrics
  private readonly marketDataLatency = new Histogram({
    name: 'market_data_latency_seconds',
    help: 'Latency of market data updates',
    labelNames: ['symbol', 'exchange', 'data_type'],
    buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1]
  });

  private readonly marketDataUpdates = new Counter({
    name: 'market_data_updates_total',
    help: 'Total number of market data updates',
    labelNames: ['symbol', 'exchange', 'data_type']
  });

  // Risk management metrics
  private readonly riskViolations = new Counter({
    name: 'risk_violations_total',
    help: 'Total number of risk rule violations',
    labelNames: ['strategy_id', 'rule_type', 'severity']
  });

  private readonly portfolioExposure = new Gauge({
    name: 'portfolio_exposure_total',
    help: 'Total portfolio exposure by currency',
    labelNames: ['currency', 'user_id']
  });

  // System performance metrics
  private readonly apiRequestDuration = new Summary({
    name: 'api_request_duration_seconds',
    help: 'Duration of API requests',
    labelNames: ['method', 'endpoint', 'status_code'],
    percentiles: [0.5, 0.9, 0.95, 0.99]
  });

  private readonly databaseConnectionPool = new Gauge({
    name: 'database_connection_pool_active',
    help: 'Active database connections',
    labelNames: ['database_type', 'database_name']
  });

  // Method implementations
  recordOrderExecution(
    strategyId: string,
    symbol: string,
    exchange: string,
    side: string,
    orderType: string,
    duration: number,
    status: string
  ): void {
    this.orderExecutionDuration
      .labels(strategyId, symbol, exchange, side, orderType)
      .observe(duration);
    
    this.orderExecutionTotal
      .labels(strategyId, symbol, exchange, side, status)
      .inc();
  }

  recordOrderExecutionError(
    strategyId: string,
    symbol: string,
    exchange: string,
    errorType: string
  ): void {
    this.orderExecutionErrors
      .labels(strategyId, symbol, exchange, errorType)
      .inc();
  }

  updateStrategyPnl(
    strategyId: string,
    strategyName: string,
    userId: string,
    pnl: number
  ): void {
    this.strategyPnl
      .labels(strategyId, strategyName, userId)
      .set(pnl);
  }

  recordMarketDataUpdate(
    symbol: string,
    exchange: string,
    dataType: string,
    latency: number
  ): void {
    this.marketDataLatency
      .labels(symbol, exchange, dataType)
      .observe(latency);
    
    this.marketDataUpdates
      .labels(symbol, exchange, dataType)
      .inc();
  }

  recordRiskViolation(
    strategyId: string,
    ruleType: string,
    severity: string
  ): void {
    this.riskViolations
      .labels(strategyId, ruleType, severity)
      .inc();
  }

  recordApiRequest(
    method: string,
    endpoint: string,
    statusCode: string,
    duration: number
  ): void {
    this.apiRequestDuration
      .labels(method, endpoint, statusCode)
      .observe(duration);
  }

  updateDatabaseConnections(
    databaseType: string,
    databaseName: string,
    activeConnections: number
  ): void {
    this.databaseConnectionPool
      .labels(databaseType, databaseName)
      .set(activeConnections);
  }

  // Get all metrics for Prometheus scraping
  getMetrics(): string {
    return register.metrics();
  }

  // Clear all metrics (useful for testing)
  clearMetrics(): void {
    register.clear();
  }
}
```

#### Phase 3: Grafana Dashboards (Days 9-12)

5. **Grafana Setup and Configuration**
```yaml
# Continue docker-compose.monitoring.yml
  grafana:
    image: grafana/grafana:10.2.0
    container_name: jts-grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./infrastructure/monitoring/grafana/config/grafana.ini:/etc/grafana/grafana.ini
      - ./infrastructure/monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./infrastructure/monitoring/grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    depends_on:
      - prometheus
      - elasticsearch
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-monitoring-network
```

6. **Trading Operations Dashboard**
```json
{
  "dashboard": {
    "id": null,
    "title": "JTS Trading Operations",
    "description": "Real-time trading operations monitoring dashboard",
    "tags": ["trading", "operations", "real-time"],
    "timezone": "browser",
    "refresh": "5s",
    "time": {
      "from": "now-30m",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "Order Execution Latency",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "histogram_quantile(0.95, order_execution_duration_seconds_bucket)",
            "legendFormat": "95th percentile",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 0.1},
                {"color": "red", "value": 0.5}
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Active Orders by Strategy",
        "type": "piechart",
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
        "targets": [
          {
            "expr": "sum by (strategy_id) (order_execution_total)",
            "legendFormat": "{{strategy_id}}",
            "refId": "A"
          }
        ]
      },
      {
        "id": 3,
        "title": "Real-time P&L",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "sum(strategy_pnl_total)",
            "legendFormat": "Total P&L",
            "refId": "A"
          },
          {
            "expr": "sum by (strategy_name) (strategy_pnl_total)",
            "legendFormat": "{{strategy_name}}",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "currencyUSD",
            "color": {"mode": "continuous-GrYlRd"}
          }
        }
      },
      {
        "id": 4,
        "title": "Market Data Latency",
        "type": "heatmap",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "increase(market_data_latency_seconds_bucket[5m])",
            "legendFormat": "{{le}}",
            "refId": "A"
          }
        ]
      },
      {
        "id": 5,
        "title": "System Resource Usage",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %",
            "refId": "A"
          },
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "Memory Usage %",
            "refId": "B"
          }
        ]
      },
      {
        "id": 6,
        "title": "Order Success Rate",
        "type": "stat",
        "gridPos": {"h": 6, "w": 4, "x": 0, "y": 16},
        "targets": [
          {
            "expr": "(sum(order_execution_total{status=\"filled\"}) / sum(order_execution_total)) * 100",
            "legendFormat": "Success Rate %",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "steps": [
                {"color": "red", "value": null},
                {"color": "yellow", "value": 85},
                {"color": "green", "value": 95}
              ]
            }
          }
        }
      },
      {
        "id": 7,
        "title": "Risk Violations",
        "type": "table",
        "gridPos": {"h": 6, "w": 8, "x": 4, "y": 16},
        "targets": [
          {
            "expr": "sum by (strategy_id, rule_type) (increase(risk_violations_total[1h]))",
            "legendFormat": "",
            "refId": "A"
          }
        ]
      },
      {
        "id": 8,
        "title": "API Error Rate",
        "type": "timeseries",
        "gridPos": {"h": 6, "w": 12, "x": 12, "y": 16},
        "targets": [
          {
            "expr": "sum(rate(api_request_duration_seconds_count{status_code=~\"4..|5..\"}[5m])) / sum(rate(api_request_duration_seconds_count[5m])) * 100",
            "legendFormat": "Error Rate %",
            "refId": "A"
          }
        ],
        "alert": {
          "conditions": [
            {
              "evaluator": {"params": [5], "type": "gt"},
              "operator": {"type": "and"},
              "query": {"params": ["A", "5m", "now"]},
              "reducer": {"type": "avg"},
              "type": "query"
            }
          ],
          "executionErrorState": "alerting",
          "frequency": "10s",
          "handler": 1,
          "name": "High API Error Rate",
          "noDataState": "no_data",
          "notifications": []
        }
      }
    ]
  }
}
```

#### Phase 4: Distributed Tracing (Days 13-16)

7. **Jaeger Tracing Setup**
```yaml
# Continue docker-compose.monitoring.yml
  jaeger:
    image: jaegertracing/all-in-one:1.50
    container_name: jts-jaeger
    restart: unless-stopped
    ports:
      - "16686:16686"
      - "14268:14268"
      - "14250:14250"
      - "6831:6831/udp"
      - "6832:6832/udp"
    environment:
      - COLLECTOR_OTLP_ENABLED=true
      - SPAN_STORAGE_TYPE=elasticsearch
      - ES_SERVER_URLS=http://elasticsearch:9200
      - ES_USERNAME=jaeger
      - ES_PASSWORD=${JAEGER_PASSWORD}
      - ES_INDEX_PREFIX=jaeger
    depends_on:
      elasticsearch:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:16686/"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-monitoring-network
```

8. **Tracing Integration Service**
```typescript
// libs/shared/tracing/src/lib/tracing.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { trace, context, SpanStatusCode, SpanKind } from '@opentelemetry/api';
import { NodeTracerProvider } from '@opentelemetry/sdk-node';
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

@Injectable()
export class TracingService {
  private readonly logger = new Logger(TracingService.name);
  private tracer;

  constructor(private configService: ConfigService) {
    this.initializeTracing();
  }

  private initializeTracing(): void {
    const serviceName = this.configService.get<string>('SERVICE_NAME', 'jts-service');
    const jaegerEndpoint = this.configService.get<string>('JAEGER_ENDPOINT', 'http://localhost:14268/api/traces');

    const provider = new NodeTracerProvider({
      resource: new Resource({
        [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
        [SemanticResourceAttributes.SERVICE_VERSION]: this.configService.get<string>('SERVICE_VERSION', '1.0.0'),
        [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: this.configService.get<string>('NODE_ENV', 'development')
      })
    });

    const jaegerExporter = new JaegerExporter({
      endpoint: jaegerEndpoint
    });

    provider.addSpanProcessor(
      new BatchSpanProcessor(jaegerExporter, {
        maxQueueSize: 1000,
        scheduledDelayMillis: 5000,
        exportTimeoutMillis: 30000,
        maxExportBatchSize: 100
      })
    );

    provider.register();
    this.tracer = trace.getTracer(serviceName);

    this.logger.log(`Tracing initialized for service: ${serviceName}`);
  }

  // Create a new span with trading context
  createTradingSpan(
    operationName: string,
    parentContext?: any,
    attributes?: Record<string, any>
  ) {
    const span = this.tracer.startSpan(
      operationName,
      {
        kind: SpanKind.INTERNAL,
        parent: parentContext
      }
    );

    if (attributes) {
      Object.keys(attributes).forEach(key => {
        span.setAttribute(key, attributes[key]);
      });
    }

    return span;
  }

  // Trace order execution lifecycle
  async traceOrderExecution<T>(
    orderId: string,
    strategyId: string,
    symbol: string,
    operation: () => Promise<T>
  ): Promise<T> {
    const span = this.createTradingSpan('order.execution', undefined, {
      'trading.order_id': orderId,
      'trading.strategy_id': strategyId,
      'trading.symbol': symbol,
      'trading.operation': 'order_execution'
    });

    try {
      const startTime = Date.now();
      const result = await operation();
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      span.setAttributes({
        'trading.execution_time_ms': duration,
        'trading.execution_status': 'success'
      });
      
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error) {
      span.recordException(error);
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error.message
      });
      span.setAttribute('trading.execution_status', 'error');
      throw error;
    } finally {
      span.end();
    }
  }

  // Trace strategy execution
  async traceStrategyExecution<T>(
    strategyId: string,
    strategyName: string,
    operation: () => Promise<T>
  ): Promise<T> {
    const span = this.createTradingSpan('strategy.execution', undefined, {
      'trading.strategy_id': strategyId,
      'trading.strategy_name': strategyName,
      'trading.operation': 'strategy_execution'
    });

    return await this.executeWithSpan(span, operation);
  }

  // Trace market data processing
  async traceMarketDataProcessing<T>(
    symbol: string,
    exchange: string,
    dataType: string,
    operation: () => Promise<T>
  ): Promise<T> {
    const span = this.createTradingSpan('market_data.processing', undefined, {
      'trading.symbol': symbol,
      'trading.exchange': exchange,
      'trading.data_type': dataType,
      'trading.operation': 'market_data_processing'
    });

    return await this.executeWithSpan(span, operation);
  }

  // Trace broker API calls
  async traceBrokerApiCall<T>(
    broker: string,
    apiEndpoint: string,
    operation: () => Promise<T>
  ): Promise<T> {
    const span = this.createTradingSpan('broker.api_call', undefined, {
      'trading.broker': broker,
      'trading.api_endpoint': apiEndpoint,
      'trading.operation': 'broker_api_call'
    });

    return await this.executeWithSpan(span, operation);
  }

  private async executeWithSpan<T>(
    span: any,
    operation: () => Promise<T>
  ): Promise<T> {
    try {
      const startTime = Date.now();
      const result = await context.with(trace.setSpan(context.active(), span), operation);
      
      const endTime = Date.now();
      span.setAttribute('execution_time_ms', endTime - startTime);
      span.setStatus({ code: SpanStatusCode.OK });
      
      return result;
    } catch (error) {
      span.recordException(error);
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error.message
      });
      throw error;
    } finally {
      span.end();
    }
  }

  // Get current trace context
  getCurrentTraceContext() {
    return context.active();
  }

  // Extract trace context from headers (for HTTP requests)
  extractTraceContext(headers: Record<string, string>) {
    // Implementation depends on propagation format
    return context.active();
  }
}
```

#### Phase 5: Alerting and Notifications (Days 17-18)

9. **AlertManager Configuration**
```yaml
# infrastructure/monitoring/alertmanager/config/alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@jts-trading.com'
  slack_api_url: '${SLACK_WEBHOOK_URL}'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'default-receiver'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 10s
      repeat_interval: 10m
    
    - match:
        service: order-execution
      receiver: 'trading-team'
      group_wait: 15s
      repeat_interval: 30m
    
    - match:
        service: market-data-collector
      receiver: 'data-team'

receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'admin@jts-trading.com'
        subject: 'JTS Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Labels: {{ range .Labels.SortedPairs }}
            {{ .Name }}: {{ .Value }}
          {{ end }}
          {{ end }}

  - name: 'critical-alerts'
    email_configs:
      - to: 'critical@jts-trading.com'
        subject: 'CRITICAL JTS Alert: {{ .GroupLabels.alertname }}'
    slack_configs:
      - api_url: '${SLACK_WEBHOOK_URL}'
        channel: '#trading-critical'
        title: 'Critical JTS Trading Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}: {{ .Annotations.description }}{{ end }}'
        color: 'danger'

  - name: 'trading-team'
    slack_configs:
      - api_url: '${SLACK_WEBHOOK_URL}'
        channel: '#trading-ops'
        title: 'JTS Trading Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        color: 'warning'

  - name: 'data-team'
    email_configs:
      - to: 'data-team@jts-trading.com'
        subject: 'JTS Data Alert: {{ .GroupLabels.alertname }}'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']
```

10. **Prometheus Alert Rules**
```yaml
# infrastructure/monitoring/prometheus/rules/trading-alerts.yml
groups:
  - name: trading.rules
    rules:
      # Order execution alerts
      - alert: HighOrderExecutionLatency
        expr: histogram_quantile(0.95, order_execution_duration_seconds_bucket) > 0.5
        for: 2m
        labels:
          severity: warning
          service: order-execution
        annotations:
          summary: "High order execution latency detected"
          description: "95th percentile order execution latency is {{ $value }}s"

      - alert: OrderExecutionFailureRate
        expr: (sum(rate(order_execution_errors_total[5m])) / sum(rate(order_execution_total[5m]))) * 100 > 5
        for: 1m
        labels:
          severity: critical
          service: order-execution
        annotations:
          summary: "High order execution failure rate"
          description: "Order execution failure rate is {{ $value }}%"

      - alert: MarketDataLatency
        expr: histogram_quantile(0.95, market_data_latency_seconds_bucket) > 0.1
        for: 5m
        labels:
          severity: warning
          service: market-data-collector
        annotations:
          summary: "High market data latency"
          description: "95th percentile market data latency is {{ $value }}s"

      # Strategy performance alerts
      - alert: StrategyDrawdownAlert
        expr: strategy_drawdown_current > 10
        for: 10m
        labels:
          severity: warning
          service: strategy-engine
        annotations:
          summary: "Strategy experiencing high drawdown"
          description: "Strategy {{ $labels.strategy_name }} has {{ $value }}% drawdown"

      - alert: CriticalStrategyDrawdown
        expr: strategy_drawdown_current > 20
        for: 5m
        labels:
          severity: critical
          service: strategy-engine
        annotations:
          summary: "CRITICAL: Strategy experiencing excessive drawdown"
          description: "Strategy {{ $labels.strategy_name }} has {{ $value }}% drawdown - immediate attention required"

      # System health alerts
      - alert: HighCPUUsage
        expr: (100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is {{ $value }}% on {{ $labels.instance }}"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is {{ $value }}% on {{ $labels.instance }}"

      - alert: DatabaseConnectionPoolExhaustion
        expr: database_connection_pool_active / database_connection_pool_max > 0.9
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Database connection pool near exhaustion"
          description: "{{ $labels.database_type }} connection pool is {{ $value }}% full"

      # Business logic alerts
      - alert: RiskViolationSpike
        expr: increase(risk_violations_total[1h]) > 10
        for: 0m
        labels:
          severity: critical
          service: risk-management
        annotations:
          summary: "Risk violation spike detected"
          description: "{{ $value }} risk violations in the last hour for strategy {{ $labels.strategy_id }}"

      - alert: TotalPnlAlert
        expr: sum(strategy_pnl_total) < -10000
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Total portfolio P&L below threshold"
          description: "Total P&L is {{ $value }} USD"

      - alert: APIErrorRateHigh
        expr: (sum(rate(api_request_duration_seconds_count{status_code=~"4..|5.."}[5m])) / sum(rate(api_request_duration_seconds_count[5m]))) * 100 > 5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High API error rate"
          description: "API error rate is {{ $value }}%"
```

### Security and Compliance

**Log Security and Retention:**
```yaml
# Log retention and security policies
log_retention_policies:
  error_logs: 90d      # Critical for debugging
  trading_logs: 365d   # Required for regulatory compliance
  audit_logs: 2555d    # 7 years for financial regulations
  system_logs: 30d     # Infrastructure monitoring
  
security_configurations:
  elasticsearch:
    - enable_security: true
    - audit_logging: true
    - field_level_security: true
    - document_level_security: true
    
  grafana:
    - oauth_integration: true
    - role_based_access: true
    - dashboard_permissions: true
    
  prometheus:
    - basic_auth: true
    - tls_encryption: true
    - ip_whitelisting: true
```

**Compliance Monitoring:**
```typescript
// Compliance-specific logging and monitoring
export class ComplianceMonitoringService {
  // Track all trading decisions and executions
  logTradingDecision(decision: TradingDecision): void {
    this.auditLogger.info('Trading decision made', {
      correlationId: decision.correlationId,
      strategyId: decision.strategyId,
      symbol: decision.symbol,
      decision: decision.action,
      reasoning: decision.reasoning,
      riskAssessment: decision.riskAssessment,
      timestamp: new Date().toISOString(),
      userId: decision.userId,
      complianceChecked: decision.complianceChecked
    });
  }

  // Monitor for suspicious trading patterns
  detectAnomalousActivity(tradingActivity: TradingActivity[]): void {
    const anomalies = this.anomalyDetector.detect(tradingActivity);
    
    anomalies.forEach(anomaly => {
      this.securityLogger.warn('Anomalous trading activity detected', {
        anomalyType: anomaly.type,
        severity: anomaly.severity,
        affectedAccounts: anomaly.accounts,
        timeWindow: anomaly.timeWindow,
        description: anomaly.description
      });
      
      // Trigger compliance review if needed
      if (anomaly.severity === 'high') {
        this.triggerComplianceReview(anomaly);
      }
    });
  }
}
```

## Dependencies

- **1003**: Monorepo Structure - Required for shared libraries and configuration management
- **1005**: Database Infrastructure - Required for log and metric storage integration

## Testing Plan

### Infrastructure Testing
- **Deployment Testing**: Verify all monitoring services deploy correctly with Docker Compose
- **Integration Testing**: Test data flow from applications to ELK stack and Prometheus
- **Dashboard Testing**: Validate all Grafana dashboards display correct data
- **Alert Testing**: Test alert rules trigger correctly and notifications are sent

### Performance Testing
- **Log Ingestion Testing**: Test high-volume log ingestion under trading load
- **Metric Collection Testing**: Validate metric collection doesn't impact application performance  
- **Query Performance**: Test dashboard queries perform well with large datasets
- **Storage Performance**: Test log and metric storage under sustained load

### Reliability Testing
- **Failover Testing**: Test monitoring system resilience when components fail
- **Data Retention Testing**: Verify log and metric retention policies work correctly
- **Backup Testing**: Test monitoring data backup and recovery procedures
- **Security Testing**: Validate access controls and authentication mechanisms

### Compliance Testing
- **Audit Trail Testing**: Verify all trading activities are properly logged
- **Retention Policy Testing**: Test compliance with regulatory data retention requirements
- **Access Control Testing**: Verify role-based access to sensitive monitoring data
- **Data Integrity Testing**: Test log and metric data cannot be tampered with

## Claude Code Instructions

```
When implementing this feature:
1. Deploy ELK stack with docker-compose.monitoring.yml including all security configurations
2. Configure Logstash pipelines for structured log processing with trading context enrichment
3. Set up Prometheus with custom trading metrics and proper retention policies
4. Create comprehensive Grafana dashboards for trading operations, system health, and business KPIs
5. Implement Jaeger distributed tracing with trading-specific span attributes
6. Configure AlertManager with multi-channel notifications and intelligent alert routing
7. Create shared logging and metrics libraries for consistent instrumentation across services
8. Set up automated log and metric retention policies with compliance considerations
9. Implement security controls including authentication, authorization, and audit logging
10. Create monitoring health checks and self-monitoring for the monitoring infrastructure
11. Test all alert rules and notification channels with realistic trading scenarios
12. Document monitoring best practices and troubleshooting procedures for the development team
```

## Notes

- All monitoring components must be highly available to avoid blind spots during critical trading periods
- Log correlation IDs are essential for tracing requests across the distributed trading system
- Custom trading metrics should align with business KPIs and regulatory reporting requirements
- Alert thresholds must be carefully calibrated to avoid alert fatigue while catching real issues
- Monitoring data retention must comply with financial industry regulatory requirements
- Consider implementing monitoring of the monitoring infrastructure itself (meta-monitoring)
- All sensitive data in logs must be properly masked or encrypted for compliance
- Performance impact of monitoring instrumentation should be continuously assessed

## Status Updates

- **2025-08-24**: Feature specification created with comprehensive monitoring and logging architecture design