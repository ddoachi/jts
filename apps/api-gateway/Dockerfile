# ========================================================================================================
# JTS Trading System - API Gateway Service Dockerfile
# ========================================================================================================
# The API Gateway serves as the unified entry point for all client requests, providing authentication,
# rate limiting, request routing, and API versioning. It acts as a reverse proxy that distributes
# incoming requests to appropriate microservices while handling cross-cutting concerns.
#
# SERVICE RESPONSIBILITIES:
# - Request routing and load balancing to backend services
# - Authentication and authorization (JWT validation, API keys)
# - Rate limiting and traffic throttling to prevent abuse
# - Request/response transformation and API versioning
# - SSL termination and security headers injection
# - Logging, monitoring, and metrics collection for all API calls
# - CORS handling for web clients
#
# SECURITY CONSIDERATIONS:
# - Exposed to external network, requires maximum security hardening
# - Handles sensitive authentication tokens and user credentials
# - Must implement comprehensive input validation and sanitization
# - Requires DDoS protection and security monitoring
# ========================================================================================================

# Inherit from the multi-stage base image with security hardening
FROM ../../docker/base:production

# Service-specific metadata and labels
LABEL service="api-gateway" \
      tier="frontend" \
      exposure="public" \
      security.level="critical" \
      scaling.type="horizontal" \
      load-balancer.compatible="yes"

# ========================================================================================================
# API GATEWAY ENVIRONMENT CONFIGURATION
# ========================================================================================================

# API Gateway specific environment variables
ENV SERVICE_NAME=api-gateway \
    SERVICE_PORT=3000 \
    # Gateway configuration
    GATEWAY_TIMEOUT=30000 \
    RATE_LIMIT_WINDOW=60000 \
    RATE_LIMIT_MAX_REQUESTS=1000 \
    # Upstream service endpoints (will be overridden by orchestrator)
    STRATEGY_SERVICE_URL=http://strategy-engine:3001 \
    ORDER_SERVICE_URL=http://order-execution:3002 \
    RISK_SERVICE_URL=http://risk-management:3003 \
    DATA_SERVICE_URL=http://data-ingestion:3004 \
    NOTIFICATION_SERVICE_URL=http://notification-service:3005 \
    # Security settings
    JWT_SECRET_FILE=/run/secrets/jwt_secret \
    API_KEY_HEADER=X-API-Key \
    CORS_ORIGINS="https://app.jts.com,https://admin.jts.com" \
    # Performance tuning for high-throughput gateway
    NODE_OPTIONS="--max-old-space-size=2048 --max-http-header-size=16384"

# ========================================================================================================
# GATEWAY-SPECIFIC NETWORKING
# ========================================================================================================

# Expose the main API port
# Note: This is the public-facing port that receives all external traffic
EXPOSE 3000

# Health check endpoint for load balancer integration
# The gateway health check verifies connectivity to all downstream services
HEALTHCHECK --interval=15s --timeout=10s --start-period=60s --retries=3 \
    CMD ["/nodejs/bin/node", "-e", "\
        const http = require('http'); \
        const options = { \
            hostname: 'localhost', \
            port: 3000, \
            path: '/health', \
            method: 'GET', \
            timeout: 5000 \
        }; \
        const req = http.request(options, (res) => { \
            if (res.statusCode === 200) { \
                process.exit(0); \
            } else { \
                console.error('Health check failed with status:', res.statusCode); \
                process.exit(1); \
            } \
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
        req.setTimeout(5000); \
        req.end(); \
    "]

# ========================================================================================================
# API GATEWAY RUNTIME CONFIGURATION
# ========================================================================================================

# Create gateway-specific directories for caching and temporary files
USER root
RUN mkdir -p /app/cache/routes /app/cache/auth /app/logs/access && \
    chown -R 65532:65532 /app/cache /app/logs && \
    chmod 755 /app/cache/routes /app/cache/auth && \
    chmod 644 /app/logs/access

# Switch back to non-root user for runtime
USER 65532:65532

# ========================================================================================================
# STARTUP COMMAND
# ========================================================================================================

# Start the API Gateway service
# The gateway requires special startup parameters for handling high concurrency
CMD ["dist/apps/api-gateway/main.js"]

# ========================================================================================================
# DEPLOYMENT NOTES FOR API GATEWAY
# ========================================================================================================
#
# LOAD BALANCING:
# - Deploy multiple instances behind a load balancer (nginx, HAProxy, or cloud LB)
# - Use sticky sessions if maintaining client state
# - Configure health checks on /health endpoint
#
# SCALING RECOMMENDATIONS:
# - Horizontal scaling: 2-4 instances per CPU core
# - Memory: 2-4GB per instance depending on traffic
# - CPU: Gateway is I/O intensive, optimize for network throughput
#
# SECURITY DEPLOYMENT:
# - Always deploy behind WAF (Web Application Firewall)
# - Use TLS 1.3 with strong cipher suites
# - Implement proper CORS policies
# - Configure rate limiting based on client IP and API key
#
# MONITORING:
# - Monitor response times to all downstream services
# - Track rate limiting metrics and blocked requests
# - Alert on authentication failures and suspicious patterns
# - Log all requests for audit and security analysis
#
# ENVIRONMENT VARIABLES FOR PRODUCTION:
# - JWT_SECRET_FILE: Path to JWT signing secret (use Docker secrets)
# - DATABASE_URL: Connection string for session/cache storage
# - REDIS_URL: Redis connection for distributed rate limiting
# - LOG_LEVEL: Set to 'info' or 'warn' in production
# ========================================================================================================