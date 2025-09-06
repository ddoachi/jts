# ========================================================================================================
# JTS Trading System - Notification Service Dockerfile
# ========================================================================================================
# The Notification Service manages all system communications and alerts, ensuring that users, administrators,
# and external systems are informed of important events, trade executions, system status changes, and
# emergency conditions. It supports multiple communication channels and provides reliable message delivery.
#
# SERVICE RESPONSIBILITIES:
# - Multi-channel notification delivery (email, SMS, Telegram, WebSocket)
# - Real-time trade execution alerts and confirmations
# - System health monitoring and alert management
# - Emergency notification handling with priority escalation
# - User preference management and notification customization
# - Message queuing and delivery confirmation tracking
# - Audit trail maintenance for regulatory compliance
# - Integration with external communication providers
#
# RELIABILITY REQUIREMENTS:
# - Guaranteed message delivery for critical alerts
# - Fault tolerance with message persistence and retry logic
# - Support for multiple communication channel redundancy
# - Emergency notification override capabilities
# ========================================================================================================

# Inherit from the multi-stage base image with security hardening
FROM ../../docker/base:production

# Service-specific metadata and labels
LABEL service="notification-service" \
      tier="support" \
      exposure="internal" \
      security.level="medium" \
      scaling.type="horizontal" \
      communication.service="yes" \
      external.integrations="yes"

# ========================================================================================================
# NOTIFICATION SERVICE ENVIRONMENT CONFIGURATION
# ========================================================================================================

# Notification Service specific environment variables
ENV SERVICE_NAME=notification-service \
    SERVICE_PORT=3005 \
    # Notification channels configuration
    EMAIL_ENABLED=true \
    SMS_ENABLED=true \
    TELEGRAM_ENABLED=true \
    WEBSOCKET_ENABLED=true \
    SLACK_ENABLED=true \
    # Email service configuration (SMTP)
    SMTP_HOST=smtp.gmail.com \
    SMTP_PORT=587 \
    SMTP_SECURE=false \
    SMTP_AUTH_USER="" \
    SMTP_AUTH_PASS_FILE=/run/secrets/smtp_password \
    EMAIL_FROM_ADDRESS=noreply@jts.com \
    EMAIL_TEMPLATE_PATH=/app/templates/email \
    # SMS service configuration
    SMS_PROVIDER=twilio \
    SMS_API_URL=https://api.twilio.com/2010-04-01 \
    SMS_ACCOUNT_SID_FILE=/run/secrets/twilio_sid \
    SMS_AUTH_TOKEN_FILE=/run/secrets/twilio_token \
    SMS_FROM_NUMBER=+1234567890 \
    # Telegram bot configuration
    TELEGRAM_BOT_TOKEN_FILE=/run/secrets/telegram_bot_token \
    TELEGRAM_API_URL=https://api.telegram.org \
    TELEGRAM_WEBHOOK_URL=https://notifications.jts.com/telegram/webhook \
    # WebSocket server configuration
    WEBSOCKET_PORT=3006 \
    WEBSOCKET_MAX_CONNECTIONS=10000 \
    WEBSOCKET_HEARTBEAT_INTERVAL=30000 \
    # Slack integration
    SLACK_WEBHOOK_URL_FILE=/run/secrets/slack_webhook \
    SLACK_CHANNEL_ALERTS="#trading-alerts" \
    SLACK_CHANNEL_SYSTEM="#system-status" \
    # Message processing configuration
    MESSAGE_QUEUE_SIZE=50000 \
    MESSAGE_RETRY_ATTEMPTS=3 \
    MESSAGE_RETRY_DELAY=5000 \
    PRIORITY_MESSAGE_TIMEOUT=10000 \
    BULK_MESSAGE_BATCH_SIZE=100 \
    # Database connections
    NOTIFICATION_DB_URL=postgresql://postgres:5432/notifications \
    MESSAGE_CACHE_URL=redis://redis:6379/notifications \
    # Performance tuning
    NODE_OPTIONS="--max-old-space-size=2048" \
    # Monitoring and health checks
    HEALTH_CHECK_CHANNELS=true \
    DELIVERY_CONFIRMATION_REQUIRED=true

# ========================================================================================================
# NOTIFICATION SERVICE SPECIALIZED SETUP
# ========================================================================================================

# Install communication and templating tools
USER root
RUN apk add --no-cache --virtual .notification-deps \
        # Email and communication tools
        curl=8.11.0-r2 \
        wget=1.24.5-r0 \
        # Template processing
        jq=1.7.1-r0 \
        # Image processing for rich notifications
        imagemagick=7.1.1.29-r0

# Create notification service specific directories
RUN mkdir -p /app/templates/email /app/templates/sms /app/templates/telegram \
             /app/queue/pending /app/queue/failed /app/queue/sent \
             /app/logs/notifications /app/attachments && \
    chown -R 65532:65532 /app/templates /app/queue /app/logs/notifications /app/attachments && \
    chmod 755 /app/templates/email /app/templates/sms /app/templates/telegram && \
    chmod 750 /app/queue && \
    chmod 700 /app/queue/pending /app/queue/failed /app/queue/sent && \
    chmod 755 /app/logs/notifications && \
    chmod 750 /app/attachments

# Create default notification templates
RUN cat > /app/templates/email/trade_execution.html << 'EOF'
<html>
<head><title>Trade Execution Alert</title></head>
<body>
<h2>Trade Executed</h2>
<p><strong>Symbol:</strong> {{symbol}}</p>
<p><strong>Side:</strong> {{side}}</p>
<p><strong>Quantity:</strong> {{quantity}}</p>
<p><strong>Price:</strong> {{price}}</p>
<p><strong>Time:</strong> {{timestamp}}</p>
</body>
</html>
EOF

RUN cat > /app/templates/sms/emergency_alert.txt << 'EOF'
JTS EMERGENCY: {{message}}
Time: {{timestamp}}
Action Required: {{action}}
EOF

# Switch back to non-root user
USER 65532:65532

# ========================================================================================================
# NOTIFICATION SERVICE NETWORKING
# ========================================================================================================

# Expose the notification service API port and WebSocket port
EXPOSE 3005 3006

# Notification service health check with channel verification
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 \
    CMD ["/nodejs/bin/node", "-e", "\
        const http = require('http'); \
        const options = { \
            hostname: 'localhost', \
            port: 3005, \
            path: '/health', \
            method: 'GET', \
            timeout: 12000 \
        }; \
        const req = http.request(options, (res) => { \
            let data = ''; \
            res.on('data', chunk => data += chunk); \
            res.on('end', () => { \
                if (res.statusCode === 200) { \
                    try { \
                        const health = JSON.parse(data); \
                        const requiredChannels = ['email', 'websocket']; \
                        const channels = health.channels || {}; \
                        const minChannelsWorking = requiredChannels.some(channel => \
                            channels[channel] === 'healthy' \
                        ); \
                        if (minChannelsWorking && health.message_queue_healthy) { \
                            process.exit(0); \
                        } else { \
                            console.error('Notification channels or message queue unhealthy'); \
                            process.exit(1); \
                        } \
                    } catch (e) { \
                        console.error('Invalid health check response:', e.message); \
                        process.exit(1); \
                    } \
                } else { \
                    console.error('Notification service health check failed:', res.statusCode); \
                    process.exit(1); \
                } \
            }); \
        }); \
        req.on('error', (err) => { \
            console.error('Notification service health check error:', err.message); \
            process.exit(1); \
        }); \
        req.on('timeout', () => { \
            console.error('Notification service health check timed out'); \
            req.destroy(); \
            process.exit(1); \
        }); \
        req.setTimeout(12000); \
        req.end(); \
    "]

# ========================================================================================================
# STARTUP COMMAND
# ========================================================================================================

# Start the Notification Service with communication channel initialization
CMD ["dist/apps/notification-service/main.js"]

# ========================================================================================================
# DEPLOYMENT NOTES FOR NOTIFICATION SERVICE
# ========================================================================================================
#
# SCALABILITY AND AVAILABILITY:
# - Deploy multiple instances for high availability and load distribution
# - Use load balancing for WebSocket connections with session affinity
# - Implement message queue clustering for distributed processing
# - Scale based on message volume and delivery requirements
#
# RESOURCE REQUIREMENTS:
# - CPU: 1-2 cores per instance, I/O bound operations
# - RAM: 2-4GB depending on message queue size and WebSocket connections
# - Network: Reliable internet connection for external service APIs
# - Storage: Persistent storage for message history and templates
#
# EXTERNAL SERVICE INTEGRATION:
# - Configure SMTP settings for email delivery (Gmail, SendGrid, AWS SES)
# - Set up SMS provider accounts (Twilio, AWS SNS, or local SMS gateway)
# - Create Telegram bot and obtain API tokens
# - Configure Slack webhooks and bot permissions
# - Test all external integrations before production deployment
#
# SECURITY CONSIDERATIONS:
# - Store API keys and tokens in secure secrets management
# - Implement rate limiting to prevent notification spam
# - Validate and sanitize all message content to prevent injection
# - Use TLS for all external API communications
# - Implement access controls for notification administration
#
# MESSAGE DELIVERY GUARANTEES:
# - Implement persistent message queues for critical notifications
# - Use delivery confirmation and retry mechanisms
# - Provide multiple channel redundancy for emergency alerts
# - Track message delivery status and failure reasons
# - Implement escalation procedures for failed critical messages
#
# MONITORING AND ALERTING:
# - Monitor delivery success rates for each communication channel
# - Track message processing latency and queue depths
# - Alert on external service API failures or rate limit breaches
# - Monitor WebSocket connection counts and stability
# - Dashboard for notification service performance metrics
#
# COMPLIANCE AND AUDITING:
# - Maintain audit logs for all sent notifications
# - Implement message retention policies for regulatory compliance
# - Track user consent and notification preferences
# - Document data privacy and protection measures
# - Regular compliance reviews for communication data handling
#
# NOTIFICATION TYPES AND PRIORITIES:
# - Emergency alerts (system failures, security breaches)
# - Trade execution confirmations and order updates
# - Risk management alerts and position warnings
# - System maintenance and scheduled downtime notifications
# - Performance reports and daily summaries
# - User account and authentication alerts
#
# TEMPLATE MANAGEMENT:
# - Version control for notification templates
# - Support for multiple languages and localization
# - Dynamic content insertion with proper sanitization
# - Template testing and preview capabilities
# - A/B testing for notification effectiveness
#
# DISASTER RECOVERY:
# - Backup notification configurations and templates
# - Document communication channel failover procedures
# - Test emergency notification procedures regularly
# - Maintain offline communication channels for system failures
# - Recovery procedures for message queue data loss
#
# USER EXPERIENCE:
# - Implement notification preferences and opt-out mechanisms
# - Provide notification history and status tracking
# - Support for Do Not Disturb periods and time zone preferences
# - Rich content notifications with charts and attachments
# - Mobile-optimized notifications for trading alerts
# ========================================================================================================