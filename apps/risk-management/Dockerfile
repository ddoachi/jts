# ========================================================================================================
# JTS Trading System - Risk Management Service Dockerfile
# ========================================================================================================
# The Risk Management Service is the guardian of the trading system, responsible for monitoring positions,
# calculating risk metrics, and enforcing risk limits to prevent catastrophic losses. It operates as a
# real-time risk engine that can halt trading activities when risk thresholds are breached.
#
# SERVICE RESPONSIBILITIES:
# - Real-time position monitoring and risk calculation
# - Portfolio-level and individual position risk assessment
# - VaR (Value at Risk) and stress testing calculations
# - Risk limit enforcement and position sizing controls
# - Drawdown monitoring and automatic trading halts
# - Margin requirement calculations and monitoring
# - Regulatory compliance for risk reporting
# - Emergency risk controls and circuit breakers
#
# CRITICAL IMPORTANCE:
# - Acts as the last line of defense against catastrophic losses
# - Must remain operational even when other services fail
# - Requires redundancy and fail-safe mechanisms
# - Performance is secondary to accuracy and reliability
# ========================================================================================================

# Inherit from the multi-stage base image with security hardening
FROM ../../docker/base:production

# Service-specific metadata and labels
LABEL service="risk-management" \
      tier="core" \
      exposure="internal" \
      security.level="critical" \
      scaling.type="vertical" \
      mission.critical="yes" \
      compliance.required="yes" \
      failsafe.required="yes"

# ========================================================================================================
# RISK MANAGEMENT ENVIRONMENT CONFIGURATION
# ========================================================================================================

# Risk Management specific environment variables
ENV SERVICE_NAME=risk-management \
    SERVICE_PORT=3003 \
    # Risk calculation parameters
    VAR_CONFIDENCE_LEVEL=0.95 \
    VAR_TIME_HORIZON_DAYS=1 \
    HISTORICAL_DATA_LOOKBACK_DAYS=252 \
    STRESS_TEST_SCENARIOS=10 \
    CORRELATION_CALCULATION_WINDOW=60 \
    # Risk limits and thresholds
    MAX_PORTFOLIO_VAR_PERCENT=2.0 \
    MAX_POSITION_SIZE_PERCENT=10.0 \
    MAX_DRAWDOWN_PERCENT=5.0 \
    MAX_LEVERAGE_RATIO=3.0 \
    MIN_LIQUIDITY_BUFFER_PERCENT=10.0 \
    # Emergency controls
    CIRCUIT_BREAKER_LOSS_THRESHOLD=1000000 \
    EMERGENCY_HALT_ENABLED=true \
    RISK_OVERRIDE_REQUIRES_APPROVAL=true \
    # Monitoring and alerting
    RISK_CALCULATION_INTERVAL=5000 \
    POSITION_MONITORING_INTERVAL=1000 \
    ALERT_NOTIFICATION_TIMEOUT=30000 \
    # Database connections for risk data
    POSITIONS_DB_URL=postgresql://postgres:5432/positions \
    RISK_METRICS_DB_URL=clickhouse://clickhouse:8123/risk_metrics \
    COMPLIANCE_DB_URL=postgresql://postgres:5432/compliance \
    # Performance tuning for complex risk calculations
    NODE_OPTIONS="--max-old-space-size=6144 --optimize-for-size" \
    # Mathematical libraries configuration
    BLAS_NUM_THREADS=4 \
    LAPACK_NUM_THREADS=4

# ========================================================================================================
# RISK MANAGEMENT SPECIALIZED SETUP
# ========================================================================================================

# Install additional mathematical and statistical libraries
USER root
RUN apk add --no-cache --virtual .risk-deps \
        # Advanced mathematical libraries
        lapack=3.12.0-r0 \
        blas=3.12.0-r0 \
        gsl=2.8-r0 \
        # Statistical computing tools
        R=4.4.1-r0 \
        py3-numpy=1.26.4-r0 \
        py3-scipy=1.13.1-r0 \
        # Risk management specific tools
        py3-pandas=2.2.2-r0 \
        py3-matplotlib=3.8.4-r0

# Create risk management specific directories
RUN mkdir -p /app/risk/calculations /app/risk/limits /app/risk/reports \
             /app/risk/emergency /app/compliance/reports /app/models/risk && \
    chown -R 65532:65532 /app/risk /app/compliance /app/models/risk && \
    chmod 750 /app/risk && \
    chmod 700 /app/risk/emergency && \
    chmod 755 /app/risk/calculations /app/risk/limits /app/risk/reports && \
    chmod 750 /app/compliance && \
    chmod 755 /app/models/risk

# Create risk configuration files with secure permissions
RUN touch /app/risk/limits/portfolio_limits.json \
          /app/risk/limits/position_limits.json \
          /app/risk/emergency/halt_conditions.json && \
    chown 65532:65532 /app/risk/limits/*.json /app/risk/emergency/*.json && \
    chmod 640 /app/risk/limits/*.json && \
    chmod 600 /app/risk/emergency/*.json

# Switch back to non-root user
USER 65532:65532

# ========================================================================================================
# RISK MANAGEMENT NETWORKING
# ========================================================================================================

# Expose the risk management API port
EXPOSE 3003

# Critical health check for risk management service
# Verifies risk calculation engines and emergency controls
HEALTHCHECK --interval=5s --timeout=10s --start-period=120s --retries=2 \
    CMD ["/nodejs/bin/node", "-e", "\
        const http = require('http'); \
        const options = { \
            hostname: 'localhost', \
            port: 3003, \
            path: '/health', \
            method: 'GET', \
            timeout: 8000 \
        }; \
        const req = http.request(options, (res) => { \
            let data = ''; \
            res.on('data', chunk => data += chunk); \
            res.on('end', () => { \
                if (res.statusCode === 200) { \
                    try { \
                        const health = JSON.parse(data); \
                        const requiredSystems = [ \
                            'risk_calculator', \
                            'position_monitor', \
                            'emergency_controls', \
                            'limit_engine' \
                        ]; \
                        const allSystemsHealthy = requiredSystems.every(system => \
                            health[system] && health[system].status === 'healthy' \
                        ); \
                        if (allSystemsHealthy && health.can_calculate_risk) { \
                            process.exit(0); \
                        } else { \
                            console.error('Critical risk systems unhealthy'); \
                            process.exit(1); \
                        } \
                    } catch (e) { \
                        console.error('Invalid health check response:', e.message); \
                        process.exit(1); \
                    } \
                } else { \
                    console.error('Risk management health check failed:', res.statusCode); \
                    process.exit(1); \
                } \
            }); \
        }); \
        req.on('error', (err) => { \
            console.error('Risk management health check error:', err.message); \
            process.exit(1); \
        }); \
        req.on('timeout', () => { \
            console.error('Risk management health check timed out'); \
            req.destroy(); \
            process.exit(1); \
        }); \
        req.setTimeout(8000); \
        req.end(); \
    "]

# ========================================================================================================
# STARTUP COMMAND
# ========================================================================================================

# Start the Risk Management service with high reliability and monitoring
CMD ["dist/apps/risk-management/main.js"]

# ========================================================================================================
# DEPLOYMENT NOTES FOR RISK MANAGEMENT SERVICE
# ========================================================================================================
#
# CRITICAL DEPLOYMENT REQUIREMENTS:
# - Deploy with maximum reliability and redundancy
# - Implement active-active clustering for zero downtime
# - Risk service must NEVER go down during trading hours
# - Implement hardware redundancy and automatic failover
#
# RESOURCE REQUIREMENTS:
# - CPU: Minimum 4 cores, recommended 8 cores for complex calculations
# - RAM: 6-12GB for large portfolio risk calculations
# - Storage: High-speed SSD for real-time data access
# - Network: Low latency connections to position and market data
#
# SECURITY AND COMPLIANCE:
# - Highest security classification due to financial risk exposure
# - All risk limits and calculations must be auditable
# - Implement role-based access control for risk limit modifications
# - Regular penetration testing and security audits required
#
# MONITORING AND ALERTING:
# - Real-time monitoring of all risk metrics and calculations
# - Immediate alerts for risk limit breaches (< 1 second response)
# - Monitor system performance and calculation accuracy
# - Alert on service degradation or calculation delays
# - Dashboard for real-time risk visualization
#
# RISK CALCULATION ACCURACY:
# - Implement multiple risk models for cross-validation
# - Regular backtesting of risk models against historical data
# - Stress testing under various market conditions
# - Model validation and independent risk assessment
#
# EMERGENCY PROCEDURES:
# - Documented procedures for emergency trading halts
# - Manual override capabilities with proper authorization
# - Communication protocols for risk breaches
# - Integration with exchange circuit breakers
# - Recovery procedures after risk events
#
# REGULATORY COMPLIANCE:
# - Maintain audit trails for all risk decisions
# - Regular reporting to risk management committee
# - Compliance with regulatory risk requirements
# - Documentation of risk management procedures
# - Regular model validation and governance
#
# DATA DEPENDENCIES:
# - Real-time position data from order execution service
# - Market data for mark-to-market calculations
# - Historical price data for volatility calculations
# - Correlation matrices and risk factor models
# - Regulatory requirements and limit configurations
#
# TESTING AND VALIDATION:
# - Comprehensive testing of all risk scenarios
# - Regular stress testing and scenario analysis
# - Validation against independent risk systems
# - Performance testing under high-load conditions
# - Disaster recovery testing and failover procedures
# ========================================================================================================