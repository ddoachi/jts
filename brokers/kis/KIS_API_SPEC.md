# KIS (Korea Investment Securities) API Specification

## Overview

Korea Investment Securities provides comprehensive REST and WebSocket APIs for stock trading in Korean markets.

## API Categories

### Total APIs: 337

#### Main Categories:
1. **Authentication & Token Management** (5 APIs)
   - Token issuance and management
   - Hashkey generation
   - WebSocket connection key

2. **Domestic Stock Trading** (26 APIs)
   - Stock orders (cash/credit)
   - Order modification/cancellation
   - Scheduled orders
   - Balance inquiries
   - Trading history

3. **Domestic Stock Market Data** (49 APIs)
   - Real-time price quotes
   - Orderbook data
   - Historical price data (daily/weekly/monthly)
   - Time and sales
   - After-hours trading

4. **ELW (Equity Linked Warrant)** (22 APIs)
   - ELW pricing
   - Sensitivity analysis
   - Volatility tracking
   - LP trading trends

5. **Market Indices & Sectors** (12 APIs)
   - Index quotes
   - Sector performance
   - Market holidays

6. **Corporate Information** (30 APIs)
   - Financial statements
   - Financial ratios
   - Analyst opinions
   - Corporate events (dividends, splits, etc.)

7. **Investment Analysis** (29 APIs)
   - Program trading data
   - Foreign/institutional investor flows
   - Short selling data
   - Market microstructure

8. **Ranking & Screening** (23 APIs)
   - Volume rankings
   - Price change rankings
   - Market cap rankings
   - Conditional screening

9. **Real-time WebSocket** (22 APIs)
   - Real-time quotes
   - Real-time orderbook
   - Real-time trades
   - Real-time indices

10. **Futures & Options** (24 APIs)
    - Futures/options orders
    - Position management
    - Margin requirements
    - Night session trading

11. **International Stocks** (51 APIs)
    - US/Asian market trading
    - International market data
    - Currency exchange rates

12. **International Futures & Options** (14 APIs)
    - Global derivatives trading
    - International margin management

## Key Trading APIs

### 1. Stock Order (Cash)
- **Endpoint**: `/uapi/domestic-stock/v1/trading/order-cash`
- **Method**: POST
- **Purpose**: Place buy/sell orders with cash account

### 2. Stock Order Modification/Cancellation
- **Endpoint**: `/uapi/domestic-stock/v1/trading/order-rvsecncl`
- **Method**: POST
- **Purpose**: Modify or cancel existing orders

### 3. Stock Balance Inquiry
- **Endpoint**: `/uapi/domestic-stock/v1/trading/inquire-balance`
- **Method**: GET
- **Purpose**: Query current stock holdings

### 4. Current Stock Price
- **Endpoint**: `/uapi/domestic-stock/v1/quotations/inquire-price`
- **Method**: GET
- **Purpose**: Get real-time stock prices

### 5. Orderbook & Expected Execution
- **Endpoint**: `/uapi/domestic-stock/v1/quotations/inquire-asking-price-exp-ccn`
- **Method**: GET
- **Purpose**: Get orderbook depth and expected execution prices

### 6. Buyable Amount Inquiry
- **Endpoint**: `/uapi/domestic-stock/v1/trading/inquire-psbl-order`
- **Method**: GET
- **Purpose**: Calculate maximum buyable quantity

### 7. Daily Order Execution History
- **Endpoint**: `/uapi/domestic-stock/v1/trading/inquire-daily-ccld`
- **Method**: GET
- **Purpose**: Query daily trade executions

## Authentication

### OAuth2 Flow
1. **Get Access Token**
   - Endpoint: `/oauth2/tokenP`
   - Method: POST
   - Validity: 24 hours

2. **Hashkey Generation**
   - Endpoint: `/uapi/hashkey`
   - Method: POST
   - Required for: Order placement, modification

3. **WebSocket Token**
   - Endpoint: `/oauth2/Approval`
   - Method: POST
   - For real-time data subscription

## Rate Limits

### REST API Limits
- **Per Second**: 20 requests
- **Per Minute**: 1,000 requests
- **Per Hour**: 50,000 requests

### WebSocket Limits
- **Concurrent Connections**: 5
- **Subscriptions per Connection**: 40 symbols

### Rate Limit Headers
- `X-RateLimit-Limit`: Maximum requests
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Reset timestamp

## Domains

### Production
- **REST API**: `https://openapi.koreainvestment.com:9443`
- **WebSocket**: `ws://ops.koreainvestment.com:21000`

### Sandbox (Paper Trading)
- **REST API**: `https://openapivts.koreainvestment.com:29443`
- **WebSocket**: `ws://ops.koreainvestment.com:31000`

## Order Types

### Basic Order Types
- **00**: Market order (시장가)
- **01**: Limit order (지정가)
- **02**: Conditional order (조건부지정가)
- **03**: Best limit order (최유리지정가)
- **04**: Priority limit order (최우선지정가)
- **05**: Pre-market order (장전 시간외)
- **06**: Post-market order (장후 시간외)
- **07**: Market on open (시장가 시가)
- **08**: Market on close (시장가 종가)

### Time in Force
- **IOC**: Immediate or Cancel
- **FOK**: Fill or Kill
- **GTD**: Good Till Date
- **GTC**: Good Till Cancel

## Error Codes

### Common Error Codes
- `OPSQ0001`: Invalid request parameter
- `OPSQ0002`: Authentication failed
- `OPSQ0003`: Insufficient permissions
- `OPSQ0004`: Rate limit exceeded
- `OPSQ0005`: Service temporarily unavailable
- `OPSQ1001`: Insufficient balance
- `OPSQ1002`: Order quantity exceeds limit
- `OPSQ1003`: Invalid stock code
- `OPSQ1004`: Market closed
- `OPSQ1005`: Trading suspended

## WebSocket Message Format

### Subscribe Request
```json
{
  "header": {
    "approval_key": "approval_key_value",
    "custtype": "P",
    "tr_type": "1",
    "content-type": "utf-8"
  },
  "body": {
    "input": {
      "tr_id": "H0STCNT0",
      "tr_key": "005930"
    }
  }
}
```

### Real-time Price Response
```json
{
  "header": {
    "tr_id": "H0STCNT0",
    "datetime": "20240101120000"
  },
  "body": {
    "rt_cd": "0",
    "msg_cd": "OPSP0000",
    "msg1": "정상처리",
    "output": {
      "stck_cntg_hour": "120000",
      "stck_prpr": "71000",
      "prdy_vrss": "-500",
      "prdy_ctrt": "-0.70",
      "acml_vol": "10234567"
    }
  }
}
```

## Implementation Notes

### Connection Management
1. Maintain connection pool for REST APIs
2. Implement exponential backoff for retries
3. Use circuit breaker pattern for failures
4. Keep WebSocket connections alive with ping/pong

### Data Normalization
1. Convert KRW amounts to numbers (remove commas)
2. Parse dates in YYYYMMDD format
3. Handle null values appropriately
4. Normalize stock codes (6-digit format)

### Security Best Practices
1. Store API keys in environment variables
2. Rotate access tokens before expiry
3. Implement request signing with hashkey
4. Use TLS for all connections
5. Validate all server responses

## KIS-Specific Features

### 1. Scheduled Orders (예약주문)
- Place orders to execute at specific times
- Useful for market open/close strategies

### 2. Credit Trading (신용거래)
- Margin trading with leverage
- Separate API endpoints for credit orders

### 3. Retirement Accounts (퇴직연금)
- Special handling for pension accounts
- Different tax treatment

### 4. Fractional Shares (소수점 매매)
- Support for fractional share trading
- Available for select stocks

### 5. Block Trading (대량매매)
- Special endpoints for large orders
- Negotiated pricing available