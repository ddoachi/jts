---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '1003' # Numeric ID for stable reference
title: 'Monorepo Structure and Tooling'
type: 'feature' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '1000' # Parent spec ID (leave empty for top-level)
children: ['1031', '1032', '1033', '1034', '1035', '1036'] # Child spec IDs (if any)
epic: '1000' # Root epic ID for this work
domain: 'infrastructure' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low

# === TRACKING ===
created: '2025-08-24' # YYYY-MM-DD
updated: '2025-08-28' # YYYY-MM-DD
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 12 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: ['1002'] # Must be done before this (spec IDs)
blocks: ['1004', '1005', '1006', '1007'] # This blocks these specs
related: ['1001'] # Related but not blocking (spec IDs)

# === IMPLEMENTATION ===
pull_requests: [] # GitHub PR numbers
commits: [] # Key implementation commits
context_file: "context.md" # Implementation journal
files: ['nx.json', 'package.json', 'tsconfig.base.json', 'project.json', 'libs/', 'apps/', 'tools/', '.eslintrc.json', 'jest.config.ts'] # Key files to modify

# === METADATA ===
tags: ['monorepo', 'nx', 'tooling', 'workspace', 'typescript', 'build', 'testing'] # Searchable tags
effort: 'medium' # small | medium | large | epic
risk: 'medium' # low | medium | high

# ============================================================================
---

# Monorepo Structure and Tooling

## Overview

Establish a comprehensive monorepo structure using Nx workspace to manage all JTS microservices, shared libraries, and applications in a single repository. This feature focuses on creating an efficient development workflow with proper project organization, dependency management, build optimization, and testing infrastructure.

## Acceptance Criteria

- [ ] **Nx Workspace Setup**: Nx 17+ workspace with TypeScript and NestJS presets configured
- [ ] **Project Structure**: Organized apps/ and libs/ structure with clear separation of concerns
- [ ] **Shared Libraries**: Common DTOs, interfaces, utilities, and configuration libraries
- [ ] **Build Configuration**: Optimized build processes with caching and affected builds
- [ ] **Testing Infrastructure**: Jest configuration with coverage reporting and parallel execution
- [ ] **Linting and Formatting**: ESLint, Prettier, and TypeScript strict mode configuration
- [ ] **Dependency Management**: Single package.json with proper dependency organization
- [ ] **Code Generation**: Custom schematics for generating services and libraries
- [ ] **CI/CD Integration**: GitHub Actions workflows for affected builds and tests
- [ ] **Development Scripts**: npm scripts for common development tasks
- [ ] **Frontend Architecture**: PWA-first approach with responsive design for desktop/mobile
- [ ] **State Management**: Zustand stores for real-time data synchronization
- [ ] **Component Library**: Reusable UI components with mobile/desktop variants
- [ ] **Service Worker**: Offline capabilities and background sync for trading operations

## Technical Approach

### Nx Workspace Architecture

#### System Architecture Layers

```
┌──────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                            │
│                 (PWA with Service Workers)                       │
└──────────────────────────────────────────────────────────────────┘
                               ↓
┌──────────────────────────────────────────────────────────────────┐
│                      Gateway Layer                               │
│              (API Gateway with Auth & Rate Limiting)             │
└──────────────────────────────────────────────────────────────────┘
                               ↓
┌──────────────────────────────────────────────────────────────────┐
│                    Business Layer                                │
├────────────────┬────────────────┬────────────────┬───────────────┤
│    Strategy    │   Risk         │    Portfolio   │    Order      │
│    Engine      │   Management   │    Tracker     │    Execution  │
├────────────────┴────────────────┴────────────────┴───────────────┤
│        Market Data Collector    │    Notification Service        │
└──────────────────────────────────────────────────────────────────┘
                               ↓
┌──────────────────────────────────────────────────────────────────┐
│                   Integration Layer                              │
│            (Broker Libraries & Infrastructure Utilities)         │
│         libs/brokers/* | libs/infrastructure/*                   │
└──────────────────────────────────────────────────────────────────┘
                               ↓
┌──────────────────────────────────────────────────────────────────┐
│                    Messaging Layer                               │
├───────────────────────────────┬──────────────────────────────────┤
│      Kafka (Event Stream)     │     Redis (Cache/Lock/Session)   │
└───────────────────────────────┴──────────────────────────────────┘
                               ↓
┌──────────────────────────────────────────────────────────────────┐
│                     Brokers Layer                                │
├─────────────┬─────────────┬─────────────┬───────────────────────┤
│Creon Service│ KIS Service │Binance Serv.│    Upbit Service      │
│ (Windows)   │  (Linux)    │  (Linux)    │     (Linux)           │
│Rate: 15s/60 │Rate: 1s/20  │Rate: 1m/1200│   Rate: 1s/10         │
└─────────────┴─────────────┴─────────────┴───────────────────────┘
                               ↓
┌──────────────────────────────────────────────────────────────────┐
│                      Data Layer                                  │
├──────────────┬──────────────┬──────────────┬────────────────────┤
│ PostgreSQL   │ ClickHouse   │   MongoDB    │   File Storage     │
│(Transactions)│(Time Series) │(Configuration)│  (Logs/Backups)   │
└──────────────┴──────────────┴──────────────┴────────────────────┘
```

#### Workspace Structure

**Note**: The workspace follows Nx conventions where:
- `apps/` contains standalone microservices and applications
- `libs/` contains shared libraries and reusable modules
- Each service in `apps/` can import libraries from `libs/`
- No top-level `src/` directory - each app/lib has its own `src/`

```
jts/
├── apps/                           # Applications (Standalone Microservices)
│   ├── api-gateway/               # Express.js API Gateway
│   ├── web-app/                   # Next.js Frontend
│   ├── strategy-engine/           # NestJS Strategy Service
│   ├── risk-management/           # NestJS Risk Service
│   ├── order-execution/           # NestJS Order Service
│   ├── market-data-collector/     # NestJS Market Data Service
│   ├── notification-service/      # NestJS Notification Service
│   └── creon-bridge/             # Windows COM Bridge Service
├── libs/                          # Shared Libraries (Reusable Modules)
│   ├── shared/
│   │   ├── dto/                  # Data Transfer Objects
│   │   ├── interfaces/           # TypeScript Interfaces
│   │   ├── types/                # Type Definitions
│   │   ├── utils/                # Utility Functions
│   │   ├── constants/            # Application Constants
│   │   └── config/               # Configuration Utilities
│   ├── domain/
│   │   ├── trading/              # Trading Domain Logic
│   │   ├── market-data/          # Market Data Domain
│   │   ├── portfolio/            # Portfolio Domain
│   │   ├── risk/                 # Risk Management Domain
│   │   └── strategy/             # Strategy Domain
│   ├── infrastructure/
│   │   ├── database/             # Database Utilities
│   │   ├── messaging/            # Kafka/Redis Utilities
│   │   ├── http/                 # HTTP Client Utilities
│   │   ├── logging/              # Logging Infrastructure
│   │   └── monitoring/           # Monitoring Utilities
│   └── brokers/
│       ├── creon/                # Creon API Integration
│       ├── kis/                  # KIS API Integration
│       ├── binance/              # Binance API Integration
│       └── upbit/                # Upbit API Integration
├── tools/                         # Development Tools
│   ├── generators/               # Custom Nx Generators
│   ├── executors/                # Custom Nx Executors
│   ├── scripts/                  # Build and Deployment Scripts
│   └── workspace-plugin/         # Custom Workspace Plugin
├── configs/                       # Configuration Files
│   ├── eslint/                   # ESLint Configurations
│   ├── jest/                     # Jest Configurations
│   ├── typescript/               # TypeScript Configurations
│   └── docker/                   # Docker Configurations
└── docs/                         # Documentation
    ├── architecture/             # Architecture Documentation
    ├── development/              # Development Guides
    └── deployment/               # Deployment Documentation
```

#### Nx Configuration (`nx.json`)
```json
{
  "$schema": "./node_modules/nx/schemas/nx-schema.json",
  "version": 3,
  "tasksRunnerOptions": {
    "default": {
      "runner": "nx/tasks-runners/default",
      "options": {
        "cacheableOperations": [
          "build",
          "lint",
          "test",
          "e2e",
          "type-check"
        ],
        "parallel": 4,
        "maxParallel": 6
      }
    }
  },
  "namedInputs": {
    "default": ["{projectRoot}/**/*", "sharedGlobals"],
    "production": [
      "default",
      "!{projectRoot}/**/?(*.)+(spec|test).[jt]s?(x)?(.snap)",
      "!{projectRoot}/tsconfig.spec.json",
      "!{projectRoot}/jest.config.[jt]s",
      "!{projectRoot}/.eslintrc.json",
      "!{projectRoot}/**/*.stories.@(js|jsx|ts|tsx|mdx)"
    ],
    "sharedGlobals": []
  },
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"],
      "cache": true
    },
    "test": {
      "inputs": ["default", "^production", "{workspaceRoot}/jest.preset.js"],
      "cache": true,
      "options": {
        "passWithNoTests": true
      },
      "configurations": {
        "ci": {
          "ci": true,
          "coverage": true
        }
      }
    },
    "lint": {
      "inputs": ["default", "{workspaceRoot}/.eslintrc.json"],
      "cache": true
    },
    "type-check": {
      "dependsOn": ["^type-check"],
      "inputs": ["default"],
      "cache": true
    }
  },
  "generators": {
    "@nx/angular:application": {
      "style": "scss",
      "linter": "eslint",
      "unitTestRunner": "jest",
      "e2eTestRunner": "cypress"
    },
    "@nx/angular:library": {
      "linter": "eslint",
      "unitTestRunner": "jest"
    },
    "@nx/angular:component": {
      "style": "scss"
    },
    "@nx/nest:application": {
      "linter": "eslint",
      "unitTestRunner": "jest"
    },
    "@nx/next:application": {
      "style": "tailwind",
      "linter": "eslint",
      "unitTestRunner": "jest"
    }
  },
  "plugins": [
    {
      "plugin": "@nx/jest/plugin",
      "options": {
        "targetName": "test"
      }
    },
    {
      "plugin": "@nx/eslint/plugin",
      "options": {
        "targetName": "lint"
      }
    },
    {
      "plugin": "@nx/next/plugin",
      "options": {
        "startTargetName": "start",
        "buildTargetName": "build",
        "devTargetName": "dev"
      }
    },
    {
      "plugin": "@nx/webpack/plugin",
      "options": {
        "buildTargetName": "build",
        "serveTargetName": "serve",
        "previewTargetName": "preview"
      }
    }
  ]
}
```

### Package.json Configuration

#### Root Package.json
```json
{
  "name": "@jts/trading-system",
  "version": "1.0.0",
  "private": true,
  "description": "JTS Automated Trading System - Monorepo",
  "license": "UNLICENSED",
  "workspaces": ["apps/*", "libs/*"],
  "packageManager": "npm@10.2.0",
  "engines": {
    "node": ">=20.0.0",
    "npm": ">=10.0.0"
  },
  "scripts": {
    "dev": "nx serve",
    "build": "nx build",
    "test": "nx test",
    "test:ci": "nx test --configuration=ci",
    "test:affected": "nx affected --target=test --parallel=3",
    "test:coverage": "nx test --coverage",
    "lint": "nx lint",
    "lint:fix": "nx lint --fix",
    "lint:affected": "nx affected --target=lint --parallel=3",
    "type-check": "nx run-many --target=type-check --all",
    "type-check:affected": "nx affected --target=type-check",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "build:all": "nx run-many --target=build --all",
    "build:affected": "nx affected --target=build --parallel=3",
    "build:production": "nx run-many --target=build --configuration=production --all",
    "clean": "nx reset && rm -rf dist tmp coverage .nx",
    "clean:modules": "rm -rf node_modules apps/*/node_modules libs/*/node_modules",
    "dep-graph": "nx graph",
    "affected:graph": "nx affected:graph",
    "generate:app": "nx g @nx/nest:app",
    "generate:lib": "nx g @nx/js:lib",
    "generate:service": "nx g @nx/nest:service",
    "migration:run": "nx migrate --run-migrations",
    "migration:check": "nx migrate latest",
    "workspace:setup": "npm install && npm run build:all",
    "workspace:reset": "npm run clean && npm run clean:modules && npm install",
    "docker:build": "docker-compose build",
    "docker:up": "docker-compose up -d",
    "docker:down": "docker-compose down",
    "docker:logs": "docker-compose logs -f",
    "services:health": "node tools/scripts/check-services-health.js",
    "db:migrate": "npm run db:migrate:postgres && npm run db:migrate:clickhouse",
    "db:seed": "npm run db:seed:postgres && npm run db:seed:clickhouse",
    "release": "semantic-release",
    "prepare": "husky install"
  },
  "dependencies": {
    "@nestjs/common": "^10.3.0",
    "@nestjs/core": "^10.3.0",
    "@nestjs/platform-express": "^10.3.0",
    "@nestjs/platform-fastify": "^10.3.0",
    "@nestjs/microservices": "^10.3.0",
    "@nestjs/swagger": "^7.1.0",
    "@nestjs/typeorm": "^10.0.1",
    "@nestjs/config": "^3.1.1",
    "@nestjs/jwt": "^10.2.0",
    "@nestjs/passport": "^10.0.2",
    "@nestjs/throttler": "^5.0.1",
    "@nestjs/websockets": "^10.3.0",
    "@nestjs/platform-socket.io": "^10.3.0",
    "@grpc/grpc-js": "^1.9.0",
    "@grpc/proto-loader": "^0.7.10",
    "kafkajs": "^2.2.4",
    "ioredis": "^5.3.2",
    "typeorm": "^0.3.17",
    "pg": "^8.11.3",
    "@clickhouse/client": "^0.2.5",
    "mongodb": "^6.3.0",
    "next": "14.0.4",
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "@tanstack/react-query": "^5.0.0",
    "zustand": "^4.4.0",
    "socket.io-client": "^4.7.0",
    "lightweight-charts": "^4.1.0",
    "tailwindcss": "3.3.6",
    "@headlessui/react": "^1.7.0",
    "@heroicons/react": "^2.0.0",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1",
    "rxjs": "^7.8.0",
    "axios": "^1.6.0",
    "ws": "^8.14.0",
    "uuid": "^9.0.0",
    "bcrypt": "^5.1.0",
    "jsonwebtoken": "^9.0.0",
    "passport": "^0.7.0",
    "passport-jwt": "^4.0.0",
    "helmet": "^7.1.0",
    "compression": "^1.7.0",
    "express-rate-limit": "^7.1.0",
    "winston": "^3.11.0",
    "joi": "^17.11.0",
    "lodash": "^4.17.21",
    "moment": "^2.29.0",
    "date-fns": "^2.30.0",
    "decimal.js": "^10.4.0",
    "bull": "^4.12.0",
    "node-cron": "^3.0.0"
  },
  "devDependencies": {
    "@nx/eslint": "17.2.8",
    "@nx/eslint-plugin": "17.2.8",
    "@nx/jest": "17.2.8",
    "@nx/js": "17.2.8",
    "@nx/nest": "17.2.8",
    "@nx/next": "17.2.8",
    "@nx/node": "17.2.8",
    "@nx/react": "17.2.8",
    "@nx/webpack": "17.2.8",
    "@nx/workspace": "17.2.8",
    "nx": "17.2.8",
    "@types/node": "^20.10.0",
    "@types/express": "^4.17.0",
    "@types/jest": "^29.4.0",
    "@types/bcrypt": "^5.0.0",
    "@types/jsonwebtoken": "^9.0.0",
    "@types/passport-jwt": "^3.0.0",
    "@types/uuid": "^9.0.0",
    "@types/lodash": "^4.14.0",
    "@types/ws": "^8.5.0",
    "@types/compression": "^1.7.0",
    "@types/pg": "^8.10.0",
    "@typescript-eslint/eslint-plugin": "^6.13.0",
    "@typescript-eslint/parser": "^6.13.0",
    "eslint": "^8.55.0",
    "eslint-config-prettier": "^9.0.0",
    "eslint-plugin-import": "^2.29.0",
    "eslint-plugin-jsx-a11y": "^6.8.0",
    "eslint-plugin-react": "^7.33.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-config-next": "14.0.4",
    "prettier": "^3.1.0",
    "typescript": "^5.3.0",
    "jest": "^29.4.0",
    "jest-environment-node": "^29.4.0",
    "@swc/core": "^1.3.0",
    "@swc/jest": "^0.2.0",
    "ts-jest": "^29.1.0",
    "ts-node": "^10.9.0",
    "husky": "^8.0.0",
    "lint-staged": "^15.2.0",
    "semantic-release": "^22.0.0",
    "conventional-changelog-cli": "^4.1.0",
    "cross-env": "^7.0.0",
    "rimraf": "^5.0.0",
    "concurrently": "^8.2.0",
    "wait-on": "^7.2.0"
  },
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,md,yaml,yml}": [
      "prettier --write"
    ]
  },
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "commit-msg": "conventional-changelog-lint"
    }
  }
}
```

### TypeScript Configuration

#### Base TypeScript Config (`tsconfig.base.json`)
```json
{
  "compileOnSave": false,
  "compilerOptions": {
    "rootDir": ".",
    "sourceMap": true,
    "declaration": false,
    "moduleResolution": "node",
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "importHelpers": true,
    "target": "ES2022",
    "module": "ESNext",
    "lib": ["ES2022", "DOM"],
    "skipLibCheck": true,
    "skipDefaultLibCheck": true,
    "strict": true,
    "noImplicitAny": true,
    "strictPropertyInitialization": false,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "incremental": true,
    "baseUrl": ".",
    "paths": {
      "@jts/shared/dto": ["libs/shared/dto/src/index.ts"],
      "@jts/shared/interfaces": ["libs/shared/interfaces/src/index.ts"],
      "@jts/shared/types": ["libs/shared/types/src/index.ts"],
      "@jts/shared/utils": ["libs/shared/utils/src/index.ts"],
      "@jts/shared/constants": ["libs/shared/constants/src/index.ts"],
      "@jts/shared/config": ["libs/shared/config/src/index.ts"],
      "@jts/domain/trading": ["libs/domain/trading/src/index.ts"],
      "@jts/domain/market-data": ["libs/domain/market-data/src/index.ts"],
      "@jts/domain/portfolio": ["libs/domain/portfolio/src/index.ts"],
      "@jts/domain/risk": ["libs/domain/risk/src/index.ts"],
      "@jts/domain/strategy": ["libs/domain/strategy/src/index.ts"],
      "@jts/infrastructure/database": ["libs/infrastructure/database/src/index.ts"],
      "@jts/infrastructure/messaging": ["libs/infrastructure/messaging/src/index.ts"],
      "@jts/infrastructure/http": ["libs/infrastructure/http/src/index.ts"],
      "@jts/infrastructure/logging": ["libs/infrastructure/logging/src/index.ts"],
      "@jts/infrastructure/monitoring": ["libs/infrastructure/monitoring/src/index.ts"],
      "@jts/brokers/creon": ["libs/brokers/creon/src/index.ts"],
      "@jts/brokers/kis": ["libs/brokers/kis/src/index.ts"],
      "@jts/brokers/binance": ["libs/brokers/binance/src/index.ts"],
      "@jts/brokers/upbit": ["libs/brokers/upbit/src/index.ts"]
    }
  },
  "exclude": ["node_modules", "tmp", "dist"]
}
```

### Shared Libraries Structure

#### Core Shared Libraries

**Shared DTOs Library** (`libs/shared/dto/src/index.ts`):
```typescript
export * from './lib/market-data.dto';
export * from './lib/order.dto';
export * from './lib/portfolio.dto';
export * from './lib/strategy.dto';
export * from './lib/risk.dto';
export * from './lib/auth.dto';
export * from './lib/common.dto';

// Example: Market Data DTO
export interface MarketDataDto {
  symbol: string;
  exchange: string;
  timestamp: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
  value: number;
  change: number;
  changePercent: number;
}

export interface OrderBookDto {
  symbol: string;
  exchange: string;
  timestamp: number;
  bids: Array<{ price: number; quantity: number; count: number }>;
  asks: Array<{ price: number; quantity: number; count: number }>;
}

export interface TradeDto {
  id: string;
  symbol: string;
  exchange: string;
  timestamp: number;
  price: number;
  quantity: number;
  side: 'buy' | 'sell';
  tradeType: 'market' | 'limit';
}
```

**Shared Interfaces Library** (`libs/shared/interfaces/src/index.ts`):
```typescript
export * from './lib/broker.interface';
export * from './lib/strategy.interface';
export * from './lib/market-data.interface';
export * from './lib/order.interface';
export * from './lib/portfolio.interface';
export * from './lib/risk.interface';

// Example: Broker Interface
export interface IBrokerService {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  isConnected(): boolean;
  
  // Market Data
  subscribeToMarketData(symbols: string[]): Promise<void>;
  unsubscribeFromMarketData(symbols: string[]): Promise<void>;
  getMarketData(symbol: string): Promise<MarketDataDto>;
  
  // Orders
  submitOrder(order: OrderDto): Promise<OrderResult>;
  cancelOrder(orderId: string): Promise<boolean>;
  getOrderStatus(orderId: string): Promise<OrderStatus>;
  
  // Account
  getAccountInfo(): Promise<AccountInfo>;
  getPositions(): Promise<Position[]>;
  getBalance(): Promise<Balance>;
}

export interface IStrategyEngine {
  executeStrategy(strategyId: string, marketData: MarketDataDto): Promise<SignalDto[]>;
  validateStrategy(strategy: StrategyDto): Promise<ValidationResult>;
  backtestStrategy(strategy: StrategyDto, period: DateRange): Promise<BacktestResult>;
}
```

**Shared Utilities Library** (`libs/shared/utils/src/index.ts`):
```typescript
export * from './lib/date.utils';
export * from './lib/math.utils';
export * from './lib/validation.utils';
export * from './lib/crypto.utils';
export * from './lib/format.utils';

// Example: Math Utilities
export class MathUtils {
  static calculateReturn(currentPrice: number, previousPrice: number): number {
    return (currentPrice - previousPrice) / previousPrice;
  }
  
  static calculateSMA(prices: number[], period: number): number[] {
    const sma: number[] = [];
    for (let i = period - 1; i < prices.length; i++) {
      const sum = prices.slice(i - period + 1, i + 1).reduce((acc, val) => acc + val, 0);
      sma.push(sum / period);
    }
    return sma;
  }
  
  static calculateEMA(prices: number[], period: number): number[] {
    const multiplier = 2 / (period + 1);
    const ema: number[] = [prices[0]];
    
    for (let i = 1; i < prices.length; i++) {
      ema.push((prices[i] - ema[i - 1]) * multiplier + ema[i - 1]);
    }
    return ema;
  }
  
  static calculateVolatility(returns: number[]): number {
    const mean = returns.reduce((acc, val) => acc + val, 0) / returns.length;
    const variance = returns.reduce((acc, val) => acc + Math.pow(val - mean, 2), 0) / returns.length;
    return Math.sqrt(variance);
  }
}
```

### Frontend Architecture

#### Overview

The JTS frontend follows a PWA-first strategy with progressive enhancement for desktop and mobile platforms. The architecture prioritizes real-time data visualization, responsive design, and offline capabilities critical for trading operations.

#### Platform Strategy

##### PWA Foundation (Primary)
- **Technology**: Next.js 14 with App Router
- **Deployment**: Single codebase for web, desktop PWA, and mobile PWA
- **Offline**: Service Workers for offline trading data access
- **Installation**: Installable on all platforms via browser

##### Desktop Enhancement (Optional)
- **Electron Wrapper**: For native OS integration and multi-window support
- **Features**: System tray, native notifications, global shortcuts
- **Auto-updates**: Electron-updater for seamless updates
- **Multi-monitor**: Support for detached trading panels

##### Mobile Native (Future)
- **React Native**: For performance-critical mobile experience
- **Code Sharing**: 70% shared code with PWA via monorepo structure
- **Native Features**: Biometric auth, push notifications
- **Platforms**: iOS 14+ and Android 8+

#### Frontend Application Structure

```
apps/web-app/
├── src/
│   ├── app/                      # Next.js App Router
│   │   ├── (auth)/               # Authentication routes
│   │   │   ├── login/
│   │   │   └── register/
│   │   ├── (trading)/            # Trading interface routes
│   │   │   ├── dashboard/
│   │   │   ├── orders/
│   │   │   ├── positions/
│   │   │   └── charts/
│   │   ├── (analytics)/          # Analytics routes
│   │   │   ├── reports/
│   │   │   ├── performance/
│   │   │   └── backtesting/
│   │   └── api/                  # API routes for BFF pattern
│   ├── features/                 # Feature-based modules
│   │   ├── trading/
│   │   │   ├── components/       # Trading UI components
│   │   │   │   ├── OrderEntry/
│   │   │   │   ├── OrderBook/
│   │   │   │   ├── PriceTicket/
│   │   │   │   └── TradeHistory/
│   │   │   ├── hooks/            # Custom React hooks
│   │   │   ├── utils/            # Trading utilities
│   │   │   └── types/            # TypeScript definitions
│   │   ├── portfolio/
│   │   │   ├── components/
│   │   │   │   ├── PositionList/
│   │   │   │   ├── BalanceCard/
│   │   │   │   └── PnLChart/
│   │   │   └── hooks/
│   │   ├── market-data/
│   │   │   ├── components/
│   │   │   │   ├── PriceChart/
│   │   │   │   ├── DepthChart/
│   │   │   │   └── HeatMap/
│   │   │   └── services/
│   │   └── strategies/
│   │       ├── components/
│   │       │   ├── StrategyBuilder/
│   │       │   ├── BacktestRunner/
│   │       │   └── PerformanceMetrics/
│   │       └── hooks/
│   ├── shared/
│   │   ├── components/           # Shared UI components
│   │   │   ├── layouts/
│   │   │   │   ├── TradingLayout/
│   │   │   │   ├── MobileLayout/
│   │   │   │   └── MultiPanelLayout/
│   │   │   ├── charts/           # Chart components
│   │   │   │   ├── CandlestickChart/
│   │   │   │   ├── LineChart/
│   │   │   │   └── VolumeChart/
│   │   │   ├── forms/            # Form components
│   │   │   │   ├── OrderForm/
│   │   │   │   ├── FilterForm/
│   │   │   │   └── SettingsForm/
│   │   │   └── ui/               # Base UI components
│   │   │       ├── Button/
│   │   │       ├── Modal/
│   │   │       ├── Table/
│   │   │       └── Toast/
│   │   ├── hooks/                # Global hooks
│   │   │   ├── useWebSocket/
│   │   │   ├── useAuth/
│   │   │   ├── useTheme/
│   │   │   └── useBreakpoint/
│   │   └── utils/                # Shared utilities
│   │       ├── formatters/
│   │       ├── validators/
│   │       └── calculations/
│   ├── stores/                   # Zustand state management
│   │   ├── market.store.ts       # Market data state
│   │   ├── portfolio.store.ts    # Portfolio state
│   │   ├── orders.store.ts       # Orders state
│   │   ├── strategy.store.ts     # Strategy state
│   │   └── ui.store.ts           # UI preferences
│   ├── services/                 # API and WebSocket services
│   │   ├── api/
│   │   │   ├── client.ts         # API client setup
│   │   │   ├── auth.service.ts
│   │   │   ├── trading.service.ts
│   │   │   └── market.service.ts
│   │   └── websocket/
│   │       ├── socket.manager.ts
│   │       ├── market.socket.ts
│   │       └── order.socket.ts
│   ├── styles/
│   │   ├── globals.css           # Global styles
│   │   ├── themes/               # Theme definitions
│   │   │   ├── light.css
│   │   │   └── dark.css
│   │   └── components/           # Component styles
│   └── workers/                  # Web Workers
│       ├── chart.worker.ts       # Chart calculations
│       ├── data.worker.ts        # Data processing
│       └── sync.worker.ts        # Background sync
├── public/
│   ├── manifest.json             # PWA manifest
│   ├── service-worker.js         # Service Worker
│   └── icons/                    # App icons
└── tests/
    ├── unit/                     # Unit tests
    ├── integration/              # Integration tests
    └── e2e/                      # E2E tests
```

#### State Management Architecture

##### Store Structure (Zustand)
```typescript
// Market Store
interface MarketStore {
  // State
  symbols: Map<string, Symbol>;
  orderBooks: Map<string, OrderBook>;
  trades: Map<string, Trade[]>;
  tickers: Map<string, Ticker>;
  
  // Actions
  subscribeSymbol: (symbol: string) => void;
  unsubscribeSymbol: (symbol: string) => void;
  updateOrderBook: (symbol: string, data: OrderBook) => void;
  addTrade: (symbol: string, trade: Trade) => void;
}

// Portfolio Store
interface PortfolioStore {
  // State
  positions: Position[];
  balance: Balance;
  openOrders: Order[];
  orderHistory: Order[];
  pnl: PnLData;
  
  // Actions
  refreshPortfolio: () => Promise<void>;
  updatePosition: (position: Position) => void;
  addOrder: (order: Order) => void;
  cancelOrder: (orderId: string) => Promise<void>;
}

// Real-time Sync Strategy
interface RealtimeSyncStrategy {
  // WebSocket connections
  marketDataSocket: Socket;
  orderStatusSocket: Socket;
  portfolioSocket: Socket;
  
  // Reconnection logic
  reconnectionStrategy: 'exponential-backoff';
  maxReconnectAttempts: 10;
  
  // Offline queue
  offlineQueue: {
    storage: 'IndexedDB';
    maxSize: 1000;
    syncOnReconnect: true;
  };
  
  // Conflict resolution
  conflictResolution: 'server-wins' | 'client-wins' | 'merge';
}
```

#### Component Architecture

##### Trading Components
```typescript
// Order Entry Component
interface OrderEntryProps {
  symbol: string;
  side: 'buy' | 'sell';
  orderType: 'market' | 'limit' | 'stop';
  onSubmit: (order: OrderRequest) => Promise<void>;
}

// Features:
// - Real-time price updates
// - Order validation
// - Risk checks
// - Keyboard shortcuts (Desktop)
// - Touch optimization (Mobile)

// Chart Component
interface ChartComponentProps {
  symbol: string;
  interval: '1m' | '5m' | '15m' | '1h' | '1d';
  indicators: Indicator[];
  drawings: Drawing[];
  onIntervalChange: (interval: string) => void;
}

// Features:
// - WebGL rendering for performance
// - Touch gestures for mobile
// - Drawing tools
// - Technical indicators
// - Real-time updates via WebSocket
```

#### Responsive Design Strategy

##### Breakpoints
```scss
// Breakpoint definitions
$mobile-small: 320px;   // Small phones
$mobile: 375px;         // Standard phones
$mobile-large: 414px;   // Large phones
$tablet: 768px;         // Tablets
$desktop: 1024px;       // Small desktop
$desktop-large: 1440px; // Standard desktop
$desktop-xl: 1920px;    // Large desktop
$trading-desk: 2560px;  // Multi-monitor setup

// Layout strategies
@media (max-width: $tablet - 1px) {
  // Mobile layout: Single column, stacked components
  // Simplified trading interface
  // Bottom navigation
  // Swipeable panels
}

@media (min-width: $tablet) and (max-width: $desktop - 1px) {
  // Tablet layout: 2-column grid
  // Collapsible sidebars
  // Modal-based forms
}

@media (min-width: $desktop) {
  // Desktop layout: Multi-panel dashboard
  // Persistent sidebars
  // Drag-and-drop panels
  // Keyboard navigation
}

@media (min-width: $trading-desk) {
  // Professional trading desk
  // Multi-monitor support
  // Detachable windows
  // Advanced charting
}
```

##### Mobile-First Components
```typescript
// Responsive component example
const TradingDashboard = () => {
  const breakpoint = useBreakpoint();
  const isMobile = breakpoint === 'mobile';
  const isTablet = breakpoint === 'tablet';
  const isDesktop = breakpoint === 'desktop';
  
  if (isMobile) {
    return <MobileTradingView />;  // Simplified, touch-optimized
  }
  
  if (isTablet) {
    return <TabletTradingView />;  // 2-column layout
  }
  
  return <DesktopTradingView />;   // Full dashboard
};
```

#### PWA Implementation

##### Service Worker Configuration
```javascript
// service-worker.js
const CACHE_NAME = 'jts-v1';
const STATIC_ASSETS = [
  '/',
  '/manifest.json',
  '/offline.html',
  // Critical CSS and JS
];

const DYNAMIC_CACHE = 'jts-dynamic-v1';
const MAX_DYNAMIC_AGE = 60 * 60 * 1000; // 1 hour

// Caching strategies
const CACHE_STRATEGIES = {
  '/api/market-data': 'network-first',  // Always try live data
  '/api/portfolio': 'network-first',    // Current positions
  '/api/historical': 'cache-first',     // Historical data
  '/static': 'cache-first',             // Static assets
};

// Background sync for orders
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-orders') {
    event.waitUntil(syncPendingOrders());
  }
});

// Push notifications
self.addEventListener('push', (event) => {
  const data = event.data.json();
  self.registration.showNotification(data.title, {
    body: data.body,
    icon: '/icons/icon-192.png',
    badge: '/icons/badge-72.png',
    data: data.clickAction,
  });
});
```

##### PWA Manifest
```json
{
  "name": "JTS Trading System",
  "short_name": "JTS",
  "description": "Professional Trading Platform",
  "start_url": "/dashboard",
  "display": "standalone",
  "orientation": "any",
  "theme_color": "#1a1a1a",
  "background_color": "#ffffff",
  "icons": [
    {
      "src": "/icons/icon-72.png",
      "sizes": "72x72",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "categories": ["finance", "business"],
  "shortcuts": [
    {
      "name": "New Order",
      "url": "/orders/new",
      "description": "Place a new order"
    },
    {
      "name": "Portfolio",
      "url": "/portfolio",
      "description": "View portfolio"
    }
  ]
}
```

#### Performance Requirements

##### Core Web Vitals Targets
- **LCP (Largest Contentful Paint)**: < 2.5s
- **FID (First Input Delay)**: < 100ms
- **CLS (Cumulative Layout Shift)**: < 0.1
- **Order Entry Latency**: < 50ms
- **Chart Update Rate**: 60fps minimum

##### Optimization Strategies
```typescript
// Code splitting by route
const TradingDashboard = lazy(() => import('./features/trading/Dashboard'));
const Portfolio = lazy(() => import('./features/portfolio/Portfolio'));
const Analytics = lazy(() => import('./features/analytics/Analytics'));

// Image optimization
import Image from 'next/image';

// React Query for data caching
const { data, isLoading } = useQuery({
  queryKey: ['portfolio'],
  queryFn: fetchPortfolio,
  staleTime: 5000,        // Consider stale after 5s
  cacheTime: 10 * 60000,  // Keep in cache for 10min
  refetchInterval: 5000,  // Refetch every 5s
});

// Virtual scrolling for large lists
import { FixedSizeList } from 'react-window';

// Web Workers for heavy calculations
const worker = new Worker('/workers/chart.worker.js');
worker.postMessage({ type: 'CALCULATE_INDICATORS', data: prices });
```

#### Security Considerations

##### Frontend Security
```typescript
// Secure storage
class SecureStorage {
  private encryptionKey: CryptoKey;
  
  async store(key: string, value: any): Promise<void> {
    const encrypted = await this.encrypt(JSON.stringify(value));
    localStorage.setItem(key, encrypted);
  }
  
  async retrieve(key: string): Promise<any> {
    const encrypted = localStorage.getItem(key);
    if (!encrypted) return null;
    const decrypted = await this.decrypt(encrypted);
    return JSON.parse(decrypted);
  }
}

// API Security
const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  withCredentials: true,
  headers: {
    'X-Requested-With': 'XMLHttpRequest',
  },
});

// CSRF Protection
apiClient.interceptors.request.use((config) => {
  const token = getCsrfToken();
  if (token) {
    config.headers['X-CSRF-Token'] = token;
  }
  return config;
});

// Input validation
const validateOrderInput = (order: OrderRequest): ValidationResult => {
  const errors: string[] = [];
  
  if (order.quantity <= 0) {
    errors.push('Quantity must be positive');
  }
  
  if (order.type === 'limit' && !order.price) {
    errors.push('Limit order requires price');
  }
  
  // Additional validation rules
  return { valid: errors.length === 0, errors };
};
```

#### Testing Strategy

##### Testing Pyramid
```typescript
// Unit Tests (70%)
describe('OrderEntry Component', () => {
  it('should validate order input', () => {
    const { getByRole, getByText } = render(<OrderEntry />);
    const submitButton = getByRole('button', { name: 'Submit Order' });
    
    fireEvent.click(submitButton);
    expect(getByText('Quantity is required')).toBeInTheDocument();
  });
});

// Integration Tests (20%)
describe('Trading Flow', () => {
  it('should place order and update portfolio', async () => {
    const { result } = renderHook(() => useTradingFlow());
    
    await act(async () => {
      await result.current.placeOrder(mockOrder);
    });
    
    expect(result.current.portfolio.openOrders).toContainEqual(
      expect.objectContaining({ id: mockOrder.id })
    );
  });
});

// E2E Tests (10%)
test('Complete trading workflow', async ({ page }) => {
  await page.goto('/dashboard');
  await page.click('[data-testid="new-order"]');
  await page.fill('[name="symbol"]', 'AAPL');
  await page.fill('[name="quantity"]', '100');
  await page.click('[type="submit"]');
  
  await expect(page.locator('.order-confirmation')).toBeVisible();
});
```

### Build and Testing Configuration

#### Jest Configuration (`jest.config.ts`)
```typescript
import { getJestProjects } from '@nx/jest';

export default {
  projects: getJestProjects(),
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'apps/**/*.ts',
    'libs/**/*.ts',
    '!**/*.spec.ts',
    '!**/*.e2e-spec.ts',
    '!**/node_modules/**',
    '!**/dist/**',
    '!**/*.d.ts',
    '!**/main.ts',
    '!**/test-setup.ts'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  testMatch: [
    '<rootDir>/{apps,libs}/**/*(*.)@(spec|test).[jt]s?(x)'
  ],
  transform: {
    '^.+\\.[jt]s$': ['@swc/jest', {
      jsc: {
        parser: {
          syntax: 'typescript',
          decorators: true
        },
        transform: {
          legacyDecorator: true,
          decoratorMetadata: true
        }
      }
    }]
  },
  moduleNameMapping: {
    '^@jts/(.*)$': '<rootDir>/libs/$1/src'
  },
  setupFilesAfterEnv: ['<rootDir>/tools/test-setup.ts'],
  testEnvironment: 'node',
  maxWorkers: '50%',
  verbose: true
};
```

#### ESLint Configuration (`.eslintrc.json`)
```json
{
  "root": true,
  "ignorePatterns": ["**/*"],
  "plugins": ["@nx"],
  "extends": [
    "@nx/eslint-plugin"
  ],
  "overrides": [
    {
      "files": ["*.ts", "*.tsx", "*.js", "*.jsx"],
      "extends": [
        "@typescript-eslint/recommended",
        "@typescript-eslint/recommended-requiring-type-checking",
        "prettier"
      ],
      "parserOptions": {
        "project": ["./tsconfig.*?.json"]
      },
      "rules": {
        "@nx/enforce-module-boundaries": [
          "error",
          {
            "enforceBuildableLibDependency": true,
            "allow": [],
            "depConstraints": [
              {
                "sourceTag": "scope:shared",
                "onlyDependOnLibsWithTags": ["scope:shared"]
              },
              {
                "sourceTag": "scope:domain",
                "onlyDependOnLibsWithTags": ["scope:shared", "scope:domain"]
              },
              {
                "sourceTag": "scope:infrastructure",
                "onlyDependOnLibsWithTags": ["scope:shared", "scope:domain", "scope:infrastructure"]
              },
              {
                "sourceTag": "scope:brokers",
                "onlyDependOnLibsWithTags": ["scope:shared", "scope:domain", "scope:infrastructure"]
              },
              {
                "sourceTag": "scope:apps",
                "onlyDependOnLibsWithTags": ["*"]
              }
            ]
          }
        ],
        "@typescript-eslint/no-unused-vars": "error",
        "@typescript-eslint/no-explicit-any": "warn",
        "@typescript-eslint/explicit-function-return-type": "warn",
        "@typescript-eslint/no-floating-promises": "error",
        "@typescript-eslint/await-thenable": "error",
        "@typescript-eslint/no-misused-promises": "error",
        "prefer-const": "error",
        "no-var": "error"
      }
    },
    {
      "files": ["*.spec.ts", "*.test.ts"],
      "rules": {
        "@typescript-eslint/no-explicit-any": "off",
        "@typescript-eslint/no-non-null-assertion": "off"
      }
    }
  ]
}
```

### Custom Nx Generators

#### Service Generator (`tools/generators/nestjs-service/index.ts`)
```typescript
import {
  Tree,
  formatFiles,
  installPackagesTask,
  names,
  offsetFromRoot,
  generateFiles,
  joinPathFragments,
} from '@nx/devkit';
import { applicationGenerator } from '@nx/nest';

interface Schema {
  name: string;
  tags?: string;
  directory?: string;
  unitTestRunner?: 'jest' | 'none';
  linter?: 'eslint' | 'tslint' | 'none';
  language?: 'js' | 'ts';
}

export default async function (tree: Tree, options: Schema) {
  const normalizedOptions = normalizeOptions(tree, options);
  
  // Generate NestJS application
  await applicationGenerator(tree, {
    name: normalizedOptions.projectName,
    directory: normalizedOptions.projectDirectory,
    tags: normalizedOptions.parsedTags.join(','),
    unitTestRunner: options.unitTestRunner || 'jest',
    linter: options.linter || 'eslint',
    language: options.language || 'ts',
  });

  // Add custom templates
  generateFiles(
    tree,
    joinPathFragments(__dirname, 'files'),
    normalizedOptions.projectRoot,
    {
      ...normalizedOptions,
      ...names(options.name),
      offsetFromRoot: offsetFromRoot(normalizedOptions.projectRoot),
      template: '',
    }
  );

  await formatFiles(tree);
  return () => {
    installPackagesTask(tree);
  };
}

function normalizeOptions(tree: Tree, options: Schema) {
  const name = names(options.name).fileName;
  const projectDirectory = options.directory ? `${names(options.directory).fileName}/${name}` : name;
  const projectName = projectDirectory.replace(new RegExp('/', 'g'), '-');
  const projectRoot = `apps/${projectDirectory}`;
  const parsedTags = options.tags ? options.tags.split(',').map((s) => s.trim()) : [];

  return {
    ...options,
    projectName,
    projectRoot,
    projectDirectory,
    parsedTags,
  };
}
```

### CI/CD Integration

#### GitHub Actions Workflow (`.github/workflows/ci.yml`)
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  NODE_VERSION: '20.x'
  NX_CLOUD_DISTRIBUTED_EXECUTION: true

jobs:
  setup:
    runs-on: ubuntu-latest
    outputs:
      has-affected-apps: ${{ steps.affected.outputs.has-affected-apps }}
      has-affected-libs: ${{ steps.affected.outputs.has-affected-libs }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci --prefer-offline

      - name: Check Affected
        id: affected
        run: |
          echo "has-affected-apps=$(npx nx print-affected --select=projects --type=app | grep -q '.' && echo 'true' || echo 'false')" >> $GITHUB_OUTPUT
          echo "has-affected-libs=$(npx nx print-affected --select=projects --type=lib | grep -q '.' && echo 'true' || echo 'false')" >> $GITHUB_OUTPUT

  lint:
    needs: setup
    runs-on: ubuntu-latest
    if: needs.setup.outputs.has-affected-apps == 'true' || needs.setup.outputs.has-affected-libs == 'true'
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci --prefer-offline

      - name: Lint Affected
        run: npx nx affected --target=lint --parallel=3

  type-check:
    needs: setup
    runs-on: ubuntu-latest
    if: needs.setup.outputs.has-affected-apps == 'true' || needs.setup.outputs.has-affected-libs == 'true'
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci --prefer-offline

      - name: Type Check Affected
        run: npx nx affected --target=type-check --parallel=3

  test:
    needs: setup
    runs-on: ubuntu-latest
    if: needs.setup.outputs.has-affected-apps == 'true' || needs.setup.outputs.has-affected-libs == 'true'
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci --prefer-offline

      - name: Test Affected
        run: npx nx affected --target=test --configuration=ci --parallel=3 --coverage

      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          directory: ./coverage
          fail_ci_if_error: false

  build:
    needs: [lint, type-check, test]
    runs-on: ubuntu-latest
    if: always() && (needs.lint.result == 'success' || needs.lint.result == 'skipped') && (needs.type-check.result == 'success' || needs.type-check.result == 'skipped') && (needs.test.result == 'success' || needs.test.result == 'skipped')
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci --prefer-offline

      - name: Build Affected
        run: npx nx affected --target=build --configuration=production --parallel=3

      - name: Upload Build Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: dist/
          retention-days: 1

  dependency-review:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Dependency Review
        uses: actions/dependency-review-action@v3
```

## Implementation Steps

1. **Workspace Initialization (2 hours)**
   - Initialize Nx workspace with NestJS preset
   - Configure basic TypeScript and ESLint settings
   - Set up base project structure

2. **Shared Libraries Setup (3 hours)**
   - Create shared DTOs, interfaces, and utilities libraries
   - Implement domain-specific libraries
   - Configure barrel exports and path mapping

3. **Build Configuration (2 hours)**
   - Configure Nx build targets and caching
   - Set up Jest testing configuration
   - Configure ESLint rules and dependency boundaries

4. **Application Structure (3 hours)**
   - Generate NestJS microservices applications
   - Create Next.js frontend application
   - Configure inter-service communication

5. **Development Tools (1 hour)**
   - Create custom Nx generators
   - Set up development scripts
   - Configure IDE integration

6. **CI/CD Integration (1 hour)**
   - Set up GitHub Actions workflows
   - Configure automated testing and building
   - Set up coverage reporting

## Dependencies

- **1002**: Development Environment Setup - Required for tooling and IDE configuration
- **1001**: Storage Infrastructure - Related for understanding data layer requirements

## Testing Plan

- Validate Nx workspace generation and configuration
- Test build processes with caching and affected builds
- Verify shared library imports and dependency boundaries
- Test custom generators and development scripts
- Validate CI/CD pipeline execution
- Test cross-platform compatibility

## Configuration Files Summary

Key configuration files created by this feature:
- `nx.json` - Nx workspace configuration
- `package.json` - Root package management
- `tsconfig.base.json` - TypeScript base configuration
- `.eslintrc.json` - ESLint configuration with Nx rules
- `jest.config.ts` - Jest testing configuration
- `tools/generators/` - Custom Nx generators
- `.github/workflows/ci.yml` - CI/CD pipeline

## Architecture References

For comprehensive system architecture and implementation details, see:
- `/architecture/INTEGRATED_ARCHITECTURE.md` - Complete integrated system architecture with DDD
- `/architecture/IMPLEMENTATION_ROADMAP.md` - Phase-based implementation strategy
- `/plan/jts_improved_architecture.md` - Rate limiter and PWA notification patterns
- `/plan/implementation-details.md` - Technical implementation specifics
- `/plan/jts_communication_architecture.md` - Service communication patterns
- `/plan/architecture-guide.md` - Architecture diagram guidelines

## Notes

- Focus on developer productivity through proper tooling
- Maintain strict dependency boundaries between layers
- Optimize build times with Nx caching and affected builds
- Ensure scalability for future microservices additions
- Consider Nx Cloud for distributed builds in larger teams
- Follow Domain-Driven Design principles for service boundaries
- Implement rate limiting at the broker service level
- Use event-driven architecture for scalability

## Status Updates

- **2025-08-24**: Feature specification created and documented
- **2025-08-27**: Integrated comprehensive architecture with DDD and layered design
- **2025-08-28**: Fixed architecture layer diagram - moved Market Data Collector and Notification Service to Business Layer, clarified Integration Layer as libraries only
- **2025-08-28**: Added comprehensive Frontend Architecture section with PWA-first strategy, detailed component structure, state management, and platform-specific implementations for desktop and mobile