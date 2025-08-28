---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '10000' # Numeric ID for stable reference
title: 'Cryptocurrency Integration'
type: 'epic' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '' # Parent spec ID (leave empty for top-level)
children: [] # Child spec IDs (if any)
epic: '10000' # Root epic ID for this work
domain: 'cryptocurrency' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low

# === TRACKING ===
created: '2025-08-24' # YYYY-MM-DD
updated: '2025-08-24' # YYYY-MM-DD
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 160 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: ['1000', '2000'] # Must be done before this (foundation-infrastructure, broker-integration)
blocks: [] # This blocks these specs
related: ['3000', '5000'] # Related to market-data and risk-management epics

# === IMPLEMENTATION ===
branch: '' # Git branch name
files: ['apps/brokers/binance/', 'apps/brokers/upbit/', 'libs/shared/interfaces/crypto.interface.ts', 'libs/shared/dto/crypto.dto.ts'] # Key files to modify

# === METADATA ===
tags: ['cryptocurrency', 'binance', 'upbit', 'crypto-trading', '24-7', 'arbitrage', 'compliance'] # Searchable tags
effort: 'epic' # small | medium | large | epic
risk: 'high' # low | medium | high (high due to 24/7 operations and regulatory complexity)

# ============================================================================
---

# Cryptocurrency Integration

## Overview

Implement comprehensive cryptocurrency trading capabilities by integrating Binance for global crypto markets and Upbit for Korean KRW pairs. This epic establishes 24/7 trading infrastructure, crypto-specific indicators and strategies, cross-exchange arbitrage detection, and regulatory compliance for Korean cryptocurrency trading.

## Acceptance Criteria

- [ ] Binance service fully integrated with spot trading, WebSocket feeds, and rate limiting
- [ ] Upbit service operational with KRW pairs and Korean regulatory compliance
- [ ] 24/7 trading management system with continuous market monitoring
- [ ] Crypto-specific technical indicators and volatility metrics implemented
- [ ] Cross-exchange arbitrage detection and alert system functional
- [ ] Support for USDT, BTC, ETH, and KRW trading pairs
- [ ] Regulatory compliance framework for Korean crypto trading
- [ ] Unified cryptocurrency portfolio management across exchanges
- [ ] Real-time risk management for high-volatility crypto markets
- [ ] Crypto market data normalization and standardization

## Technical Approach

### Cryptocurrency Trading Architecture
Build a specialized cryptocurrency trading infrastructure that handles the unique characteristics of crypto markets including 24/7 operation, high volatility, cross-exchange opportunities, and regulatory requirements specific to Korean crypto trading.

### Key Components

1. **Binance Service Integration**
   - REST API for account management and trading
   - WebSocket streams for real-time market data
   - Spot trading implementation (futures optional)
   - Rate limit management (1200 requests/minute)
   - Multi-symbol data streaming
   - Order book depth integration

2. **Upbit Service Integration**
   - Korean Won (KRW) trading pairs
   - Regulatory compliance features
   - Tax reporting data collection
   - Korean market hours awareness
   - Rate limit management (10 requests/second)
   - Account verification status monitoring

3. **24/7 Trading Management**
   - Continuous market monitoring system
   - Weekend and holiday trading support
   - Global timezone management
   - Market session detection (Asian/European/American)
   - Automated position rebalancing
   - Sleep mode for low-volume periods

4. **Crypto-Specific Indicators**
   - Cryptocurrency volatility metrics
   - Social sentiment integration
   - On-chain analysis indicators
   - Fear & Greed index integration
   - Funding rate analysis
   - Volume-weighted indicators

5. **Cross-Exchange Arbitrage System**
   - Real-time price comparison across exchanges
   - Arbitrage opportunity detection
   - Transaction cost calculation
   - Execution feasibility analysis
   - Risk-adjusted profit estimation
   - Automated alert generation

6. **Multi-Currency Support**
   - USDT (Tether) as primary stable coin
   - BTC (Bitcoin) trading pairs
   - ETH (Ethereum) ecosystem tokens
   - KRW (Korean Won) fiat integration
   - Currency conversion management
   - Cross-currency portfolio balancing

7. **Korean Regulatory Compliance**
   - KYC/AML verification tracking
   - Transaction reporting for tax purposes
   - Daily trading limit monitoring
   - Suspicious activity detection
   - Regulatory update notification system
   - Compliance audit trail

### Implementation Steps

1. **Binance Service Development**
   - Set up NestJS service structure
   - Implement Binance REST API client
   - Configure WebSocket market data streams
   - Add rate limiting and error handling
   - Build order execution system
   - Implement account management features

2. **Upbit Service Development**
   - Create Upbit API integration
   - Implement Korean compliance features
   - Add KRW pair trading support
   - Build regulatory reporting system
   - Configure market data collection
   - Add tax calculation helpers

3. **24/7 Operations Infrastructure**
   - Design continuous monitoring system
   - Implement timezone-aware scheduling
   - Create market session detection
   - Build automated rebalancing logic
   - Add weekend trading capabilities
   - Implement emergency stop mechanisms

4. **Crypto Indicators Framework**
   - Develop crypto-specific indicators
   - Integrate external data sources
   - Build volatility calculation engine
   - Add social sentiment analysis
   - Implement on-chain metrics
   - Create composite crypto scores

5. **Arbitrage Detection System**
   - Build price comparison engine
   - Implement opportunity scoring
   - Add execution cost modeling
   - Create alert notification system
   - Build historical arbitrage tracking
   - Add performance analytics

6. **Unified Portfolio Management**
   - Design cross-exchange position tracking
   - Implement unified balance calculation
   - Build currency conversion system
   - Add portfolio rebalancing logic
   - Create risk exposure monitoring
   - Implement consolidated reporting

7. **Compliance & Risk Management**
   - Build Korean compliance framework
   - Implement transaction monitoring
   - Add regulatory reporting features
   - Create risk limit enforcement
   - Build suspicious activity detection
   - Add compliance dashboard

## Dependencies

- **1000**: Foundation & Infrastructure Setup - Requires monorepo, Redis, Kafka, and database infrastructure
- **2000**: Multi-Broker Integration Layer - Requires unified broker interface and rate limiting framework

## Testing Plan

- Unit tests for both Binance and Upbit service adapters
- Integration tests with exchange sandbox environments
- 24/7 operation stress testing during low-volume periods
- Arbitrage detection accuracy validation
- Regulatory compliance workflow testing
- Cross-exchange position synchronization testing
- High-volatility scenario testing
- Korean regulatory compliance verification
- Multi-currency conversion accuracy testing

## Claude Code Instructions

```
When implementing this epic:
1. Create separate NestJS services for Binance and Upbit in apps/brokers/
2. Implement crypto-specific interfaces extending the base IBroker interface
3. Use WebSocket connections for real-time price feeds from both exchanges
4. Implement comprehensive error handling for network instability
5. Create crypto-specific DTOs for orders, positions, and market data
6. Build timezone-aware scheduling for 24/7 operations
7. Implement rate limiting specific to each exchange's requirements
8. Create regulatory compliance logging for Korean markets
9. Use Redis for caching frequently accessed crypto prices
10. Implement circuit breakers for exchange connectivity
11. Create comprehensive monitoring for crypto market volatility
12. Build automated position sizing based on crypto volatility
```

## Korean Regulatory Considerations

### Key Compliance Requirements
- **Real Name Verification**: All accounts must be verified with real names
- **Daily Trading Limits**: Monitor and enforce daily trading volume limits
- **Tax Reporting**: Collect transaction data for capital gains reporting
- **Anti-Money Laundering**: Implement AML monitoring for large transactions
- **Market Manipulation Prevention**: Monitor for suspicious trading patterns
- **Data Retention**: Maintain transaction records for regulatory audits

### Implementation Requirements
- KYC status verification for all trading accounts
- Automated daily limit tracking and enforcement
- Transaction categorization for tax purposes
- Suspicious activity pattern detection
- Regulatory reporting data export capabilities
- Compliance dashboard for monitoring

## Cross-Exchange Arbitrage Strategy

### Opportunity Detection
- Real-time price monitoring across Binance and Upbit
- Minimum profit threshold configuration (accounting for fees)
- Network congestion impact assessment
- Liquidity depth verification
- Transaction cost modeling including:
  - Trading fees on both exchanges
  - Network withdrawal/deposit fees
  - Slippage estimation
  - Time value risk

### Execution Considerations
- Account balance verification on both exchanges
- Simultaneous order execution capability
- Network latency monitoring
- Order fill confirmation tracking
- Profit realization verification
- Risk management for failed arbitrage attempts

## 24/7 Operations Management

### Continuous Monitoring
- Global market session awareness (Asian/European/American)
- Weekend and holiday trading support
- Low-volume period detection and strategy adjustment
- Automated position rebalancing during off-peak hours
- Emergency stop mechanisms for system maintenance
- Market volatility spike detection and response

### Resource Management
- CPU and memory optimization for continuous operation
- Database connection pooling for 24/7 queries
- WebSocket connection management and reconnection
- Log rotation and storage management
- Automated backup scheduling
- System health monitoring and alerting

## Performance Requirements

- **Latency**: Price feed updates within 50ms
- **Throughput**: Handle 1000+ price updates per second
- **Uptime**: 99.9% availability for crypto markets
- **Response Time**: Order execution within 200ms
- **Data Retention**: 2 years of transaction history
- **Monitoring**: Real-time system health metrics

## Security Considerations

- API key encryption for exchange credentials
- Secure WebSocket connection management
- Transaction signing and verification
- Rate limiting to prevent API abuse
- Network security for 24/7 operations
- Audit logging for all trading activities
- Multi-factor authentication for account management
- Cold storage integration for large crypto holdings

## Notes

- Cryptocurrency markets operate 24/7 requiring continuous system operation
- High volatility requires enhanced risk management compared to traditional assets
- Korean crypto regulations are strict and require careful compliance implementation
- Cross-exchange arbitrage opportunities exist but require fast execution
- Network congestion can significantly impact transaction costs and timing
- Consider implementing futures trading capabilities as future enhancement
- Monitor regulatory changes in both global and Korean crypto markets

## Status Updates

- **2025-08-24**: Epic created and documented