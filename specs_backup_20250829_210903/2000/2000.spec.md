---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '2000' # Numeric ID for stable reference
title: 'Multi-Broker Integration Layer'
type: 'epic' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '' # Parent spec ID (leave empty for top-level)
children: ['2100', '2101', '2102', '2103', '2104', '2105', '2106', '2107', '2108', '2109', '2110'] # Child spec IDs
epic: '2000' # Root epic ID for this work
domain: 'broker-integration' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low

# === TRACKING ===
created: '2025-08-24' # YYYY-MM-DD
updated: '2025-08-26' # YYYY-MM-DD
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 340 # Time estimate in hours (sum of all features)
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: ['1000'] # Must be done before this (foundation-infrastructure)
blocks: ['4000', '5000', '6000'] # This blocks strategy, risk, and order execution
related: ['3000'] # Related to market-data epic

# === IMPLEMENTATION ===
branch: '' # Git branch name
files: ['apps/brokers/', 'libs/shared/interfaces/broker.interface.ts'] # Key files to modify

# === METADATA ===
tags: ['broker', 'integration', 'kis', 'creon', 'api', 'rate-limiting'] # Searchable tags
effort: 'epic' # small | medium | large | epic
risk: 'high' # low | medium | high (high due to external API dependencies)

# ============================================================================
---

# Multi-Broker Integration Layer

## Overview

Implement a unified broker integration layer that provides seamless connectivity to multiple Korean stock brokers (KIS, Creon) and cryptocurrency exchanges (Binance, Upbit). This epic establishes the abstraction layer for broker-agnostic trading operations, intelligent rate limiting, and multi-account management capabilities.

## Feature Breakdown

This epic has been decomposed into 11 features totaling 340 hours of estimated effort:

| ID | Feature | Hours | Priority |
|----|---------|-------|----------|
| 2100 | Unified Broker Interface Foundation | 25 | Critical |
| 2101 | KIS REST API Integration | 40 | High |
| 2102 | KIS WebSocket Real-time Data | 30 | High |
| 2103 | Creon Windows COM Integration | 35 | High |
| 2104 | Distributed Rate Limiting System | 30 | Critical |
| 2105 | Multi-Account Pool Management | 35 | Medium |
| 2106 | Smart Order Routing Engine | 35 | Medium |
| 2107 | Standardized Service Endpoints | 25 | Medium |
| 2108 | Error Handling & Recovery | 30 | High |
| 2109 | Broker Testing & Mock Services | 25 | Low |
| 2110 | Broker Monitoring & Observability | 30 | Medium |

## Mobile-Friendly Dependency Flow

```
┌─────────────────────┐
│    Epic 1000        │
│   Foundation        │
│  Infrastructure     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│    Epic 2000        │
│  BROKER INTEGRATION │ ◄── You are here
│    (340 hours)      │
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    ▼             ▼
┌────────┐  ┌────────┐
│ Epic   │  │ Epic   │
│ 3000   │  │ 10000  │
│ Market │  │ Crypto │
│ Data   │  │        │
└───┬────┘  └────────┘
    │
    ▼
┌────────────────────┐
│    Epic 4000       │
│ Trading Strategy   │
│     Engine         │
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│    Epic 5000       │
│ Risk Management    │
│     System         │
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│    Epic 6000       │
│ Order Execution    │
│   & Portfolio      │
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│    Epic 7000       │
│   User Interface   │
│    & Dashboard     │
└────────────────────┘

Parallel Tracks:
├── Epic 8000: Monitoring
├── Epic 9000: Backtesting
├── Epic 11000: Performance
└── Epic 12000: DevOps
```

## Feature Dependencies Within Epic

### Implementation Phases

**Phase 1: Foundation (25 hrs)**
- 2100: Unified Broker Interface ── Must complete first

**Phase 2: Core Integrations (105 hrs)**
- 2101: KIS REST API ────────────┐
- 2103: Creon COM Integration ───┼── Can run in parallel
- 2104: Rate Limiting System ────┘

**Phase 3: Advanced Features (95 hrs)**
- 2102: KIS WebSocket ───────────┐
- 2105: Account Pool Management ─┼── Can run in parallel
- 2109: Testing & Mocks ─────────┘

**Phase 4: Routing & Standards (60 hrs)**
- 2106: Smart Order Routing ─────┐
- 2107: Standard Endpoints ──────┴── Sequential

**Phase 5: Operations (60 hrs)**
- 2108: Error Handling ──────────┐
- 2110: Monitoring ──────────────┴── Can run in parallel

### Critical Path
```
2100 → 2101 → 2104 → 2105 → 2106 → 2107
     ↘ 2103 ↗
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

- **1000**: Foundation & Infrastructure Setup - Requires monorepo structure, Redis, and Docker infrastructure

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
- **Blocks**: 3 major epics (4000: Strategy, 5000: Risk, 6000: Execution)
- **Blocked by**: 1 epic (1000: Foundation)
- **Related to**: 1 epic (3000: Market Data)
- **Criticality**: HIGH - No trading possible without broker connectivity

### Timeline Context
- **Prerequisites**: Foundation (Epic 1000) must be 100% complete
- **Can run parallel with**: 
  - Epic 8000 (Monitoring) 
  - Epic 10000 (Crypto Integration)
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