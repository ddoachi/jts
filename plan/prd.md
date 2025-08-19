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

## Phase 1: Foundation & Unified Broker Architecture (Weeks 1-6)

### 1.0 Project Foundation (Week 1)

**Objective**: Establish monorepo structure with unified broker interface for parallel development

**Key Deliverables**:
- Monorepo workspace configuration
- Unified broker interface definition
- Service scaffolding and shared libraries
- Development environment setup

**Success Criteria**:
- All services compile and communicate
- Development workflow established
- CI/CD pipeline configured
- Documentation structure in place

### 1.1 Parallel Broker Implementation (Weeks 1-2)

**Objective**: Develop multiple broker integrations simultaneously

**Creon Service**:
- Windows-based integration for Korean equities
- COM object wrapper with rate limiting
- Real-time and historical data access
- Order execution capabilities

**KIS Service**:
- Cross-platform REST API integration
- Multi-account support for scaling
- WebSocket real-time streaming
- Batch operations for efficiency

**Integration Standards**:
- Common data models across brokers
- Unified error handling
- Standardized API endpoints
- Consistent authentication patterns

### 1.2 Multi-Account Architecture (Week 2)

**Objective**: Build scalable account management system

**Core Features**:
- Dynamic account pool management
- Intelligent symbol distribution
- Load-balanced order execution
- Automatic failover mechanisms
- Parallel data collection capabilities

**Benefits**:
- Linear scaling with account additions
- Increased market coverage
- Improved execution redundancy
- Enhanced system resilience

### 1.3 Unified Market Data Collector (Week 3)

**Objective**: Create comprehensive market data aggregation system

**Key Components**:
- Multi-source data collection
- Real-time normalization pipeline
- Time-series storage optimization
- High-performance caching layer

**Capabilities**:
- Parallel processing from all brokers
- Sub-second surge detection
- Historical data management
- Data quality assurance

### 1.4 Smart Order Execution (Week 4)

**Objective**: Build intelligent order routing system

**Core Features**:
- Best execution venue selection
- Multi-account order distribution
- Real-time status tracking
- Cross-account position management
- Automated reconciliation

**Routing Intelligence**:
- Dynamic broker selection
- Rate limit optimization
- Balance consideration
- Historical performance analysis
- Market condition adaptation

### 1.5 Strategy Engine & DSL (Week 5)

**Objective**: Create powerful strategy definition and execution framework

**Core Components**:
- Domain-specific language for strategies
- Real-time signal generation
- Surge detection algorithms
- Multi-timeframe analysis
- Risk management integration
- Backtesting capabilities

**Strategy Types**:
- Technical indicator-based
- Momentum and surge detection
- Multi-timeframe correlation
- Machine learning enhanced
- Custom algorithm support

**Execution Features**:
- Sub-second signal processing
- Parallel strategy evaluation
- State management
- Performance tracking

### 1.6 Monitoring & Integration (Week 6)

**Objective**: Build comprehensive monitoring and notification system

**Dashboard Features**:
- Real-time market coverage metrics
- Multi-broker status monitoring
- Trading performance analytics
- Position and P&L tracking
- Risk metrics visualization

**System Integration**:
- Unified API gateway
- Centralized authentication
- Health monitoring
- Alert management
- Push notifications

**Notification Categories**:
- Trade executions
- Risk warnings
- System alerts
- Performance summaries

## Phase 2: Advanced Trading Features (Weeks 7-10)

### 2.1 Trading Dashboard (Weeks 7-8)

**Objective**: Develop comprehensive trading interface

**Key Features**:
- Multi-broker overview
- Real-time surge monitoring
- Account management
- Position aggregation
- Execution analytics
- Market visualization

**Technical Foundation**:
- Progressive Web App architecture
- Real-time data streaming
- Offline capabilities
- Push notification support

### 2.2 Risk Management System (Week 9)

**Objective**: Implement comprehensive risk controls

**Risk Categories**:
- Account-level limits and controls
- Cross-account exposure management
- Position sizing algorithms
- Correlation risk analysis
- Dynamic adjustment mechanisms

**Protection Mechanisms**:
- Maximum exposure limits
- Loss prevention controls
- Volatility-based adjustments
- Portfolio diversification rules

### 2.3 Performance Analytics (Week 10)

**Objective**: Build comprehensive performance tracking

**Analytics Dimensions**:
- Aggregated performance metrics
- Strategy effectiveness analysis
- Surge trading optimization
- Account utilization metrics
- Execution quality tracking

**Insights Generated**:
- Optimal trading parameters
- Market condition correlation
- Resource allocation efficiency
- Strategy refinement recommendations

## Phase 3: Scaling & Optimization (Weeks 11-14)

### 3.1 Account Scaling (Week 11)

**Objective**: Expand market coverage through additional accounts

**Scaling Approach**:
- Strategic account distribution
- Market segment specialization
- Dynamic resource allocation
- Automated failover systems

**Coverage Strategy**:
- Large-cap blue chips
- Technology growth stocks
- Small-cap momentum plays
- Sector rotation opportunities
- Reserve capacity for overflow

### 3.2 Cryptocurrency Integration - Binance (Week 12)

**Objective**: Add global cryptocurrency trading capabilities

**Key Features**:
- Real-time market data streaming
- Comprehensive trading API
- Major trading pair support
- Advanced order types

### 3.3 Korean Crypto Integration - Upbit (Week 13)

**Objective**: Enable local cryptocurrency trading

**Key Features**:
- KRW trading pair access
- Local regulatory compliance
- Tax reporting capabilities
- Real-time data streaming

### 3.4 System Optimization (Week 14)

**Objective**: Maximize system performance and reliability

**Optimization Areas**:
- Latency reduction strategies
- Execution quality improvements
- System resilience enhancements
- Resource utilization efficiency

**Reliability Features**:
- Automated failover mechanisms
- Circuit breaker patterns
- Self-healing capabilities
- Performance monitoring

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

### Technical Performance
- Market coverage: 1,800+ symbols
- Detection latency: <100ms
- Execution speed: <500ms
- System uptime: 99.9%
- API utilization: 80-90%

### Trading Performance
- Surge detection: 20-50 daily opportunities
- Win rate: 60-70%
- Risk/Reward: 1:2 or better
- Daily volume: 10-30 trades

### System Capabilities
- Multi-broker support
- Automatic failover
- Comprehensive test coverage
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

### Project Timeline
- Phase 1: Foundation (Weeks 1-6)
- Phase 2: Advanced Features (Weeks 7-10)
- Phase 3: Scaling (Weeks 11-14)
- Phase 4: ML Enhancement (Weeks 15-18)
- Phase 5: Production (Weeks 19-20)
