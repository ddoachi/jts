# JTS Generators Guide

**Generated from spec**: [[E01-F03-T05] Create Development Tooling and Generators](../specs/E01/F03/T05/E01-F03-T05.spec.md)

## Overview

The JTS monorepo includes custom Nx generators to ensure consistent project structure and accelerate development. This guide provides comprehensive documentation for using and extending these generators.

## Table of Contents

1. [Available Generators](#available-generators)
2. [NestJS Service Generator](#nestjs-service-generator)
3. [JTS Library Generator](#jts-library-generator)
4. [Architecture & Design Decisions](#architecture--design-decisions)
5. [Troubleshooting](#troubleshooting)
6. [Extending Generators](#extending-generators)

## Available Generators

| Generator        | Purpose                          | Command          |
| ---------------- | -------------------------------- | ---------------- |
| `nestjs-service` | Create new NestJS microservice   | `yarn g:service` |
| `jts-library`    | Create scoped TypeScript library | `yarn g:lib`     |

## NestJS Service Generator

### Purpose

Creates a standardized NestJS microservice with JTS architecture patterns, including domain-driven design structure, health checks, Docker support, and optional integrations (Kafka, gRPC, WebSocket).

### Usage

```bash
# Interactive mode (recommended)
yarn g:service

# With options
yarn g:service --name=trading-service --port=3010

# With additional features
yarn g:service --name=market-data \
  --port=3020 \
  --includeKafka=true \
  --includeGrpc=true \
  --includeWebsocket=true
```

### Options

| Option             | Type    | Description               | Default                   |
| ------------------ | ------- | ------------------------- | ------------------------- |
| `name`             | string  | Service name (kebab-case) | Required                  |
| `directory`        | string  | Subdirectory in apps/     | Optional                  |
| `port`             | number  | Service port (3000-3999)  | Auto-assigned             |
| `tags`             | string  | Comma-separated Nx tags   | `scope:apps,type:service` |
| `includeKafka`     | boolean | Add Kafka configuration   | false                     |
| `includeGrpc`      | boolean | Add gRPC support          | false                     |
| `includeWebsocket` | boolean | Add WebSocket gateway     | false                     |

### Generated Structure

```
apps/
└── {service-name}/
    ├── src/
    │   ├── main.ts                 # Application bootstrap
    │   ├── app/
    │   │   ├── app.module.ts       # Root module
    │   │   └── health/
    │   │       ├── health.module.ts
    │   │       └── health.controller.ts
    │   ├── domain/                 # Business logic layer
    │   │   └── domain.module.ts
    │   ├── infra/                  # Infrastructure layer
    │   │   ├── infra.module.ts
    │   │   ├── kafka/              # If includeKafka=true
    │   │   ├── grpc/               # If includeGrpc=true
    │   │   └── websocket/          # If includeWebsocket=true
    │   └── shared/                 # Cross-cutting concerns
    │       └── shared.module.ts
    ├── Dockerfile                   # Multi-stage Docker build
    ├── .env.example                 # Environment template
    ├── README.md                    # Service documentation
    ├── project.json                 # Nx configuration
    ├── jest.config.ts              # Test configuration
    ├── tsconfig.json               # TypeScript config
    ├── tsconfig.app.json
    └── tsconfig.spec.json
```

### Key Features

#### 1. **Automatic Port Assignment**

The generator automatically assigns ports in the 3000-3999 range, avoiding conflicts with existing services:

```typescript
// Port assignment algorithm
function assignNextAvailablePort(tree: Tree): number {
  const basePort = 3000;
  const maxPort = 3999;
  // Scans existing services and finds next available port
}
```

#### 2. **Health Check Endpoints**

Every service includes health check endpoints for container orchestration:

- `GET /health` - Basic liveness check
- `GET /health/ready` - Detailed readiness check with dependencies

#### 3. **Docker Configuration**

Multi-stage Dockerfile with:

- Optimized layer caching
- Non-root user for security
- Health check configuration
- Signal handling with dumb-init

#### 4. **Environment Configuration**

Comprehensive `.env.example` with all service dependencies:

- Database connections (PostgreSQL, MongoDB, ClickHouse, Redis)
- Message queue configuration (Kafka)
- JWT and security settings
- Monitoring and logging

### Examples

#### Example 1: Basic Trading Service

```bash
yarn g:service --name=trading-engine --port=3100
```

This creates a basic service at `apps/trading-engine/` with:

- Port 3100
- Standard JTS structure
- Health checks
- Docker support

#### Example 2: Market Data Service with Kafka and WebSocket

```bash
yarn g:service --name=market-data \
  --port=3200 \
  --includeKafka=true \
  --includeWebsocket=true
```

This creates a service at `apps/market-data/` with:

- Port 3200
- Kafka producer/consumer configuration
- WebSocket gateway for real-time updates
- All standard features

## JTS Library Generator

### Purpose

Creates TypeScript libraries with proper scoping, following the JTS monorepo architecture. Libraries are organized by scope to enforce architectural boundaries.

### Usage

```bash
# Interactive mode (recommended)
yarn g:lib

# With options
yarn g:lib --name=common-types --scope=shared

# Advanced options
yarn g:lib --name=trading-logic \
  --scope=domain \
  --buildable=true \
  --publishable=false \
  --strict=true
```

### Options

| Option        | Type    | Description                   | Default        |
| ------------- | ------- | ----------------------------- | -------------- |
| `name`        | string  | Library name (kebab-case)     | Required       |
| `scope`       | enum    | Library scope (see below)     | Required       |
| `directory`   | string  | Subdirectory within scope     | Optional       |
| `buildable`   | boolean | Can be built independently    | true           |
| `publishable` | boolean | Can be published to npm       | false          |
| `strict`      | boolean | Enable TypeScript strict mode | true           |
| `tags`        | string  | Additional Nx tags            | Auto-generated |

### Scopes

| Scope            | Purpose                           | Import Path                  | Example                        |
| ---------------- | --------------------------------- | ---------------------------- | ------------------------------ |
| `shared`         | Cross-cutting utilities and types | `@jts/shared/{name}`         | `@jts/shared/common-types`     |
| `domain`         | Business logic and domain models  | `@jts/domain/{name}`         | `@jts/domain/trading-logic`    |
| `infrastructure` | External service interfaces       | `@jts/infrastructure/{name}` | `@jts/infrastructure/database` |
| `brokers`        | Broker-specific implementations   | `@jts/brokers/{name}`        | `@jts/brokers/creon`           |

### Generated Structure by Scope

#### Shared Libraries

```
libs/shared/{library-name}/
├── src/
│   ├── index.ts           # Main barrel export
│   ├── constants/         # Shared constants
│   ├── types/            # TypeScript types
│   ├── utils/            # Utility functions
│   └── dto/              # Data transfer objects
├── README.md
├── project.json
├── jest.config.ts
├── tsconfig.json
├── tsconfig.lib.json
└── tsconfig.spec.json
```

#### Domain Libraries

```
libs/domain/{library-name}/
├── src/
│   ├── index.ts
│   ├── entities/         # Domain entities
│   ├── value-objects/    # Value objects
│   ├── services/         # Domain services
│   ├── events/           # Domain events
│   └── repositories/     # Repository interfaces
└── ...
```

#### Infrastructure Libraries

```
libs/infrastructure/{library-name}/
├── src/
│   ├── index.ts
│   ├── adapters/         # Infrastructure adapters
│   ├── clients/          # External clients
│   └── config/           # Configuration
└── ...
```

#### Broker Libraries

```
libs/brokers/{library-name}/
├── src/
│   ├── index.ts
│   └── adapter.ts        # Broker adapter implementation
└── ...
```

### Examples

#### Example 1: Shared Types Library

```bash
yarn g:lib --name=common-types --scope=shared
```

Creates `libs/shared/common-types/` with:

- Import path: `@jts/shared/common-types`
- Structure for types, constants, and utilities
- Buildable configuration

#### Example 2: Domain Trading Library

```bash
yarn g:lib --name=trading-logic --scope=domain
```

Creates `libs/domain/trading-logic/` with:

- Import path: `@jts/domain/trading-logic`
- DDD structure (entities, services, events)
- Repository interfaces

#### Example 3: Broker Integration

```bash
yarn g:lib --name=creon --scope=brokers
```

Creates `libs/brokers/creon/` with:

- Import path: `@jts/brokers/creon`
- Broker adapter template
- Platform-specific implementation structure

## Architecture & Design Decisions

### Why Custom Generators?

1. **Consistency**: Ensures all services and libraries follow the same structure
2. **Best Practices**: Embeds JTS architectural patterns automatically
3. **Speed**: Reduces boilerplate and setup time from hours to seconds
4. **Documentation**: Self-documenting through consistent patterns

### Design Principles

#### 1. **Domain-Driven Design**

All services follow DDD principles with clear separation:

- **Domain Layer**: Pure business logic, no framework dependencies
- **Infrastructure Layer**: External service implementations
- **Application Layer**: Controllers and orchestration
- **Shared Layer**: Cross-cutting concerns

#### 2. **Ports and Adapters**

Infrastructure implements domain interfaces:

```typescript
// Domain defines the port (interface)
export interface OrderRepository {
  save(order: Order): Promise<Order>;
}

// Infrastructure provides the adapter (implementation)
export class PostgresOrderRepository implements OrderRepository {
  async save(order: Order): Promise<Order> {
    // PostgreSQL-specific implementation
  }
}
```

#### 3. **Dependency Injection**

All dependencies are injected, making testing and swapping implementations easy:

```typescript
@Injectable()
export class TradingService {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly marketData: MarketDataService,
  ) {}
}
```

### File Naming Conventions

- **Services**: `{name}-service` (e.g., `trading-service`)
- **Libraries**: `{scope}-{name}` (e.g., `shared-common-types`)
- **Files**: kebab-case (e.g., `order-service.ts`)
- **Classes**: PascalCase (e.g., `OrderService`)
- **Interfaces**: PascalCase with 'I' prefix optional (e.g., `OrderRepository`)

### Import Path Strategy

All libraries use the `@jts` namespace:

```typescript
// Good - uses namespace
import { OrderDTO } from '@jts/shared/common-types';
import { TradingService } from '@jts/domain/trading-logic';

// Bad - relative imports across packages
import { OrderDTO } from '../../../libs/shared/common-types';
```

## Troubleshooting

### Common Issues

#### 1. **Generator Not Found**

```bash
Error: Cannot find generator @tools/generators/nestjs-service
```

**Solution**: Ensure you're in the repository root and generators are properly installed:

```bash
cd /path/to/jts
yarn install
```

#### 2. **Port Already in Use**

```bash
Error: No available ports in range 3000-3999
```

**Solution**: Either:

- Manually specify a port: `--port=4000`
- Clean up unused services
- Extend the port range in the generator

#### 3. **Invalid Scope**

```bash
Error: Invalid scope: custom. Must be one of: shared, domain, infrastructure, brokers
```

**Solution**: Use one of the valid scopes or extend the generator to support custom scopes.

#### 4. **TypeScript Path Not Resolving**

```typescript
Cannot find module '@jts/shared/my-lib'
```

**Solution**: Ensure `tsconfig.base.json` has the correct path mapping:

```json
{
  "compilerOptions": {
    "paths": {
      "@jts/shared/my-lib": ["libs/shared/my-lib/src/index.ts"]
    }
  }
}
```

### Validation Checks

Before using generated code:

1. **Build the project**:

```bash
nx build {project-name}
```

2. **Run tests**:

```bash
nx test {project-name}
```

3. **Check dependencies**:

```bash
nx graph
```

4. **Validate imports**:

```bash
nx lint {project-name}
```

## Extending Generators

### Adding a New Generator

1. **Create generator directory**:

```bash
mkdir -p tools/generators/my-generator
```

2. **Create generator files**:

```
tools/generators/my-generator/
├── index.ts        # Generator logic
├── schema.json     # Options schema
└── files/          # Template files
```

3. **Implement generator**:

```typescript
import { Tree, formatFiles, generateFiles } from '@nx/devkit';

export default async function myGenerator(tree: Tree, options: any) {
  // Generator implementation
  await formatFiles(tree);
}
```

4. **Add npm script**:

```json
{
  "scripts": {
    "g:my": "nx g ./tools/generators/my-generator"
  }
}
```

### Modifying Existing Generators

1. **Locate generator**: `tools/generators/{generator-name}/`
2. **Modify logic**: Update `index.ts`
3. **Update templates**: Edit files in `files/`
4. **Test changes**: Run generator with test project

### Template Variables

Templates use EJS syntax with these available variables:

| Variable                | Description           | Example                |
| ----------------------- | --------------------- | ---------------------- |
| `<%= name %>`           | Raw name              | `trading-service`      |
| `<%= className %>`      | PascalCase name       | `TradingService`       |
| `<%= fileName %>`       | File-safe name        | `trading-service`      |
| `<%= constantName %>`   | CONSTANT_CASE         | `TRADING_SERVICE`      |
| `<%= propertyName %>`   | camelCase             | `tradingService`       |
| `<%= projectRoot %>`    | Project path          | `apps/trading-service` |
| `<%= offsetFromRoot %>` | Relative path to root | `../../`               |

### Best Practices for Custom Generators

1. **Validate inputs**: Check for required options and valid values
2. **Normalize names**: Use `@nx/devkit` names utility
3. **Format files**: Always call `formatFiles()` at the end
4. **Install packages**: Return `installPackagesTask()` if adding dependencies
5. **Document options**: Use clear descriptions in schema.json
6. **Test thoroughly**: Create test projects to validate generator output

## See Also

- [Nx Generator Documentation](https://nx.dev/generators/intro/what-is-a-generator)
- [NestJS Architecture](https://docs.nestjs.com/fundamentals/platform-agnosticism)
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [Ports and Adapters Pattern](https://alistair.cockburn.us/hexagonal-architecture/)
