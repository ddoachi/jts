---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: 08f90c1a # Unique identifier (never changes)
title: Multi-Broker Integration Layer
type: epic

# === HIERARCHY ===
parent: ''
children:
  - "[F01](./F01/spec.md)"
  - "[F02](./F02/spec.md)"
  - "[F03](./F03/spec.md)"
  - "[F04](./F04/spec.md)"
  - "[F05](./F05/spec.md)"
  - "[F06](./F06/spec.md)"
  - "[F07](./F07/spec.md)"
  - "[F08](./F08/spec.md)"
  - "[F09](./F09/spec.md)"
  - "[F10](./F10/spec.md)"
  - "[F11](./F11/spec.md)"
epic: E02
domain: broker-integration

# === WORKFLOW ===
status: draft
priority: high

# === TRACKING ===
created: '2025-08-24'
updated: '2025-08-26'
due_date: ''
estimated_hours: 340
actual_hours: 0

# === DEPENDENCIES ===
dependencies:
  - "[E01](../E01/spec.md)"
blocks:
  - "[E04](../E04/spec.md)"
  - "[E05](../E05/spec.md)"
  - "[E06](../E06/spec.md)"
related:
  - "[E03](../E03/spec.md)"
branch: ''
files:
  - apps/brokers/
  - libs/shared/interfaces/broker.interface.ts

# === METADATA ===
tags:
  - broker
  - integration
  - kis
  - creon
  - api
  - rate-limiting
effort: epic
risk: high
---

# Multi-Broker Integration Layer

## Overview

Implement a unified broker integration layer that provides seamless connectivity to multiple Korean stock brokers (KIS, Creon) and cryptocurrency exchanges (Binance, Upbit). This epic establishes the abstraction layer for broker-agnostic trading operations, intelligent rate limiting, and multi-account management capabilities.

## Feature Breakdown

This epic has been decomposed into 11 features totaling 340 hours of estimated effort:

| ID  | Feature                             | Hours | Priority |
| --- | ----------------------------------- | ----- | -------- |
| F01 | Unified Broker Interface Foundation | 25    | Critical |
| F02 | KIS REST API Integration            | 40    | High     |
| F03 | KIS WebSocket Real-time Data        | 30    | High     |
| F04 | Creon Windows COM Integration       | 35    | High     |
| F05 | Distributed Rate Limiting System    | 30    | Critical |
| F06 | Multi-Account Pool Management       | 35    | Medium   |
| F07 | Smart Order Routing Engine          | 35    | Medium   |
| F08 | Standardized Service Endpoints      | 25    | Medium   |
| F09 | Error Handling & Recovery           | 30    | High     |
| F10 | Broker Testing & Mock Services      | 25    | Low      |
| F11 | Broker Monitoring & Observability   | 30    | Medium   |

## Mobile-Friendly Dependency Flow

```
┌─────────────────────┐
│    Epic E01        │
│   Foundation        │
│  Infrastructure     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│    Epic E02        │
│  BROKER INTEGRATION │ ◄── You are here
│    (340 hours)      │
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    ▼             ▼
┌────────┐  ┌────────┐
│ Epic   │  │ Epic   │
│ E03   │  │ E10  │
│ Market │  │ Crypto │
│ Data   │  │        │
└───┬────┘  └────────┘
    │
    ▼
┌────────────────────┐
│    Epic E04       │
│ Trading Strategy   │
│     Engine         │
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│    Epic E05       │
│ Risk Management    │
│     System         │
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│    Epic E06       │
│ Order Execution    │
│   & Portfolio      │
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│    Epic E07       │
│   User Interface   │
│    & Dashboard     │
└────────────────────┘

Parallel Tracks:
├── Epic E08: Monitoring
├── Epic E09: Backtesting
├── Epic E11: Performance
└── Epic E12: DevOps
```

## Feature Dependencies Within Epic

### Implementation Phases

**Phase 1: Foundation (25 hrs)**

- F01: Unified Broker Interface ── Must complete first

**Phase 2: Core Integrations (105 hrs)**

- F02: KIS REST API ────────────┐
- F04: Creon COM Integration ───┼── Can run in parallel
- F05: Rate Limiting System ────┘

**Phase 3: Advanced Features (95 hrs)**

- F03: KIS WebSocket ───────────┐
- F06: Account Pool Management ─┼── Can run in parallel
- F10: Testing & Mocks ─────────┘

**Phase 4: Routing & Standards (60 hrs)**

- F07: Smart Order Routing ─────┐
- F08: Standard Endpoints ──────┴── Sequential

**Phase 5: Operations (60 hrs)**

- F09: Error Handling ──────────┐
- F11: Monitoring ──────────────┴── Can run in parallel

### Critical Path

```
F01 → F02 → F05 → F06 → F07 → F08
     ↘ F04 ↗
```

## Acceptance Criteria

- [ ] Unified IBroker interface implemented and documented
- [ ] KIS service fully integrated with REST API support
- [ ] Creon service operational on Windows with COM object wrapper
- [ ] Rate limiting system prevents API violations across all brokers
- [ ] Multi-account pool management distributes load effectively
- [ ] Smart order routing selects optimal broker for execution
- [ ] All broker services expose standardized REST/gRPC endpoints
- [ ] Comprehensive error handling and retry mechanisms in place
- [ ] Real-time connection monitoring and failover capability
- [ ] Mock broker service available for testing

## Technical Approach

### Unified Broker Architecture

Create a broker-agnostic interface that standardizes all broker operations, allowing the system to interact with any broker through the same API. Implement adapter pattern for each specific broker integration.

### Key Components

1. **Unified Broker Interface**
   - Common data models (Order, Position, Balance)
   - Standardized API methods
   - Error code normalization
   - Response transformation layer

2. **KIS Service (Linux/Windows)**
   - REST API integration (337 APIs available)
   - OAuth 2.0 authentication with 24-hour token validity
   - WebSocket for real-time data (40 symbols per connection)
   - Multi-account support
   - Rate limits: 20 req/sec, 1,000 req/min
   - Reference: `brokers/kis/KIS_API_SPEC.md` for API details
   - Full spec: `brokers/kis/reference/KIS_API_20250817_030000.xlsx`

3. **Creon Service (Windows)**
   - FastAPI wrapper for COM objects
   - Dedicated Windows PC (no containers/VMs due to Creon restrictions)
   - Rate limit: 15 requests/60 seconds
   - Session management

4. **Rate Limiting System**
   - Distributed rate limiter using Redis
   - Priority queue for critical operations
   - Sliding window algorithm
   - Exponential backoff on violations

5. **Account Pool Management**
   - Dynamic account allocation
   - Symbol distribution strategy
   - Balance aggregation
   - Load balancing across accounts

### Implementation Steps

1. **Define Broker Interface**
   - Create IBroker TypeScript interface
   - Define common DTOs
   - Establish error handling patterns
   - Document API contracts

2. **Implement KIS Service**
   - Set up NestJS service
   - Integrate KIS REST APIs (see `brokers/kis/KIS_API_SPEC.md`)
   - Implement OAuth2 authentication flow with hashkey generation
   - Add WebSocket support for real-time data
   - Handle rate limiting (20/sec, 1,000/min)
   - Support both production and sandbox environments

3. **Implement Creon Service**
   - Create FastAPI Python service
   - Wrap Creon COM objects
   - Deploy on dedicated Windows PC (bare metal)
   - Expose REST endpoints for network access

4. **Build Rate Limiting**
   - Implement Redis-based limiter
   - Create priority queue system
   - Add request batching
   - Monitor rate limit status

5. **Create Account Pool**
   - Design account management system
   - Implement symbol distribution
   - Add failover mechanisms
   - Build account selection logic

6. **Develop Smart Router**
   - Create routing decision engine
   - Implement broker selection algorithm
   - Add execution quality tracking
   - Build fallback strategies

## API Resources

### KIS (Korea Investment Securities)

- **API Documentation**: `brokers/kis/KIS_API_SPEC.md`
- **Complete Specification**: `brokers/kis/reference/KIS_API_20250817_030000.xlsx`
- **Total APIs**: 337 endpoints
- **Categories**: Stocks, Futures, Options, International Markets, WebSocket
- **Rate Limits**: 20 req/sec, 1,000 req/min, 50,000 req/hour
- **Environments**:
  - Production: `https://openapi.koreainvestment.com:9443`
  - Sandbox: `https://openapivts.koreainvestment.com:29443`
  - WebSocket: `ws://ops.koreainvestment.com:21000` (prod) / `:31000` (sandbox)

### Creon

- **Platform**: Windows-only (COM objects)
- **Rate Limits**: 15 requests per 60 seconds
- **Deployment**: Dedicated Windows PC (bare metal)

## Dependencies

- **[E01](../E01/spec.md)**: Foundation & Infrastructure Setup - Requires monorepo structure, Redis, and Docker infrastructure

## Testing Plan

- Unit tests for each broker adapter
- Integration tests with broker sandbox environments
- Rate limiting stress tests
- Multi-account coordination tests
- Failover scenario testing
- Mock broker for development testing

## Claude Code Instructions

```
When implementing this epic:
1. Start with the IBroker interface in libs/shared/interfaces/
2. Use NestJS for Linux-based broker services (KIS, Binance, Upbit)
3. For KIS implementation, refer to:
   - API documentation: brokers/kis/KIS_API_SPEC.md
   - Complete Excel spec: brokers/kis/reference/KIS_API_20250817_030000.xlsx
   - 337 APIs available with detailed request/response formats
4. Use FastAPI for Creon service on dedicated Windows PC (bare metal, not containerized)
5. Configure secure network communication between Creon PC and main system
6. Implement comprehensive logging for all broker interactions
7. Create a broker-mock service for testing without real APIs
8. Use environment variables for all API credentials
9. Implement circuit breaker pattern for broker connections
10. Create detailed documentation for each broker's quirks
11. Set up monitoring dashboards for rate limit usage
12. Ensure Creon PC has static IP and proper firewall rules for API access
13. For KIS, implement proper OAuth2 flow with hashkey generation for secure orders
```

## Notes

- KIS provides 337 APIs covering stocks, futures, options, and international markets
- KIS documentation available in `brokers/kis/KIS_API_SPEC.md` and Excel spec in `brokers/kis/reference/`
- KIS rate limits: 20 req/sec, 1,000 req/min, 50,000 req/hour
- KIS supports both production (`openapi.koreainvestment.com`) and sandbox environments
- Creon requires dedicated Windows PC - no containers/VMs allowed due to security restrictions
- Creon FastAPI service runs directly on Windows bare metal and exposes REST API to network
- Rate limiting is critical - violations can result in API suspension
- Consider implementing a broker health check system
- Each broker has unique data formats requiring normalization
- Network security between Creon Windows PC and main system needs careful configuration

## Epic Position in Overall Project

### Impact Analysis

This epic is the **second most critical** in the entire JTS project:

- **Blocks**: 3 major epics ([E04](../E04/spec.md): Strategy, [E05](../E05/spec.md): Risk, [E06](../E06/spec.md): Execution)
- **Blocked by**: 1 epic ([E01](../E01/spec.md): Foundation)
- **Related to**: 1 epic ([E03](../E03/spec.md): Market Data)
- **Criticality**: HIGH - No trading possible without broker connectivity

### Timeline Context

- **Prerequisites**: Foundation (Epic [E01](../E01/spec.md)) must be 100% complete
- **Can run parallel with**:
  - Epic E08 (Monitoring)
  - Epic E10 (Crypto Integration)
- **Optimal team size**: 2-3 developers
- **Estimated duration**: 8-10 weeks with 2 developers

### Risk Factors

1. **External API Dependencies** (HIGH)
   - KIS API changes or outages
   - Creon platform updates
   - Rate limit violations

2. **Platform Constraints** (MEDIUM)
   - Creon requires dedicated Windows hardware
   - Cannot use virtualization for Creon

3. **Integration Complexity** (HIGH)
   - 337 KIS APIs to integrate
   - Multiple broker data format normalization
   - Cross-platform communication (Linux ↔ Windows)

### Success Metrics

- All 11 features completed and tested
- <100ms order placement latency
- 99.9% uptime during market hours
- Zero rate limit violations in production
- Successful failover between brokers

## Status Updates

- **2025-08-24**: Epic created and documented
- **2025-08-26**: Split into 11 feature specifications with detailed requirements
