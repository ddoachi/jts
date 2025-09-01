# JTS Nx Monorepo

## Overview

This is an Nx-powered monorepo for the JTS (Joohan Trading System) platform, using NestJS for microservices and TypeScript throughout.

## Workspace Structure

```
jts/
├── apps/           # Microservices and applications
├── libs/           # Shared libraries
├── tools/          # Build tools and scripts
│   ├── generators/ # Custom Nx generators
│   ├── executors/  # Custom Nx executors
│   └── scripts/    # Utility scripts
├── configs/        # Configuration files
├── docs/           # Documentation
├── nx.json         # Nx configuration
├── package.json    # Root package.json
├── tsconfig.base.json # Base TypeScript config
└── .gitignore      # Git ignore rules
```

## Quick Start

### Prerequisites
- Node.js >= 20.0.0
- npm or yarn

### Installation
```bash
npm install
```

### Running Commands

#### List available plugins
```bash
npx nx list
```

#### View dependency graph
```bash
npx nx graph
```

#### Format check
```bash
npx nx format:check
```

#### Reset cache
```bash
npx nx reset
```

## Development

### Creating new applications
```bash
npx nx g @nx/nest:application <app-name>
```

### Creating new libraries
```bash
npx nx g @nx/nest:library <lib-name>
```

### Running services
```bash
npx nx serve <app-name>
```

### Building services
```bash
npx nx build <app-name>
```

### Testing
```bash
npx nx test <project-name>
npx nx e2e <project-name>
```

## Configuration

### Task Runner Options
- Parallel execution: 4 processes by default
- Max parallel: 6 processes
- Cacheable operations: build, lint, test, e2e

### Target Defaults
- Build depends on dependencies being built first
- All targets are cached for performance

## NestJS Integration

This workspace is configured with NestJS presets for building microservices:
- @nestjs/common: ^10.3.0
- @nestjs/core: ^10.3.0
- @nestjs/platform-express: ^10.3.0
- rxjs: ^7.8.0
- reflect-metadata: ^0.1.13

## TypeScript Configuration

Base TypeScript configuration includes:
- Target: ES2022
- Strict mode enabled
- Decorator support for NestJS
- Module resolution: node
- Source maps enabled