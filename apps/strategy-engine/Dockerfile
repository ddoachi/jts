# ========================================================================================================
# JTS Trading System - Strategy Engine Service Dockerfile
# ========================================================================================================
# The Strategy Engine is the algorithmic brain of the trading system, responsible for analyzing market
# data, executing trading strategies, and making buy/sell decisions. It processes real-time market data
# streams and generates trading signals based on predefined algorithms and machine learning models.
#
# SERVICE RESPONSIBILITIES:
# - Real-time market data analysis and technical indicator calculations
# - Strategy execution and algorithmic decision making
# - Risk-adjusted position sizing and portfolio optimization
# - Backtesting and strategy performance evaluation
# - Machine learning model inference for predictive analytics
# - Signal generation and order recommendations
#
# PERFORMANCE REQUIREMENTS:
# - Sub-millisecond latency for high-frequency strategies
# - High CPU utilization for complex mathematical computations
# - Memory-intensive operations for large datasets and model inference
# - Real-time streaming data processing capabilities
# ========================================================================================================

# Inherit from the multi-stage base image with security hardening
FROM ../../docker/base:production

# Service-specific metadata and labels
LABEL service="strategy-engine" \
      tier="core" \
      exposure="internal" \
      security.level="high" \
      scaling.type="vertical" \
      compute.intensive="yes" \
      data.sensitivity="high"

# ========================================================================================================
# STRATEGY ENGINE ENVIRONMENT CONFIGURATION
# ========================================================================================================

# Strategy Engine specific environment variables
ENV SERVICE_NAME=strategy-engine \
    SERVICE_PORT=3001 \
    # Performance tuning for compute-intensive operations
    NODE_OPTIONS="--max-old-space-size=8192 --optimize-for-size --gc-interval=100" \
    # Strategy execution settings
    STRATEGY_EXECUTION_INTERVAL=1000 \
    MAX_CONCURRENT_STRATEGIES=50 \
    BACKTEST_MEMORY_LIMIT=4096 \
    # Market data configuration
    MARKET_DATA_BUFFER_SIZE=10000 \
    TECHNICAL_INDICATOR_CACHE_SIZE=5000 \
    # Machine learning model settings
    ML_MODEL_PATH=/app/models \
    TENSORFLOW_SERVING_URL=http://ml-serving:8501 \
    MODEL_INFERENCE_TIMEOUT=500 \
    # Database connections for strategy data
    TIMESERIES_DB_URL=clickhouse://clickhouse:8123/market_data \
    STRATEGY_CONFIG_DB_URL=mongodb://mongodb:27017/strategies \
    # Performance monitoring
    METRICS_COLLECTION_INTERVAL=10000

# ========================================================================================================
# STRATEGY ENGINE PERFORMANCE OPTIMIZATION
# ========================================================================================================

# Install additional tools for mathematical computations and data processing
USER root
RUN apk add --no-cache --virtual .strategy-deps \
        # Mathematical libraries for strategy calculations
        lapack=3.12.0-r0 \
        blas=3.12.0-r0 \
        # Data processing utilities
        jq=1.7.1-r0 \
        # Memory profiling tools for development
        valgrind=3.23.0-r0

# Create strategy-specific directories
RUN mkdir -p /app/models /app/strategies /app/backtests /app/cache/indicators && \
    chown -R 65532:65532 /app/models /app/strategies /app/backtests /app/cache && \
    chmod 755 /app/models /app/strategies /app/backtests && \
    chmod 700 /app/cache/indicators

# Switch back to non-root user
USER 65532:65532

# ========================================================================================================
# STRATEGY ENGINE NETWORKING
# ========================================================================================================

# Expose the strategy engine API port
EXPOSE 3001

# Strategy Engine health check with performance metrics validation
HEALTHCHECK --interval=20s --timeout=15s --start-period=90s --retries=3 \
    CMD ["/nodejs/bin/node", "-e", "\
        const http = require('http'); \
        const options = { \
            hostname: 'localhost', \
            port: 3001, \
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
                        if (health.strategies_loaded && health.models_ready) { \
                            process.exit(0); \
                        } else { \
                            console.error('Strategy engine not fully initialized'); \
                            process.exit(1); \
                        } \
                    } catch (e) { \
                        console.error('Invalid health check response'); \
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
        req.setTimeout(10000); \
        req.end(); \
    "]

# ========================================================================================================
# STARTUP COMMAND
# ========================================================================================================

# Start the Strategy Engine service with optimized Node.js flags for mathematical computations
CMD ["dist/apps/strategy-engine/main.js"]

# ========================================================================================================
# DEPLOYMENT NOTES FOR STRATEGY ENGINE
# ========================================================================================================
#
# RESOURCE REQUIREMENTS:
# - CPU: Minimum 4 cores, recommended 8+ cores for complex strategies
# - RAM: 8-16GB depending on number of active strategies and historical data
# - Storage: SSD required for fast model loading and data access
#
# SCALING STRATEGY:
# - Vertical scaling preferred due to shared state and memory requirements
# - If horizontal scaling needed, partition strategies by asset class or timeframe
# - Use sticky routing for stateful strategy instances
#
# DATA DEPENDENCIES:
# - Requires real-time market data feed from data-ingestion service
# - Needs access to historical data in ClickHouse for backtesting
# - MongoDB for strategy configurations and parameters
# - ML model artifacts mounted as volumes or downloaded at startup
#
# MONITORING AND ALERTING:
# - Monitor strategy execution latency (should be < 100ms)
# - Alert on strategy failures or unexpected PnL deviations
# - Track memory usage for memory leaks in long-running strategies
# - Monitor model inference performance and accuracy
#
# SECURITY CONSIDERATIONS:
# - Strategy algorithms are proprietary intellectual property
# - Encrypt strategy configuration data at rest
# - Implement audit logging for all strategy modifications
# - Secure model artifacts and prevent unauthorized access
#
# DEVELOPMENT AND TESTING:
# - Use separate environments for strategy development and backtesting
# - Implement comprehensive unit tests for all strategies
# - Paper trading mode for strategy validation before live deployment
# - Version control for strategy code and model artifacts
# ========================================================================================================