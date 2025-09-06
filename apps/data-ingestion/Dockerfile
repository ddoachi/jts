# ========================================================================================================
# JTS Trading System - Data Ingestion Service Dockerfile
# ========================================================================================================
# The Data Ingestion Service is the data backbone of the trading system, responsible for collecting,
# processing, and distributing real-time and historical market data from multiple sources. It handles
# high-throughput data streams, performs data normalization, and ensures data quality and consistency.
#
# SERVICE RESPONSIBILITIES:
# - Real-time market data ingestion from multiple exchanges and data providers
# - WebSocket and REST API data stream management
# - Data normalization, validation, and quality assurance
# - High-frequency tick data processing and aggregation
# - Historical data backfilling and maintenance
# - Data distribution to downstream services via Kafka
# - Rate limiting and connection management for data providers
# - Data backup and disaster recovery procedures
#
# PERFORMANCE REQUIREMENTS:
# - Handle thousands of messages per second with low latency
# - Memory-efficient processing of large data volumes
# - Network I/O intensive with multiple concurrent connections
# - Fault-tolerant data processing with zero data loss
# ========================================================================================================

# Inherit from the multi-stage base image with security hardening
FROM ../../docker/base:production

# Service-specific metadata and labels
LABEL service="data-ingestion" \
      tier="infrastructure" \
      exposure="internal" \
      security.level="medium" \
      scaling.type="horizontal" \
      data.throughput="high" \
      network.intensive="yes"

# ========================================================================================================
# DATA INGESTION ENVIRONMENT CONFIGURATION
# ========================================================================================================

# Data Ingestion specific environment variables
ENV SERVICE_NAME=data-ingestion \
    SERVICE_PORT=3004 \
    # Data source configurations
    UPBIT_WEBSOCKET_URL=wss://api.upbit.com/websocket/v1 \
    BINANCE_WEBSOCKET_URL=wss://stream.binance.com:9443/ws \
    KIS_API_URL=https://openapi.koreainvestment.com \
    CREON_DATA_URL=http://creon-gateway:8080/market-data \
    YAHOO_FINANCE_URL=https://query1.finance.yahoo.com/v8/finance/chart \
    # Data processing configuration
    MAX_CONCURRENT_CONNECTIONS=100 \
    WEBSOCKET_RECONNECT_INTERVAL=5000 \
    DATA_VALIDATION_ENABLED=true \
    DATA_COMPRESSION_ENABLED=true \
    TICK_DATA_BUFFER_SIZE=50000 \
    CANDLE_AGGREGATION_INTERVALS="1m,5m,15m,1h,4h,1d" \
    # Kafka producer settings for data distribution
    KAFKA_BROKERS=kafka:9092 \
    KAFKA_TOPIC_RAW_DATA=market.raw \
    KAFKA_TOPIC_PROCESSED_DATA=market.processed \
    KAFKA_TOPIC_CANDLES=market.candles \
    KAFKA_BATCH_SIZE=16384 \
    KAFKA_LINGER_MS=100 \
    KAFKA_COMPRESSION_TYPE=snappy \
    # Database connections for data persistence
    CLICKHOUSE_URL=clickhouse://clickhouse:8123/market_data \
    REDIS_URL=redis://redis:6379 \
    # Performance tuning for high-throughput data processing
    NODE_OPTIONS="--max-old-space-size=4096 --max-http-sockets=1000" \
    # Data quality and monitoring
    DATA_QUALITY_CHECK_INTERVAL=60000 \
    MISSING_DATA_ALERT_THRESHOLD=10 \
    LATENCY_ALERT_THRESHOLD_MS=1000

# ========================================================================================================
# DATA INGESTION SPECIALIZED SETUP
# ========================================================================================================

# Install data processing and networking tools
USER root
RUN apk add --no-cache --virtual .ingestion-deps \
        # Network monitoring and debugging tools
        tcpdump=4.99.4-r0 \
        netcat-openbsd=1.226-r0 \
        bind-tools=9.18.31-r0 \
        # Data processing utilities
        jq=1.7.1-r0 \
        gzip=1.13-r0 \
        # Time synchronization (critical for financial data)
        chrony=4.5-r0

# Create data ingestion specific directories
RUN mkdir -p /app/data/raw /app/data/processed /app/data/failed \
             /app/data/backup /app/cache/symbols /app/logs/ingestion && \
    chown -R 65532:65532 /app/data /app/cache/symbols /app/logs/ingestion && \
    chmod 755 /app/data/raw /app/data/processed && \
    chmod 700 /app/data/failed /app/data/backup && \
    chmod 644 /app/cache/symbols && \
    chmod 755 /app/logs/ingestion

# Configure time synchronization for accurate timestamps
RUN echo "server time.nist.gov iburst" >> /etc/chrony/chrony.conf && \
    echo "server pool.ntp.org iburst" >> /etc/chrony/chrony.conf

# Switch back to non-root user
USER 65532:65532

# ========================================================================================================
# DATA INGESTION NETWORKING
# ========================================================================================================

# Expose the data ingestion API port
EXPOSE 3004

# Specialized health check for data ingestion service
# Verifies data source connections and processing pipeline health
HEALTHCHECK --interval=15s --timeout=12s --start-period=60s --retries=3 \
    CMD ["/nodejs/bin/node", "-e", "\
        const http = require('http'); \
        const options = { \
            hostname: 'localhost', \
            port: 3004, \
            path: '/health', \
            method: 'GET', \
            timeout: 10000 \
        }; \
        const req = http.request(options, (res) => { \
            let data = ''; \
            res.on('data', chunk => data += chunk); \
            res.on('end', () => { \
                if (res.statusCode === 200) { \
                    try { \
                        const health = JSON.parse(data); \
                        const requiredSources = ['upbit', 'binance', 'kis']; \
                        const connectedSources = health.data_sources || {}; \
                        const minConnected = requiredSources.filter(source => \
                            connectedSources[source] === 'connected' \
                        ).length >= 2; \
                        if (minConnected && health.kafka_connected && health.processing_pipeline_healthy) { \
                            process.exit(0); \
                        } else { \
                            console.error('Data sources or processing pipeline unhealthy'); \
                            process.exit(1); \
                        } \
                    } catch (e) { \
                        console.error('Invalid health check response:', e.message); \
                        process.exit(1); \
                    } \
                } else { \
                    console.error('Data ingestion health check failed:', res.statusCode); \
                    process.exit(1); \
                } \
            }); \
        }); \
        req.on('error', (err) => { \
            console.error('Data ingestion health check error:', err.message); \
            process.exit(1); \
        }); \
        req.on('timeout', () => { \
            console.error('Data ingestion health check timed out'); \
            req.destroy(); \
            process.exit(1); \
        }); \
        req.setTimeout(10000); \
        req.end(); \
    "]

# ========================================================================================================
# STARTUP COMMAND
# ========================================================================================================

# Start the Data Ingestion service with high-performance networking
CMD ["dist/apps/data-ingestion/main.js"]

# ========================================================================================================
# DEPLOYMENT NOTES FOR DATA INGESTION SERVICE
# ========================================================================================================
#
# SCALABILITY AND PERFORMANCE:
# - Horizontal scaling preferred for handling multiple data sources
# - Deploy multiple instances with load balancing by data source
# - Use container orchestration for automatic scaling based on data volume
# - Optimize network settings for high-throughput data ingestion
#
# RESOURCE REQUIREMENTS:
# - CPU: 2-4 cores per instance, optimized for I/O operations
# - RAM: 4-8GB depending on buffer sizes and number of connections
# - Network: High bandwidth and low latency connections required
# - Storage: Fast SSD for temporary data buffering and caching
#
# DATA SOURCE MANAGEMENT:
# - Implement connection pooling for REST API data sources
# - Use WebSocket connection multiplexing where possible
# - Implement exponential backoff for reconnection attempts
# - Monitor data source rate limits and implement throttling
#
# RELIABILITY AND FAULT TOLERANCE:
# - Implement circuit breakers for unstable data sources
# - Use dead letter queues for failed message processing
# - Implement data source failover and redundancy
# - Regular health checks for all data source connections
#
# DATA QUALITY ASSURANCE:
# - Implement real-time data validation and anomaly detection
# - Monitor data latency and missing data points
# - Compare data across multiple sources for consistency
# - Implement automated data quality reporting
#
# MONITORING AND ALERTING:
# - Monitor data ingestion rates and processing latency
# - Alert on data source connection failures
# - Track data quality metrics and anomalies
# - Monitor Kafka producer performance and lag
# - Dashboard for real-time data ingestion status
#
# SECURITY CONSIDERATIONS:
# - Secure API keys and credentials for data providers
# - Implement rate limiting to prevent API quota exhaustion
# - Monitor for suspicious data patterns or potential attacks
# - Encrypt sensitive market data in transit and at rest
#
# DATA GOVERNANCE:
# - Implement data lineage tracking for audit purposes
# - Maintain data retention policies for historical data
# - Ensure compliance with data provider terms of service
# - Implement data privacy controls where applicable
#
# DISASTER RECOVERY:
# - Regular backups of critical configuration and symbol data
# - Implement data replay capabilities for system recovery
# - Document procedures for data source failover
# - Test data recovery scenarios regularly
#
# OPTIMIZATION STRATEGIES:
# - Use connection pooling and keep-alive for HTTP connections
# - Implement efficient data serialization and compression
# - Use memory-efficient data structures for high-frequency data
# - Optimize Kafka producer settings for throughput vs. latency
# - Implement data deduplication to reduce storage costs
# ========================================================================================================