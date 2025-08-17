# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JTS (JooHan Trading System) is an automated trading system built with microservices architecture. It's designed to handle real-time market data, execute algorithmic trading strategies, and manage portfolios across multiple Korean exchanges.

**Key Technologies:**
- Backend: NestJS (TypeScript), FastAPI (Python)
- Databases: PostgreSQL, ClickHouse, MongoDB, Redis
- Message Queue: Kafka
- Containerization: Docker
- Monorepo: Nx workspace
- API Protocols: REST, gRPC, WebSocket

**Platform Requirements:**
- Linux (primary development and production)
- Windows (required for Creon API integration)

## Development Commands

```bash
# Install dependencies
npm install

# Start development environment
npm run dev

# Build all services
npm run build

# Run tests
npm run test

# Run specific service tests
npx nx test <service-name>

# Lint code
npm run lint

# Type checking
npm run type-check

# Format code
npm run format

# Generate new service
npx nx g @nestjs/schematics:app <service-name>

# Run specific service in development
npx nx serve <service-name>
```

## Architecture Overview

### Microservices Structure
The system follows a layered microservices architecture:

1. **API Gateway Layer**: Entry point for external requests, handles authentication and routing
2. **Core Services Layer**: Business logic services (trading, portfolio, strategy)
3. **Data Services Layer**: Market data collection, storage, and real-time processing
4. **Integration Layer**: Broker API integrations (Creon for Korean markets)
5. **Infrastructure Layer**: Shared utilities, logging, monitoring

### Service Communication
- **Synchronous**: HTTP/REST for request-response, gRPC for internal service calls
- **Asynchronous**: Kafka for event streaming and real-time data distribution
- **Real-time**: WebSocket connections for live market data

### Database Usage Patterns
- **PostgreSQL**: Core business data (users, strategies, orders, portfolios)
- **ClickHouse**: Time-series market data and analytics
- **MongoDB**: Configuration data and strategy parameters
- **Redis**: Caching, session management, rate limiting

## Development Guidelines

### Code Organization
- Each microservice is self-contained with its own database schema
- Shared utilities and types are in `libs/` directory
- Domain-driven design patterns for business logic
- Clean architecture with dependency injection

### API Rate Limiting
Broker APIs have strict rate limits that must be respected:
- Implement exponential backoff for failed requests
- Use Redis for distributed rate limiting across service instances
- Queue non-urgent requests during market hours

### Trading Strategy Development
- Strategies are defined using a custom DSL in TypeScript
- All strategies must include backtesting capabilities
- Risk management rules are enforced at the service level
- Real-time strategy execution requires proper error handling

### Testing Standards
- Maintain 95% test coverage for core trading logic
- Use mock data for broker API integrations during testing
- Backtesting framework validates strategy performance
- Integration tests verify service communication

## Broker Integration

### Creon API (Korean Markets)
- Runs on Windows service due to COM object requirements
- Implements retry logic with circuit breaker pattern
- Rate limiting: 200 requests per minute, 20 requests per second
- Data normalization layer converts to standard format

### Error Handling
- All broker interactions must have timeout handling
- Implement graceful degradation when APIs are unavailable
- Log all API errors for monitoring and debugging
- Maintain fallback data sources when possible

## Security Considerations

- API keys and secrets stored in environment variables only
- All inter-service communication uses TLS
- Database connections use connection pooling with auth
- Trading orders require multi-factor validation

## Performance Guidelines

### Real-time Data Processing
- Use streaming data pipelines for market data
- Implement data compression for high-frequency updates
- Cache frequently accessed data in Redis
- Optimize database queries for time-series data

### Monitoring and Observability
- All services expose health check endpoints
- Structured logging with correlation IDs
- Metrics collection for trading performance
- Alert on critical system failures

## Development Tips

### Local Development
- Use Docker Compose for service dependencies
- Configure VS Code with recommended extensions
- Set up pre-commit hooks for code formatting
- Use environment-specific configuration files

### Debugging Trading Logic
- Enable detailed logging for strategy execution
- Use backtesting mode to verify strategy changes
- Monitor order execution latency and success rates
- Validate data quality before strategy execution