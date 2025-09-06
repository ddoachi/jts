# ========================================================================================================
# JTS Trading System - Order Execution Service Dockerfile
# ========================================================================================================
# The Order Execution Service is the critical component responsible for executing trades with external
# brokers and exchanges. It handles order routing, execution management, fill reporting, and maintains
# connections with multiple broker APIs including Creon, KIS, Upbit, and Binance.
#
# SERVICE RESPONSIBILITIES:
# - Order routing to appropriate brokers based on asset type and market
# - Real-time order execution and fill management
# - Broker API integration and connection management
# - Order state tracking and lifecycle management
# - Execution reporting and trade confirmation
# - Slippage monitoring and execution quality analysis
# - Circuit breaker implementation for broker API rate limits
#
# RELIABILITY REQUIREMENTS:
# - Zero message loss for orders and executions
# - Fault tolerance with automatic retry mechanisms
# - Graceful degradation when broker connections fail
# - Transaction logging for regulatory compliance
# ========================================================================================================

# Inherit from the multi-stage base image with security hardening
FROM ../../docker/base:production

# Service-specific metadata and labels
LABEL service="order-execution" \
      tier="core" \
      exposure="internal" \
      security.level="critical" \
      scaling.type="horizontal" \
      financial.data="yes" \
      compliance.required="yes"

# ========================================================================================================
# ORDER EXECUTION ENVIRONMENT CONFIGURATION
# ========================================================================================================

# Order Execution specific environment variables
ENV SERVICE_NAME=order-execution \
    SERVICE_PORT=3002 \
    # Broker connection settings
    CREON_API_ENDPOINT=http://creon-gateway:8080 \
    KIS_API_ENDPOINT=https://openapi.koreainvestment.com \
    UPBIT_API_ENDPOINT=https://api.upbit.com \
    BINANCE_API_ENDPOINT=https://api.binance.com \
    # Order management configuration
    MAX_ORDER_RETRY_ATTEMPTS=3 \
    ORDER_TIMEOUT_MS=30000 \
    EXECUTION_REPORT_TIMEOUT=5000 \
    ORDER_QUEUE_SIZE=10000 \
    # Rate limiting for broker APIs
    CREON_RATE_LIMIT_PER_SEC=20 \
    CREON_RATE_LIMIT_PER_MIN=200 \
    KIS_RATE_LIMIT_PER_SEC=10 \
    UPBIT_RATE_LIMIT_PER_SEC=30 \
    BINANCE_RATE_LIMIT_PER_SEC=50 \
    # Circuit breaker settings
    CIRCUIT_BREAKER_FAILURE_THRESHOLD=5 \
    CIRCUIT_BREAKER_TIMEOUT=60000 \
    CIRCUIT_BREAKER_RESET_TIMEOUT=300000 \
    # Database connections
    ORDER_DB_URL=postgresql://postgres:5432/orders \
    EXECUTION_LOG_DB_URL=clickhouse://clickhouse:8123/executions \
    # Security settings for broker API keys
    BROKER_CREDENTIALS_PATH=/run/secrets/broker_credentials \
    # Performance tuning for high-frequency execution
    NODE_OPTIONS="--max-old-space-size=4096 --max-http-header-size=32768"

# ========================================================================================================
# ORDER EXECUTION SPECIALIZED SETUP
# ========================================================================================================

# Create order execution specific directories and files
USER root
RUN mkdir -p /app/orders/pending /app/orders/executed /app/orders/failed \
             /app/logs/executions /app/cache/broker-state /app/compliance && \
    chown -R 65532:65532 /app/orders /app/logs/executions /app/cache/broker-state /app/compliance && \
    chmod 750 /app/orders && \
    chmod 700 /app/orders/pending /app/orders/executed /app/orders/failed && \
    chmod 755 /app/logs/executions && \
    chmod 700 /app/cache/broker-state && \
    chmod 750 /app/compliance

# Switch back to non-root user
USER 65532:65532

# ========================================================================================================
# ORDER EXECUTION NETWORKING
# ========================================================================================================

# Expose the order execution API port
EXPOSE 3002

# Specialized health check for order execution service
# Verifies broker connections and order processing capability
HEALTHCHECK --interval=10s --timeout=8s --start-period=60s --retries=5 \
    CMD ["/nodejs/bin/node", "-e", "\
        const http = require('http'); \
        const options = { \
            hostname: 'localhost', \
            port: 3002, \
            path: '/health', \
            method: 'GET', \
            timeout: 6000 \
        }; \
        const req = http.request(options, (res) => { \
            let data = ''; \
            res.on('data', chunk => data += chunk); \
            res.on('end', () => { \
                if (res.statusCode === 200) { \
                    try { \
                        const health = JSON.parse(data); \
                        const requiredBrokers = ['creon', 'kis', 'upbit', 'binance']; \
                        const connectedBrokers = health.broker_connections || {}; \
                        const allConnected = requiredBrokers.some(broker => \
                            connectedBrokers[broker] === 'connected' \
                        ); \
                        if (allConnected && health.order_queue_healthy) { \
                            process.exit(0); \
                        } else { \
                            console.error('Broker connections or order queue unhealthy'); \
                            process.exit(1); \
                        } \
                    } catch (e) { \
                        console.error('Invalid health check response:', e.message); \
                        process.exit(1); \
                    } \
                } else { \
                    console.error('Health check failed with status:', res.statusCode); \
                    process.exit(1); \
                } \
            }); \
        }); \
        req.on('error', (err) => { \
            console.error('Health check request failed:', err.message); \
            process.exit(1); \
        }); \
        req.on('timeout', () => { \
            console.error('Health check timed out'); \
            req.destroy(); \
            process.exit(1); \
        }); \
        req.setTimeout(6000); \
        req.end(); \
    "]

# ========================================================================================================
# STARTUP COMMAND
# ========================================================================================================

# Start the Order Execution service with high reliability settings
CMD ["dist/apps/order-execution/main.js"]

# ========================================================================================================
# DEPLOYMENT NOTES FOR ORDER EXECUTION SERVICE
# ========================================================================================================
#
# CRITICAL DEPLOYMENT CONSIDERATIONS:
# - This service handles real money transactions - deploy with extreme caution
# - Always test with paper trading accounts before live deployment
# - Implement proper order validation to prevent erroneous trades
# - Ensure database transactions are ACID compliant for order persistence
#
# SECURITY REQUIREMENTS:
# - Broker API credentials must be stored in secure secrets management
# - All order data must be encrypted at rest and in transit
# - Implement comprehensive audit logging for regulatory compliance
# - Use network segmentation to isolate from public networks
# - Regular security audits and penetration testing required
#
# SCALING AND RELIABILITY:
# - Deploy in active-passive configuration for high availability
# - Use database replication for order state persistence
# - Implement message queuing (Kafka) for reliable order processing
# - Monitor broker API health and implement automatic failover
#
# MONITORING AND ALERTING:
# - Real-time monitoring of order execution latency (< 500ms target)
# - Alert on order failures, rejections, or timeout conditions
# - Monitor broker API rate limits and circuit breaker states
# - Track slippage and execution quality metrics
# - Set up compliance monitoring for regulatory requirements
#
# BROKER-SPECIFIC CONSIDERATIONS:
# - Creon (Korean markets): Windows COM interface, requires special handling
# - KIS: REST API with OAuth, rate limited, market hours restrictions
# - Upbit: Cryptocurrency exchange, 24/7 operation, high frequency capable
# - Binance: Global crypto exchange, complex order types, margin trading
#
# DISASTER RECOVERY:
# - Regular backups of order state and execution history
# - Documented recovery procedures for each broker integration
# - Test failover scenarios regularly
# - Maintain emergency procedures for market closure or system failure
#
# COMPLIANCE AND AUDITING:
# - All trades must be logged with timestamps and audit trails
# - Implement Best Execution reporting for regulatory compliance
# - Regular reconciliation with broker statements
# - Maintain records for regulatory reporting requirements
# ========================================================================================================