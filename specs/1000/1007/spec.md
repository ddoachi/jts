---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '1007' # Numeric ID for stable reference
title: 'Service Communication Patterns'
type: 'feature' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '1000' # Parent spec ID
children: [] # Child spec IDs (if any)
epic: '1000' # Root epic ID for this work
domain: 'infrastructure' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low

# === TRACKING ===
created: '2025-08-24' # YYYY-MM-DD
updated: '2025-08-24' # YYYY-MM-DD
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 14 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: ['1005', '1006'] # Must be done before this (spec IDs) - Database and Message Queue infrastructure
blocks: ['2000', '3000', '4000', '5000', '6000'] # This blocks these specs (spec IDs) - Core service epics
related: ['1002', '1008'] # Related but not blocking (spec IDs) - Development environment and security

# === IMPLEMENTATION ===
branch: 'feature/1007-service-communication' # Git branch name
files: ['apps/api-gateway/', 'libs/shared/grpc/', 'libs/shared/websocket/', 'proto/', 'apps/*/src/grpc/', 'nginx.conf', 'docker-compose.yml'] # Key files to modify

# === METADATA ===
tags: ['grpc', 'rest', 'websocket', 'api-gateway', 'service-discovery', 'microservices', 'communication', 'protocols'] # Searchable tags
effort: 'large' # small | medium | large | epic
risk: 'medium' # low | medium | high

# ============================================================================
---

# Service Communication Patterns

## Overview

Establish comprehensive inter-service communication patterns for the JTS trading system, implementing gRPC for internal service-to-service communication, REST APIs for external interfaces, WebSocket connections for real-time market data streaming, service discovery mechanisms, and a centralized API gateway for routing and security. This foundation enables secure, scalable, and high-performance communication across all microservices in the trading platform.

## Acceptance Criteria

- [ ] **gRPC Infrastructure**: Complete gRPC setup with Protocol Buffers, service definitions, and client/server implementations for all internal services
- [ ] **REST API Framework**: Standardized REST API design with OpenAPI documentation, validation, and error handling patterns
- [ ] **WebSocket Real-time Streaming**: WebSocket server implementation for real-time market data, order status updates, and portfolio changes
- [ ] **API Gateway Configuration**: Centralized gateway with routing, authentication, rate limiting, load balancing, and protocol translation
- [ ] **Service Discovery**: Consul-based service registry with health checks, service registration, and dynamic discovery
- [ ] **Protocol Buffer Schemas**: Comprehensive .proto files defining all service interfaces and data structures
- [ ] **Authentication & Authorization**: JWT-based authentication with role-based access control across all communication patterns
- [ ] **Rate Limiting**: Configurable rate limiting policies for different client types and API endpoints
- [ ] **Load Balancing**: Round-robin and least-connections load balancing for gRPC services
- [ ] **Error Handling**: Standardized error responses, circuit breakers, and retry mechanisms
- [ ] **Monitoring Integration**: Request tracing, metrics collection, and logging for all communication patterns
- [ ] **Documentation**: Complete API documentation with examples and client SDK generation

## Technical Approach

### Communication Architecture Design

Design a multi-protocol communication system that optimizes for different use cases:
- **gRPC**: High-performance, type-safe internal service communication
- **REST**: Standards-based external APIs for web clients and third-party integrations
- **WebSocket**: Real-time bidirectional communication for live data streaming
- **Service Discovery**: Dynamic service location and health monitoring

#### JTS Communication Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Client Layer                             │
├─────────────────┬─────────────────┬────────────────────────────┤
│   Web Client    │   Mobile App    │   External APIs/Partners   │
│   (WebSocket +  │   (REST + WS)   │        (REST API)          │
│    REST API)    │                 │                            │
└─────────────────┴─────────────────┴────────────────────────────┘
                             │
┌──────────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                          │
│  ┌─────────────┬─────────────────┬──────────────────────────┐   │
│  │   Nginx     │   Rate Limiting │    Authentication        │   │
│  │ Load Balancer│   & Throttling  │    & Authorization       │   │
│  └─────────────┴─────────────────┴──────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
                             │
┌──────────────────────────────────────────────────────────────────┐
│                   Service Discovery Layer                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │             Consul Service Registry                         │ │
│  │  ┌──────────────┬──────────────┬──────────────────────────┐ │ │
│  │  │    Health    │   Service    │     Configuration        │ │ │
│  │  │   Checks     │  Registry    │      Management          │ │ │
│  │  └──────────────┴──────────────┴──────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
                             │
┌──────────────────────────────────────────────────────────────────┐
│                    Business Service Layer                       │
│  ┌─────────────┬─────────────┬─────────────┬─────────────────┐   │
│  │  Strategy   │    Risk     │ Portfolio   │      Order      │   │
│  │   Engine    │ Management  │  Tracker    │   Execution     │   │
│  │  (gRPC +    │ (gRPC +     │(gRPC +      │   (gRPC +       │   │
│  │ WebSocket)  │ WebSocket)  │WebSocket)   │  WebSocket)     │   │
│  └─────────────┴─────────────┴─────────────┴─────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
                             │
┌──────────────────────────────────────────────────────────────────┐
│                Integration & Data Layer                          │
│  ┌─────────────────────────────┬────────────────────────────────┐ │
│  │   Market Data Collector     │    Notification Service        │ │
│  │      (gRPC + Kafka)         │      (WebSocket + gRPC)        │ │
│  └─────────────────────────────┴────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

#### Protocol Selection Strategy
- **gRPC**: Internal service communication requiring high performance, type safety, and streaming
- **REST**: External APIs, admin interfaces, and third-party integrations
- **WebSocket**: Real-time data streaming for market prices, order updates, and notifications
- **Kafka**: Asynchronous event streaming for decoupled service communication

### Key Components

1. **gRPC Service Infrastructure**
   - Protocol Buffer schema definitions for all service interfaces
   - Generated client and server stubs for TypeScript/Node.js
   - gRPC interceptors for authentication, logging, and metrics
   - Connection pooling and load balancing for gRPC clients
   - Streaming support for real-time data flows

   **Protocol Buffer Schema Example:**
   ```protobuf
   // proto/trading.proto
   syntax = "proto3";
   
   package jts.trading;
   
   service StrategyEngineService {
     rpc CreateStrategy(CreateStrategyRequest) returns (CreateStrategyResponse);
     rpc ExecuteStrategy(ExecuteStrategyRequest) returns (stream ExecutionUpdate);
     rpc GetStrategyStatus(GetStrategyStatusRequest) returns (StrategyStatus);
     rpc ListStrategies(ListStrategiesRequest) returns (ListStrategiesResponse);
   }
   
   message CreateStrategyRequest {
     string name = 1;
     string description = 2;
     StrategyType type = 3;
     StrategyConfig config = 4;
     RiskParameters risk_params = 5;
   }
   
   message ExecutionUpdate {
     string strategy_id = 1;
     ExecutionStatus status = 2;
     repeated Order orders = 3;
     Performance performance = 4;
     int64 timestamp = 5;
   }
   
   enum StrategyType {
     STRATEGY_TYPE_UNSPECIFIED = 0;
     STRATEGY_TYPE_MOMENTUM = 1;
     STRATEGY_TYPE_MEAN_REVERSION = 2;
     STRATEGY_TYPE_ARBITRAGE = 3;
   }
   ```

2. **REST API Framework with NestJS**
   - OpenAPI (Swagger) documentation generation
   - Request validation with class-validator
   - Standardized error handling and response formatting
   - API versioning strategy with backward compatibility
   - Comprehensive endpoint testing with automated tests

   **REST Controller Example:**
   ```typescript
   // apps/api-gateway/src/controllers/strategy.controller.ts
   import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
   import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
   import { JwtAuthGuard } from '../guards/jwt-auth.guard';
   import { RoleGuard } from '../guards/role.guard';
   import { Roles } from '../decorators/roles.decorator';
   
   @ApiTags('strategies')
   @ApiBearerAuth()
   @UseGuards(JwtAuthGuard, RoleGuard)
   @Controller('api/v1/strategies')
   export class StrategyController {
     constructor(private readonly strategyService: StrategyService) {}
   
     @Post()
     @Roles('trader', 'admin')
     @ApiOperation({ summary: 'Create a new trading strategy' })
     @ApiResponse({ status: 201, description: 'Strategy created successfully', type: StrategyDto })
     @ApiResponse({ status: 400, description: 'Invalid strategy configuration' })
     async createStrategy(@Body() createStrategyDto: CreateStrategyDto): Promise<StrategyDto> {
       return this.strategyService.create(createStrategyDto);
     }
   
     @Get(':id/performance')
     @Roles('trader', 'admin', 'viewer')
     @ApiOperation({ summary: 'Get strategy performance metrics' })
     async getStrategyPerformance(@Param('id') strategyId: string): Promise<PerformanceDto> {
       return this.strategyService.getPerformance(strategyId);
     }
   }
   ```

3. **WebSocket Real-time Communication**
   - Socket.IO integration for reliable real-time communication
   - Room-based subscription management for different data types
   - Authentication and authorization for WebSocket connections
   - Message queuing and delivery guarantees
   - Automatic reconnection and backoff strategies

   **WebSocket Gateway Example:**
   ```typescript
   // libs/shared/websocket/src/market-data.gateway.ts
   import {
     WebSocketGateway,
     WebSocketServer,
     SubscribeMessage,
     OnGatewayConnection,
     OnGatewayDisconnect,
   } from '@nestjs/websockets';
   import { Server, Socket } from 'socket.io';
   import { UseGuards } from '@nestjs/common';
   import { WsJwtGuard } from './guards/ws-jwt.guard';
   
   @WebSocketGateway({
     namespace: '/market-data',
     cors: { origin: process.env.FRONTEND_URL },
   })
   @UseGuards(WsJwtGuard)
   export class MarketDataGateway implements OnGatewayConnection, OnGatewayDisconnect {
     @WebSocketServer()
     server: Server;
   
     handleConnection(client: Socket) {
       console.log(`Client connected: ${client.id}`);
     }
   
     handleDisconnect(client: Socket) {
       console.log(`Client disconnected: ${client.id}`);
     }
   
     @SubscribeMessage('subscribe-ticker')
     handleSubscribeTicker(client: Socket, symbol: string) {
       client.join(`ticker-${symbol}`);
       return { event: 'subscription-confirmed', data: { symbol } };
     }
   
     @SubscribeMessage('subscribe-orders')
     handleSubscribeOrders(client: Socket, userId: string) {
       client.join(`orders-${userId}`);
       return { event: 'subscription-confirmed', data: { type: 'orders' } };
     }
   
     // Broadcast market data to subscribers
     broadcastTicker(symbol: string, data: TickerData) {
       this.server.to(`ticker-${symbol}`).emit('ticker-update', data);
     }
   
     // Broadcast order updates to specific user
     broadcastOrderUpdate(userId: string, orderUpdate: OrderUpdate) {
       this.server.to(`orders-${userId}`).emit('order-update', orderUpdate);
     }
   }
   ```

4. **API Gateway with Nginx and NestJS**
   - Nginx as reverse proxy with load balancing
   - NestJS gateway service for business logic routing
   - JWT authentication middleware
   - Rate limiting with Redis backend
   - Request/response transformation and validation

   **Nginx Configuration:**
   ```nginx
   # nginx.conf
   upstream api_gateway {
       least_conn;
       server api-gateway-1:3000;
       server api-gateway-2:3000;
       server api-gateway-3:3000;
   }
   
   upstream websocket_gateway {
       ip_hash;  # Sticky sessions for WebSocket
       server websocket-1:3001;
       server websocket-2:3001;
   }
   
   server {
       listen 80;
       server_name api.jts.local;
   
       # Rate limiting
       limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;
       limit_req_zone $binary_remote_addr zone=ws:10m rate=50r/m;
   
       # REST API endpoints
       location /api/ {
           limit_req zone=api burst=20 nodelay;
           proxy_pass http://api_gateway;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   
       # WebSocket endpoints
       location /socket.io/ {
           limit_req zone=ws burst=10 nodelay;
           proxy_pass http://websocket_gateway;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   
       # Health check endpoint
       location /health {
           access_log off;
           proxy_pass http://api_gateway/health;
       }
   }
   ```

5. **Service Discovery with Consul**
   - Consul agent configuration for service registration
   - Health check endpoints for all services
   - Service discovery client library
   - Dynamic configuration management
   - Load balancing integration

   **Consul Service Configuration:**
   ```json
   // consul/services/strategy-engine.json
   {
     "service": {
       "id": "strategy-engine-1",
       "name": "strategy-engine",
       "tags": ["trading", "v1"],
       "address": "strategy-engine-1",
       "port": 50051,
       "check": {
         "grpc": "strategy-engine-1:50051",
         "interval": "10s",
         "timeout": "3s"
       },
       "meta": {
         "version": "1.0.0",
         "protocol": "grpc",
         "environment": "production"
       }
     }
   }
   ```

### Implementation Steps

1. **Protocol Buffer Schema Design (Day 1-2)**
   ```bash
   # Create proto directory structure
   mkdir -p proto/{trading,market-data,portfolio,risk,orders}
   
   # Define core service interfaces
   # trading.proto - Strategy engine interfaces
   # market-data.proto - Market data streaming
   # portfolio.proto - Portfolio management
   # risk.proto - Risk management services
   # orders.proto - Order execution services
   
   # Generate TypeScript definitions
   npm install @grpc/grpc-js @grpc/proto-loader
   npm install -D grpc-tools @types/google-protobuf
   
   # Create generation script
   cat > scripts/generate-grpc.sh << 'EOF'
   #!/bin/bash
   PROTO_DIR="./proto"
   OUT_DIR="./libs/shared/grpc/src/generated"
   
   mkdir -p "$OUT_DIR"
   
   # Generate TypeScript definitions
   for proto_file in $(find "$PROTO_DIR" -name "*.proto"); do
       protoc \
           --plugin=protoc-gen-ts=./node_modules/.bin/protoc-gen-ts \
           --ts_out=grpc_js:"$OUT_DIR" \
           --js_out=import_style=commonjs:"$OUT_DIR" \
           --grpc_out=grpc_js:"$OUT_DIR" \
           -I "$PROTO_DIR" \
           "$proto_file"
   done
   EOF
   
   chmod +x scripts/generate-grpc.sh
   ```

2. **gRPC Service Infrastructure Setup (Day 3-4)**
   ```bash
   # Create gRPC shared library
   nx g @nrwl/workspace:lib shared/grpc
   
   # Install gRPC dependencies
   npm install @grpc/grpc-js @grpc/proto-loader
   npm install @nestjs/microservices
   
   # Create gRPC client factory
   # libs/shared/grpc/src/client-factory.ts
   # libs/shared/grpc/src/interceptors/
   # libs/shared/grpc/src/decorators/
   
   # Configure each service to support gRPC
   # Add gRPC transport to main.ts in each service
   # Implement service controllers with gRPC decorators
   ```

3. **REST API Framework Implementation (Day 5-6)**
   ```bash
   # Set up API Gateway service
   nx g @nestjs/schematics:app api-gateway
   
   # Install required dependencies
   npm install @nestjs/swagger class-validator class-transformer
   npm install @nestjs/throttler @nestjs/jwt @nestjs/passport passport-jwt
   
   # Create API structure
   # apps/api-gateway/src/controllers/
   # apps/api-gateway/src/services/
   # apps/api-gateway/src/guards/
   # apps/api-gateway/src/interceptors/
   # apps/api-gateway/src/middleware/
   
   # Configure OpenAPI documentation
   # Set up validation pipes and error handling
   # Implement JWT authentication guards
   ```

4. **WebSocket Gateway Development (Day 7-8)**
   ```bash
   # Create WebSocket shared library
   nx g @nrwl/workspace:lib shared/websocket
   
   # Install Socket.IO dependencies
   npm install @nestjs/websockets @nestjs/platform-socket.io socket.io
   npm install -D @types/socket.io
   
   # Create WebSocket gateways
   # libs/shared/websocket/src/gateways/market-data.gateway.ts
   # libs/shared/websocket/src/gateways/orders.gateway.ts
   # libs/shared/websocket/src/gateways/notifications.gateway.ts
   
   # Implement authentication for WebSocket connections
   # Set up room-based subscription management
   # Create message queuing for reliable delivery
   ```

5. **Service Discovery Integration (Day 9-10)**
   ```bash
   # Install Consul client
   npm install consul @types/consul
   
   # Create service registry library
   nx g @nrwl/workspace:lib shared/service-discovery
   
   # Implement Consul integration
   # libs/shared/service-discovery/src/consul-client.ts
   # libs/shared/service-discovery/src/service-registry.ts
   # libs/shared/service-discovery/src/health-check.service.ts
   
   # Configure service registration on startup
   # Implement health check endpoints
   # Set up service discovery for gRPC clients
   ```

6. **API Gateway Configuration (Day 11-12)**
   ```bash
   # Configure Nginx as reverse proxy
   # Create nginx.conf with load balancing rules
   # Set up SSL termination and security headers
   
   # Implement API Gateway service
   # Create routing middleware for different service endpoints
   # Set up rate limiting with Redis
   # Configure CORS and security policies
   
   # Create Docker Compose configuration
   # Include Nginx, API Gateway, and service discovery
   ```

7. **Authentication & Authorization (Day 13-14)**
   ```bash
   # Implement JWT authentication service
   # Create role-based access control
   # Set up OAuth2/OpenID Connect integration
   
   # Configure authentication for all communication patterns:
   # - JWT middleware for REST APIs
   # - gRPC interceptors for service-to-service auth
   # - WebSocket authentication on connection
   
   # Create authorization policies and guards
   # Implement token refresh and session management
   ```

## Dependencies

- **1005 - Database Infrastructure**: Required for storing authentication tokens, rate limiting data, and service configuration
- **1006 - Message Queue Infrastructure**: Required for asynchronous communication patterns and event streaming

## Testing Plan

- **gRPC Service Testing**: Unit tests for all gRPC service methods with mock clients and servers
- **REST API Testing**: Comprehensive endpoint testing with authentication, validation, and error scenarios
- **WebSocket Testing**: Connection, subscription, and message delivery testing with multiple clients
- **API Gateway Testing**: Load balancing, rate limiting, and routing functionality validation
- **Service Discovery Testing**: Service registration, health checks, and failover scenarios
- **Authentication Testing**: JWT token validation, role-based access control, and session management
- **Integration Testing**: End-to-end communication flow testing across all protocols
- **Performance Testing**: Load testing for concurrent connections and message throughput
- **Security Testing**: Authentication bypass attempts, rate limit testing, and input validation
- **Resilience Testing**: Circuit breaker functionality, retry mechanisms, and error handling

## Claude Code Instructions

```
When implementing this service communication infrastructure:

PROTOCOL BUFFER SETUP:
1. Design comprehensive .proto files for all service interfaces
2. Use consistent naming conventions and versioning strategy
3. Generate TypeScript definitions with proper typing
4. Create shared message types for common data structures
5. Implement proper error handling in gRPC services

GRPC IMPLEMENTATION:
1. Set up gRPC servers in all NestJS microservices
2. Create gRPC client factory with connection pooling
3. Implement interceptors for authentication, logging, and metrics
4. Use streaming for real-time data flows
5. Configure load balancing for gRPC client connections

REST API DEVELOPMENT:
1. Follow OpenAPI 3.0 specification for all endpoints
2. Implement comprehensive input validation with class-validator
3. Create standardized error response format
4. Use proper HTTP status codes and headers
5. Generate client SDKs from OpenAPI specifications

WEBSOCKET CONFIGURATION:
1. Set up Socket.IO with namespace organization
2. Implement room-based subscription management
3. Create authentication middleware for WebSocket connections
4. Handle connection failures with automatic reconnection
5. Implement message acknowledgment and delivery guarantees

API GATEWAY SETUP:
1. Configure Nginx with proper upstream definitions
2. Implement rate limiting with Redis backend
3. Set up SSL termination and security headers
4. Create health check endpoints for load balancer
5. Configure CORS policies for web client access

SERVICE DISCOVERY:
1. Set up Consul cluster with proper configuration
2. Implement service registration on application startup
3. Create health check endpoints for all services
4. Configure service discovery for gRPC clients
5. Implement failover and load balancing strategies

SECURITY IMPLEMENTATION:
1. Use JWT tokens with proper expiration and refresh
2. Implement role-based access control (RBAC)
3. Create authentication guards for all endpoints
4. Set up HTTPS/TLS for all external communication
5. Implement proper input sanitization and validation

ERROR HANDLING:
1. Create standardized error response format
2. Implement circuit breakers for external service calls
3. Add retry logic with exponential backoff
4. Create proper logging for debugging and monitoring
5. Handle graceful degradation when services are unavailable

MONITORING INTEGRATION:
1. Add request ID correlation across all services
2. Implement distributed tracing with OpenTelemetry
3. Create metrics for request rates, latency, and errors
4. Set up health check endpoints for monitoring systems
5. Log structured data for centralized log aggregation
```

## Notes

- **PERFORMANCE**: gRPC provides significant performance benefits for internal service communication
- **SCALABILITY**: Service discovery enables dynamic scaling and load distribution
- **SECURITY**: Multi-layer authentication ensures secure communication across all protocols
- **MONITORING**: Comprehensive request tracing and metrics collection for operational visibility
- **RELIABILITY**: Circuit breakers and retry mechanisms provide resilience against service failures
- **MAINTAINABILITY**: Protocol Buffers provide type safety and versioning for API evolution
- **FLEXIBILITY**: Multiple communication patterns support different client requirements

## Status Updates

- **2025-08-24**: Feature specification created with comprehensive implementation plan