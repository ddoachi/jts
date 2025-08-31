# JTS Automated Trading System - Product Requirements Document

## Executive Summary

JTS (자동매매시스템) is an automated trading platform designed for Korean retail investors. The system provides unified access to multiple brokers and exchanges, enabling sophisticated trading strategies across equities and cryptocurrency markets through intelligent automation and real-time market analysis.

## Vision & Objectives

### Primary Goal

Build a scalable, reliable automated trading system that democratizes algorithmic trading for retail investors by providing institutional-grade tools and strategies.

### Key Objectives

- Enable comprehensive market coverage through multi-broker integration
- Provide real-time surge detection and momentum trading capabilities
- Implement sophisticated risk management and position sizing algorithms
- Deliver actionable insights through advanced analytics
- Ensure system reliability and performance during market hours

## System Architecture

### Architectural Principles

The system follows a microservices architecture with clear separation of concerns, enabling independent scaling, fault isolation, and rapid development cycles. Services communicate through well-defined interfaces using appropriate protocols for each use case.

### Core Layers

- **Presentation**: User interfaces for monitoring and control
- **Gateway**: Request routing and authentication
- **Business Logic**: Trading strategies and risk management
- **Integration**: Market data and broker connectivity
- **Messaging**: Event streaming and caching
- **Broker Services**: Exchange-specific implementations
- **Data Storage**: Transactional and time-series databases

### Service Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                            │
│                 (PWA with Service Workers + Mobile)              │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                      Gateway Layer                               │
│              (API Gateway with Auth & Rate Limiting)             │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                    Business Layer                                │
├────────────────┬────────────────┬────────────────┬───────────────┤
│    Strategy    │   Risk         │    Portfolio   │    Order      │
│    Engine      │   Management   │    Tracker     │    Execution  │
└────────────────┴────────────────┴────────────────┴───────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                   Integration Layer                              │
├───────────────────────────────┬──────────────────────────────────┤
│     Market Data Collector     │     Notification Service         │
└───────────────────────────────┴──────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                    Messaging Layer                               │
├───────────────────────────────┬──────────────────────────────────┤
│      Kafka (Event Stream)     │     Redis (Cache/Lock/Session)   │
└───────────────────────────────┴──────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                     Brokers Layer                                │
├─────────────┬─────────────┬─────────────┬───────────────────────┤
│Creon Service│ KIS Service │Binance Serv.│    Upbit Service      │
│ (Windows)   │  (Linux)    │  (Linux)    │     (Linux)           │
│Rate: 15s/60 │Rate: 1s/20  │Rate: 1m/1200│   Rate: 1s/10         │
└─────────────┴─────────────┴─────────────┴───────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                      Data Layer                                  │
├──────────────┬──────────────┬──────────────┬────────────────────┤
│ PostgreSQL   │ ClickHouse   │   MongoDB    │   File Storage     │
│(Transactions)│(Time Series) │(Configuration)│  (Logs/Backups)   │
└──────────────┴──────────────┴──────────────┴────────────────────┘
```

## Multi-Broker Strategy

### Strategic Approach

The system implements a multi-broker architecture to maximize market coverage, execution quality, and system resilience. By leveraging multiple brokers and accounts simultaneously, the platform achieves comprehensive market access while maintaining high availability.

### Broker Capabilities

Each integrated broker offers unique advantages:

- **Creon**: Deep Korean market integration with robust historical data
- **KIS**: Scalable multi-account support with modern REST APIs
- **Binance**: Global cryptocurrency markets with high liquidity
- **Upbit**: Korean cryptocurrency exchange with KRW pairs

### Coverage Strategy

The system distributes market coverage across brokers based on their strengths:

- Primary liquid stocks through established connections
- Mid-cap opportunities through scaled account infrastructure
- Small-cap momentum plays through dedicated monitoring
- Overflow capacity through reserve accounts

### Execution Optimization

Smart order routing ensures optimal execution by considering:

- Current system capacity and rate limits
- Account balances and existing positions
- Historical execution quality metrics
- Market conditions and liquidity

## Platform Architecture

### Infrastructure Strategy

The system employs a distributed infrastructure approach, leveraging platform-specific advantages while maintaining unified control through service abstraction.

### Cross-Platform Integration

Services communicate through standardized APIs, enabling:

- Platform-agnostic business logic
- Transparent failover mechanisms
- Centralized monitoring and control
- Distributed processing capabilities

## Rate Limiting Architecture

### Overview

Each broker service implements intelligent rate limiting to maximize API utilization while respecting broker-specific constraints. The system uses priority queues and sliding window algorithms to ensure critical operations receive precedence.

### Priority Management

Requests are prioritized based on business criticality:

- **Critical**: Order execution and risk management
- **Real-time**: Market data and price updates
- **Background**: Historical data and account information

## MVP Implementation Strategy

### Critical Path for Feasibility Validation

The MVP focuses on proving core functionality with minimal complexity:

**Essential Components**:

1. **Single broker connection** (KIS recommended for REST API simplicity)
2. **Real-time market data pipeline**
3. **Basic strategy execution with DSL**
4. **Order management system**
5. **Minimal monitoring dashboard**

**Target Timeline**: 2-3 weeks for basic trading capability

### Parallel Development Tracks

**Track 1 - Data Infrastructure**:

- Market Data Collector
- PostgreSQL setup
- Redis caching layer
- Basic Kafka streaming

**Track 2 - Broker Integration**:

- KIS Service (primary)
- Creon Service (secondary)
- Order execution APIs
- Account management

**Track 3 - Business Logic**:

- Strategy Engine with mock data
- DSL interpreter
- Risk management rules
- Backtesting framework

## Phase 1: MVP - Minimal Trading Pipeline (Weeks 1-3)

### Week 1: Foundation & Single Broker

**Objective**: Establish end-to-end trading capability with one broker

**Deliverables**:

- **Infrastructure Setup**:
  - Monorepo with Nx workspace
  - PostgreSQL for orders and positions
  - Redis for real-time caching
  - Basic Docker compose setup
- **KIS Broker Service**:
  - REST API integration
  - Authentication and session management
  - Account balance queries
  - Simple order execution (buy/sell)
- **Core Data Models**:
  - Unified order structure
  - Position tracking schema
  - Account model

**Success Criteria**:

- Successfully connect to KIS API
- Execute a test trade
- Store order in database
- Cache price data in Redis

### Week 2: Real-time Data Flow

**Objective**: Build live market data pipeline with signal generation

**Deliverables**:

- **Market Data Collector**:
  - Real-time price streaming from KIS
  - WebSocket connection management
  - Data normalization layer
  - Redis pub/sub for distribution
- **Simple Strategy Engine**:
  - Basic buy/sell signal generation
  - Moving average crossover strategy
  - RSI-based signals
  - Mock DSL interpreter
- **Order Execution Service**:
  - Signal to order conversion
  - Position size calculation
  - Order state management
  - Execution confirmation handling

**Success Criteria**:

- Stream live prices for 10+ symbols
- Generate trading signals in real-time
- Execute orders based on signals
- Track order lifecycle

### Week 3: Basic Dashboard & DSL

**Objective**: Create minimal UI for monitoring and strategy definition

**Deliverables**:

- **Trading Dashboard (PWA)**:
  - Live price display
  - Account balance and positions
  - Active orders list
  - P&L tracking
  - Simple charts with entry/exit points
- **DSL Formula Builder**:
  - Basic formula creation UI
  - Support for price conditions
  - Simple indicator combinations
  - Save/load formulas
- **Backtesting Proof-of-Concept**:
  - Run DSL against historical data
  - Display backtest results
  - Basic performance metrics

**Success Criteria**:

- View live trading activity
- Create and save a DSL formula
- Backtest a strategy
- Monitor account performance

## Phase 2: Core Features Enhancement (Weeks 4-5)

### Week 4: Advanced DSL & Backtesting

**Objective**: Build comprehensive strategy definition and validation system

**Deliverables**:

- **Full DSL Implementation**:
  - Complete formula parser and interpreter
  - Support for all indicator types:
    - Technical indicators (RSI, MACD, Bollinger Bands)
    - Moving averages (SMA, EMA, WMA)
    - Volume analysis
    - Price patterns
  - Conditional logic (AND, OR, NOT)
  - Variable parameters and optimization
- **Production Backtesting Engine**:
  - Historical data fetching from multiple sources
  - Accurate simulation with:
    - Slippage modeling
    - Commission calculations
    - Market impact estimates
  - Performance metrics:
    - Sharpe ratio
    - Maximum drawdown
    - Win rate and profit factor
  - Parameter optimization framework
- **Strategy Management**:
  - Save and version strategies
  - Share strategies between accounts
  - Strategy performance tracking
  - A/B testing framework

**Success Criteria**:

- Backtest 1 year of data in <10 seconds
- Support 20+ technical indicators
- Optimize strategy parameters
- Generate detailed performance reports

### Week 5: Multi-Broker & Scaling

**Objective**: Add second broker and implement intelligent routing

**Deliverables**:

- **Creon Broker Integration**:
  - Windows service setup
  - COM object wrapper
  - Rate limit management
  - Real-time data streaming
- **Multi-Account Management**:
  - Account pool coordination
  - Symbol distribution across accounts
  - Balance aggregation
  - Unified position tracking
- **Smart Order Routing**:
  - Best execution logic
  - Broker selection algorithm
  - Rate limit optimization
  - Failover mechanisms
- **Enhanced Dashboard Features**:
  - Multi-broker status view
  - Aggregated P&L across accounts
  - Per-broker performance metrics
  - Account switching UI

**Success Criteria**:

- Manage 5+ accounts simultaneously
- Route orders to optimal broker
- Handle broker failures gracefully
- Track positions across all accounts

## Phase 3: Production Ready (Weeks 6-8)

### Week 6: Risk Management & Monitoring

**Objective**: Implement production-grade risk controls and observability

**Deliverables**:

- **Risk Management System**:
  - Position size limits per symbol
  - Maximum daily loss limits
  - Correlation-based exposure management
  - Volatility-adjusted position sizing
  - Emergency stop-all functionality
- **Real-time Monitoring**:
  - System health dashboard
  - API rate limit tracking
  - Order execution metrics
  - Latency monitoring
  - Error rate tracking
- **Alert System**:
  - WebSocket-based push notifications
  - Email/SMS integration
  - Customizable alert rules
  - Priority-based routing
- **Performance Analytics**:
  - Real-time P&L tracking
  - Strategy performance comparison
  - Slippage analysis
  - Execution quality metrics

**Success Criteria**:

- Risk limits enforced in <100ms
- 99.9% uptime for monitoring
- Alert delivery in <1 second
- Comprehensive audit trail

### Week 7: Cryptocurrency Integration

**Objective**: Add crypto trading capabilities for portfolio diversification

**Deliverables**:

- **Binance Integration**:
  - Spot trading implementation
  - WebSocket market data
  - USDT/BTC pairs focus
  - Rate limit management
- **Upbit Integration**:
  - KRW trading pairs
  - Korean regulatory compliance
  - Tax reporting hooks
  - Account verification
- **Unified Crypto Features**:
  - Cross-exchange arbitrage detection
  - Crypto-specific indicators
  - 24/7 trading management
  - Portfolio rebalancing

**Success Criteria**:

- Trade execution on both exchanges
- Real-time crypto price feeds
- Unified crypto portfolio view
- Regulatory compliance verified

### Week 8: Production Deployment & Optimization

**Objective**: Deploy to production with enterprise-grade reliability

**Deliverables**:

- **Infrastructure Hardening**:
  - Kubernetes deployment configs
  - Auto-scaling policies
  - Database connection pooling
  - CDN setup for dashboard
- **Security Implementation**:
  - API key encryption
  - JWT authentication
  - Rate limiting per user
  - Audit logging
- **Performance Optimization**:
  - Query optimization
  - Caching strategies
  - WebSocket connection pooling
  - Batch processing for historical data
- **Documentation & Training**:
  - API documentation
  - User guide
  - Deployment runbook
  - Disaster recovery plan

**Success Criteria**:

- <100ms API response time
- Handle 1000+ concurrent users
- Zero-downtime deployment
- Complete documentation

## Phase 4: Advanced Capabilities (Weeks 15-18)

### 4.1 Backtesting Framework (Weeks 15-16)

**Objective**: Build comprehensive strategy testing system

**Core Features**:

- Multi-source data integration
- Realistic market simulation
- Parameter optimization
- Performance validation

**Testing Capabilities**:

- Historical data analysis
- Multi-account constraints
- Latency simulation
- Slippage modeling

### 4.2 Machine Learning Enhancement (Week 17)

**Objective**: Integrate ML for improved trading decisions

**ML Applications**:

- Pattern recognition systems
- Predictive analytics
- Adaptive strategy optimization
- Market regime detection

**Capabilities**:

- Real-time inference
- Dynamic parameter adjustment
- False signal filtering
- Performance prediction

### 4.3 Monitoring & Alerting (Week 18)

**Objective**: Establish comprehensive system observability

**Monitoring Scope**:

- Multi-broker performance
- Trading effectiveness
- System health metrics
- Data quality assurance

**Alert Categories**:

- Connection issues
- Performance degradation
- Risk threshold breaches
- Anomaly detection

## Phase 5: Production Deployment (Weeks 19-20)

### 5.1 Performance Optimization

Focus on system-wide performance improvements including database optimization, caching strategies, network efficiency, and resource utilization.

### 5.2 Security Hardening

Implement comprehensive security measures including authentication, encryption, audit trails, and vulnerability testing.

### 5.3 Deployment & Documentation

Prepare production deployment with automated scripts, disaster recovery procedures, and comprehensive documentation.

## Technical Infrastructure

### Computing Resources

The system utilizes distributed computing infrastructure:

- **Primary Server**: High-performance Linux system for core services
- **Windows Server**: Dedicated broker API integration
- **Storage Systems**: NAS for backups and archival

### Data Architecture

**Message Queue System**:

- Market data streaming topics
- Trading signal distribution
- Order management events
- Portfolio and risk updates
- System monitoring streams

**Caching Strategy**:

- Real-time price caching
- Session management
- Distributed locking
- Rate limiter state
- Circuit breaker patterns

**Database Design**:

- **Transactional**: Order and account management
- **Time-Series**: Market data and analytics
- **Document Store**: Configuration and strategies

## Success Metrics

### MVP Success Metrics (Week 3)

- **Proof of Concept**:
  - Execute 1+ live trades via KIS API
  - Stream real-time prices for 10+ symbols
  - Generate signals from DSL formulas
  - Display live positions in dashboard

### Phase 1 Completion (Week 5)

- **Core Functionality**:
  - Backtest strategies with 70%+ accuracy
  - Support 20+ technical indicators
  - Manage 2+ brokers simultaneously
  - Handle 100+ symbols in real-time

### Production Metrics (Week 8)

- **Technical Performance**:
  - Market coverage: 500+ symbols initially, scaling to 1,800+
  - Detection latency: <100ms
  - Execution speed: <500ms
  - System uptime: 99.9%
  - API utilization: 80-90%

- **Trading Performance**:
  - Daily opportunities: 10-20 initially, scaling to 50+
  - Win rate: 60-70%
  - Risk/Reward: 1:2 or better
  - Daily volume: 10-30 trades

- **System Capabilities**:
  - Multi-broker support (KIS, Creon, Binance, Upbit)
  - Automatic failover
  - 80%+ test coverage
  - Security compliance

## Risk Management

### Technical Risks

- API limitations and constraints
- Platform stability concerns
- Network latency challenges
- Data consistency requirements

### Operational Risks

- Hardware failure scenarios
- API changes and updates
- Regulatory compliance needs

### Mitigation Strategies

- Intelligent request management
- Automated health monitoring
- Redundant data sources
- Comprehensive audit trails

## Development Approach

### Methodology

- Agile development with 2-week sprints
- Continuous integration and deployment
- Regular stakeholder communication
- Iterative refinement process

### Development Tools

- AI-assisted coding and testing
- Automated task management
- Code review and quality assurance
- Performance monitoring

## Appendix

### Key Terms

- **DSL**: Domain-Specific Language for strategy definition
- **PWA**: Progressive Web App with offline capabilities
- **Kelly Criterion**: Mathematical formula for optimal position sizing
- **Surge Detection**: Momentum-based trading opportunity identification
- **Smart Order Routing**: Intelligent broker selection for optimal execution

### Project Timeline - MVP Focused Approach

**Fast Track to Production (8 Weeks)**:

- **Weeks 1-3**: MVP - Minimal Trading Pipeline
  - Week 1: Foundation & Single Broker (KIS)
  - Week 2: Real-time Data Flow & Basic Strategy
  - Week 3: Dashboard & DSL Builder
- **Weeks 4-5**: Core Features Enhancement
  - Week 4: Advanced DSL & Backtesting
  - Week 5: Multi-Broker & Smart Routing
- **Weeks 6-8**: Production Ready
  - Week 6: Risk Management & Monitoring
  - Week 7: Cryptocurrency Integration
  - Week 8: Production Deployment

**Extended Roadmap (Post-MVP)**:

- **Weeks 9-12**: Advanced Features
  - Machine Learning Integration
  - Advanced Analytics
  - Mobile Applications
- **Weeks 13-16**: Scale & Optimize
  - Additional broker integrations
  - High-frequency trading capabilities
  - International market expansion
