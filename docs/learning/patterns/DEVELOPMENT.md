# JTS Development Guide

> Generated from spec: E01-F02-T06 (Development Scripts and Automation)  
> Spec ID: 24146db4

## Table of Contents

- [Getting Started](#getting-started)
- [Architecture Overview](#architecture-overview)
- [Development Workflow](#development-workflow)
- [Service Management](#service-management)
- [Database Operations](#database-operations)
- [Testing Strategy](#testing-strategy)
- [Debugging](#debugging)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Getting Started

### Prerequisites

Before starting development, ensure you have the following installed:

- **Node.js** 20+ (LTS recommended)
- **Yarn** 4+ (Berry)
- **Docker** and Docker Compose
- **Git**
- **VS Code** (recommended IDE)

### Initial Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/ddoachi/jts-monorepo.git
   cd jts-monorepo
   ```

2. **Run the Setup Script**

   ```bash
   yarn setup
   ```

   This script will:
   - Check prerequisites
   - Install dependencies
   - Configure environment
   - Start Docker services
   - Run database migrations
   - Set up Git hooks

3. **Configure Environment**

   Update `.env.local` with your credentials:

   ```bash
   # Edit the environment file
   nano .env.local

   # Validate configuration
   yarn env:validate
   ```

### Quick Setup Options

For experienced developers or CI/CD environments:

```bash
# Quick setup (skip optional steps)
yarn setup:quick

# Skip Docker services
yarn setup --skip-services

# Skip dependency installation
yarn setup --skip-deps
```

## Architecture Overview

### Monorepo Structure

```
jts-monorepo/
├── apps/                    # Microservices
│   ├── api-gateway/        # API Gateway service
│   ├── strategy-engine/    # Strategy execution service
│   ├── risk-management/    # Risk management service
│   ├── order-execution/    # Order execution service
│   └── market-data-collector/ # Market data service
├── libs/                    # Shared libraries
│   ├── common/             # Common utilities
│   ├── database/           # Database entities
│   └── messaging/          # Kafka messaging
├── docker/                  # Docker configurations
├── scripts/                 # Development scripts
├── specs/                   # Technical specifications
└── docs/                    # Documentation
```

### Technology Stack

| Layer           | Technology                             | Purpose                  |
| --------------- | -------------------------------------- | ------------------------ |
| Runtime         | Node.js 20+                            | JavaScript runtime       |
| Framework       | NestJS                                 | Microservices framework  |
| Language        | TypeScript                             | Type-safe development    |
| Package Manager | Yarn 4 (Berry)                         | Dependency management    |
| Build Tool      | Nx                                     | Monorepo orchestration   |
| Databases       | PostgreSQL, ClickHouse, MongoDB, Redis | Data persistence         |
| Message Queue   | Kafka                                  | Event streaming          |
| Container       | Docker                                 | Service containerization |

## Development Workflow

### Daily Development Flow

1. **Start Services**

   ```bash
   # Start all Docker services
   yarn dev:start

   # Check service health
   yarn dev:health
   ```

2. **Run Applications**

   ```bash
   # Start all microservices
   yarn dev

   # Or start specific services
   yarn start:gateway
   yarn start:strategy
   ```

3. **Monitor Services**

   ```bash
   # View logs
   yarn dev:logs

   # Check status
   yarn dev:status
   ```

4. **Stop Services**

   ```bash
   # Stop Docker services
   yarn dev:stop

   # Clean everything (including volumes)
   yarn dev:clean
   ```

### Code Development

#### Creating New Features

1. **Generate Component**

   ```bash
   # Generate new service
   nx generate @nestjs/schematics:application --name=new-service

   # Generate new library
   nx generate @nx/node:library --name=new-lib
   ```

2. **Development Server**

   ```bash
   # Run with hot reload
   nx serve api-gateway --watch
   ```

3. **Code Quality**

   ```bash
   # Run linter
   yarn lint

   # Format code
   yarn format

   # Type checking
   yarn type-check
   ```

#### Git Workflow

1. **Feature Branch**

   ```bash
   git checkout -b feature/your-feature
   ```

2. **Commit Changes**

   ```bash
   # Commits are validated by commitlint
   git commit -m "feat(gateway): add new endpoint"
   ```

3. **Push and PR**
   ```bash
   git push origin feature/your-feature
   ```

### Commit Message Convention

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Test additions or corrections
- `chore`: Maintenance tasks

Examples:

```bash
feat(strategy): add momentum indicator
fix(risk): correct position size calculation
docs(readme): update setup instructions
```

## Service Management

### Docker Services

All infrastructure services are managed via Docker Compose:

```bash
# Start services
yarn dev:start

# Stop services
yarn dev:stop

# Restart services
yarn dev:restart

# View logs
yarn dev:logs

# Clean all data
yarn dev:clean
```

### Service URLs

| Service     | URL                   | Credentials         |
| ----------- | --------------------- | ------------------- |
| API Gateway | http://localhost:3000 | -                   |
| PostgreSQL  | localhost:5432        | jts_user/jts_pass   |
| ClickHouse  | http://localhost:8123 | default/-           |
| MongoDB     | localhost:27017       | jts_user/jts_pass   |
| Redis       | localhost:6379        | -                   |
| Kafka       | localhost:9092        | -                   |
| Kafka UI    | http://localhost:8080 | -                   |
| pgAdmin     | http://localhost:5050 | admin@jts.com/admin |

### Health Monitoring

Check service health status:

```bash
# Quick health check
yarn dev:health

# Verbose output
node scripts/check-services-health.js --verbose

# JSON output
node scripts/check-services-health.js --json
```

## Database Operations

### Migrations

```bash
# Run all migrations
yarn db:migrate

# PostgreSQL only
yarn db:migrate:postgres

# ClickHouse only
yarn db:migrate:clickhouse
```

### Seeding

```bash
# Seed all databases
yarn db:seed

# PostgreSQL only
yarn db:seed:postgres

# ClickHouse only
yarn db:seed:clickhouse
```

### Reset Database

```bash
# Complete reset (clean + migrate + seed)
yarn db:reset
```

### Database Access

#### PostgreSQL

```bash
# Via Docker
docker exec -it jts-postgres-dev psql -U jts_user -d jts_dev

# Via pgAdmin
# Open http://localhost:5050
# Login: admin@jts.com / admin
```

#### ClickHouse

```bash
# Via Docker
docker exec -it jts-clickhouse-dev clickhouse-client

# Via HTTP
curl http://localhost:8123/?query=SELECT%201
```

#### MongoDB

```bash
# Via Docker
docker exec -it jts-mongodb-dev mongosh -u jts_user -p jts_pass

# Connection string
mongodb://jts_user:jts_pass@localhost:27017/jts_dev
```

#### Redis

```bash
# Via Docker
docker exec -it jts-redis-dev redis-cli

# Via redis-cli
redis-cli -h localhost -p 6379
```

## Testing Strategy

### Unit Tests

```bash
# Run all tests
yarn test

# Run affected tests
yarn test:affected

# Watch mode
yarn test:watch

# Specific service
nx test api-gateway
```

### Integration Tests

```bash
# Run e2e tests
yarn test:e2e

# Specific service
nx e2e api-gateway-e2e
```

### Test Coverage

```bash
# Generate coverage report
nx test api-gateway --coverage

# View coverage
open coverage/apps/api-gateway/index.html
```

### Testing Best Practices

1. **Test Isolation**: Each test should be independent
2. **Mock External Services**: Use mocks for databases and APIs
3. **Test Data**: Use factories for test data generation
4. **Coverage Target**: Maintain >80% coverage for critical paths

## Debugging

### VS Code Configuration

The project includes VS Code debugging configurations:

1. Open VS Code
2. Go to Run and Debug (Ctrl+Shift+D)
3. Select configuration (e.g., "Debug API Gateway")
4. Press F5 to start debugging

### Remote Debugging

For Docker containers:

```json
{
  "type": "node",
  "request": "attach",
  "name": "Attach to Docker",
  "port": 9229,
  "address": "localhost",
  "localRoot": "${workspaceFolder}",
  "remoteRoot": "/app",
  "protocol": "inspector"
}
```

### Logging

Configure log levels in `.env.local`:

```bash
LOG_LEVEL=debug  # debug, info, warn, error
```

Access logs:

```bash
# All services
yarn dev:logs

# Specific service
docker logs jts-api-gateway-dev -f

# Filter logs
yarn dev:logs | grep ERROR
```

## Troubleshooting

### Common Issues

#### Port Already in Use

```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port
API_GATEWAY_PORT=3001 yarn start:gateway
```

#### Docker Issues

```bash
# Reset Docker
docker system prune -a --volumes

# Restart Docker daemon
sudo systemctl restart docker  # Linux
# Restart Docker Desktop on Windows/Mac
```

#### Dependency Issues

```bash
# Clear yarn cache
yarn cache clean

# Reinstall dependencies
rm -rf node_modules
rm yarn.lock
yarn install
```

#### Database Connection Issues

```bash
# Check service is running
yarn dev:health

# Restart specific service
docker restart jts-postgres-dev

# Check logs
docker logs jts-postgres-dev
```

### Environment Variables

Common environment issues:

```bash
# Validate environment
yarn env:validate

# Reset to defaults
cp .env.example .env.local

# Check loaded variables
node -e "console.log(process.env.DATABASE_URL)"
```

## Best Practices

### Code Organization

1. **Domain-Driven Design**: Organize by business domain
2. **Dependency Injection**: Use NestJS DI container
3. **Repository Pattern**: Abstract database access
4. **DTO Validation**: Validate all inputs
5. **Error Handling**: Use custom exception filters

### Performance

1. **Connection Pooling**: Configure database pools
2. **Caching**: Use Redis for frequently accessed data
3. **Pagination**: Implement cursor-based pagination
4. **Indexing**: Add database indexes for queries
5. **Rate Limiting**: Implement API rate limits

### Security

1. **Environment Variables**: Never commit secrets
2. **Authentication**: Use JWT with refresh tokens
3. **Authorization**: Implement RBAC
4. **Input Validation**: Sanitize all inputs
5. **HTTPS**: Use TLS in production

### Monitoring

1. **Health Checks**: Implement health endpoints
2. **Metrics**: Export Prometheus metrics
3. **Logging**: Structured logging with correlation IDs
4. **Tracing**: Distributed tracing with OpenTelemetry
5. **Alerting**: Set up critical alerts

### Development Tips

1. **Use TypeScript Strictly**: Enable strict mode
2. **Write Tests First**: TDD approach
3. **Document APIs**: Use Swagger/OpenAPI
4. **Code Reviews**: Require PR reviews
5. **CI/CD**: Automate testing and deployment

## Additional Resources

- [NestJS Documentation](https://docs.nestjs.com/)
- [Nx Documentation](https://nx.dev/)
- [Docker Documentation](https://docs.docker.com/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)

## Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search existing GitHub issues
3. Create a new issue with:
   - Environment details
   - Steps to reproduce
   - Error messages
   - Expected behavior

---

Happy coding! 🚀
