# JTS 개선된 아키텍처 및 Nx 구조

## 1. Rate Limiter 설계

### Broker별 Rate Limiter 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Candle App    │    │ Strategy Engine │    │   BuySell App   │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     Kafka       │ 
                    │ (Request Queue) │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Creon Service  │    │   KIS Service   │    │ Binance Service │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │Rate Limiter │ │    │ │Rate Limiter │ │    │ │Rate Limiter │ │
│ │15초/60건    │ │    │ │1초/20건     │ │    │ │1분/1200건   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ API Client  │ │    │ │ API Client  │ │    │ │ API Client  │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Rate Limiter 메시지 타입 정의

```typescript
// 공통 API 요청 메시지 타입
interface BrokerApiRequest {
  requestId: string;
  correlationId: string;
  brokerType: 'creon' | 'kis' | 'binance' | 'upbit';
  apiMethod: string;
  params: Record<string, any>;
  priority: 'high' | 'medium' | 'low';
  timestamp: number;
  timeoutMs?: number;
}

// 브로커별 구체적 요청 타입
interface CreonApiRequest extends BrokerApiRequest {
  brokerType: 'creon';
  apiMethod: 'getCandleData' | 'getMarketPrice' | 'sendOrder' | 'getBalance';
  params: {
    symbol?: string;
    startDate?: string;
    endDate?: string;
    timeframe?: string;
    orderType?: 'buy' | 'sell';
    quantity?: number;
    price?: number;
  };
}

interface KisApiRequest extends BrokerApiRequest {
  brokerType: 'kis';
  apiMethod: 'getOHLCV' | 'getCurrentPrice' | 'placeOrder' | 'getAccountInfo';
  params: {
    ticker?: string;
    period?: string;
    adjusted?: boolean;
    orderSide?: 'buy' | 'sell';
    orderQty?: string;
    orderPrice?: string;
  };
}

// API 응답 타입
interface BrokerApiResponse {
  requestId: string;
  correlationId: string;
  success: boolean;
  data?: any;
  error?: {
    code: string;
    message: string;
    retryAfter?: number;
  };
  timestamp: number;
  executionTimeMs: number;
}
```

### Rate Limiter 구현 예시

```typescript
class CreonRateLimiter {
  private requestQueue: Queue<CreonApiRequest> = new Queue();
  private requestCount: number = 0;
  private windowStart: number = Date.now();
  private readonly WINDOW_SIZE_MS = 15000; // 15초
  private readonly MAX_REQUESTS = 60;

  async processRequest(request: CreonApiRequest): Promise<BrokerApiResponse> {
    // 우선순위 큐에 추가
    await this.requestQueue.enqueue(request, request.priority);
    
    // Rate limit 체크 및 처리
    await this.waitForRateLimit();
    
    // 실제 API 호출
    return await this.executeCreonApi(request);
  }

  private async waitForRateLimit(): Promise<void> {
    const now = Date.now();
    
    // 윈도우 리셋
    if (now - this.windowStart >= this.WINDOW_SIZE_MS) {
      this.requestCount = 0;
      this.windowStart = now;
    }
    
    // Rate limit 초과시 대기
    if (this.requestCount >= this.MAX_REQUESTS) {
      const waitTime = this.WINDOW_SIZE_MS - (now - this.windowStart);
      await this.sleep(waitTime);
      this.requestCount = 0;
      this.windowStart = Date.now();
    }
    
    this.requestCount++;
  }

  private async executeCreonApi(request: CreonApiRequest): Promise<BrokerApiResponse> {
    const startTime = Date.now();
    
    try {
      let result;
      switch (request.apiMethod) {
        case 'getCandleData':
          result = await this.creonClient.getCandleData(request.params);
          break;
        case 'sendOrder':
          result = await this.creonClient.sendOrder(request.params);
          break;
        // ... 다른 API 메서드들
      }
      
      return {
        requestId: request.requestId,
        correlationId: request.correlationId,
        success: true,
        data: result,
        timestamp: Date.now(),
        executionTimeMs: Date.now() - startTime
      };
    } catch (error) {
      return {
        requestId: request.requestId,
        correlationId: request.correlationId,
        success: false,
        error: {
          code: error.code || 'UNKNOWN_ERROR',
          message: error.message,
          retryAfter: this.calculateRetryAfter()
        },
        timestamp: Date.now(),
        executionTimeMs: Date.now() - startTime
      };
    }
  }
}
```

## 2. PWA 알림 시스템 (Telegram 대체)

### Service Worker 기반 Push 알림

```typescript
// service-worker.ts
self.addEventListener('push', (event) => {
  if (!event.data) return;
  
  const data = event.data.json();
  const options = {
    body: data.message,
    icon: '/icons/jts-icon-192.png',
    badge: '/icons/jts-badge-72.png',
    data: {
      correlationId: data.correlationId,
      tradeType: data.tradeType,
      url: data.url
    },
    actions: [
      {
        action: 'view-trade',
        title: '거래 확인',
        icon: '/icons/view-icon.png'
      },
      {
        action: 'close',
        title: '닫기'
      }
    ],
    requireInteraction: data.priority === 'high',
    vibrate: data.priority === 'high' ? [200, 100, 200] : [100]
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// 알림 클릭 처리
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  if (event.action === 'view-trade') {
    event.waitUntil(
      clients.openWindow(`/trades/${event.notification.data.correlationId}`)
    );
  }
});
```

### PWA 알림 타입 정의

```typescript
interface PushNotificationData {
  title: string;
  message: string;
  priority: 'high' | 'medium' | 'low';
  type: 'trade_executed' | 'risk_alert' | 'system_error' | 'daily_summary';
  correlationId?: string;
  data?: {
    symbol?: string;
    side?: 'buy' | 'sell';
    quantity?: number;
    price?: number;
    pnl?: number;
  };
  url?: string;
  timestamp: number;
}

// 알림 전송 서비스
class NotificationService {
  async sendTradeNotification(trade: TradeExecutionEvent): Promise<void> {
    const notification: PushNotificationData = {
      title: `거래 체결: ${trade.symbol}`,
      message: `${trade.side.toUpperCase()} ${trade.quantity}주 @ ${trade.price}원`,
      priority: 'high',
      type: 'trade_executed',
      correlationId: trade.correlationId,
      data: {
        symbol: trade.symbol,
        side: trade.side,
        quantity: trade.quantity,
        price: trade.price
      },
      url: `/trades/${trade.correlationId}`,
      timestamp: Date.now()
    };
    
    await this.pushToSubscribers(notification);
  }
  
  async sendRiskAlert(alert: RiskAlert): Promise<void> {
    const notification: PushNotificationData = {
      title: '리스크 알림',
      message: `${alert.riskType}: ${alert.message}`,
      priority: 'high',
      type: 'risk_alert',
      correlationId: alert.correlationId,
      timestamp: Date.now()
    };
    
    await this.pushToSubscribers(notification);
  }
}
```

## 3. 개선된 Layer 구조 및 네이밍

### 추천 Layer 네이밍

```
jts-trading-platform/
├── 📁 apps/
│   ├── 📁 presentation/                # 프레젠테이션 계층
│   │   ├── 📁 web-app/                 # React PWA 웹앱
│   │   └── 📁 mobile-app/              # React Native 모바일
│   ├── 📁 gateway/                     # API 게이트웨이 계층
│   │   └── 📁 api-gateway/             # Kong/Express 게이트웨이
│   ├── 📁 business/                    # 비즈니스 로직 계층
│   │   ├── 📁 strategy-engine/         # 전략 실행 엔진
│   │   ├── 📁 risk-management/         # 리스크 관리
│   │   ├── 📁 portfolio-tracker/       # 포트폴리오 추적
│   │   └── 📁 order-execution/         # 주문 실행 (기존 buysell-app)
│   ├── 📁 integration/                 # 통합 서비스 계층
│   │   ├── 📁 market-data-collector/   # 시장데이터 수집 (기존 candle-app)
│   │   └── 📁 notification-service/    # 알림 서비스 (PWA 푸시)
│   ├── 📁 brokers/                     # 브로커 연동 계층
│   │   ├── 📁 creon-service/           # 크레온 API 서비스
│   │   ├── 📁 kis-service/             # 한국투자증권 API
│   │   ├── 📁 binance-service/         # 바이낸스 API
│   │   └── 📁 upbit-service/           # 업비트 API
│   └── 📁 platform/                    # 플랫폼 서비스 계층
│       ├── 📁 monitoring-service/      # 모니터링 서비스
│       └── 📁 configuration-service/   # 설정 관리 서비스
├── 📁 libs/
│   ├── 📁 shared/                      # 공유 라이브러리
│   ├── 📁 messaging/                   # 메시지 브로커 통합 (Kafka + Redis)
│   └── 📁 data/                        # 데이터 계층 (DB 클라이언트들)
└── 📁 infrastructure/                  # 인프라 설정
    ├── 📁 databases/                   # 데이터베이스 설정
    ├── 📁 containers/                  # Docker 설정
    └── 📁 kubernetes/                  # K8s 매니페스트
```

### Messaging Layer (Kafka + Redis) 분리 이유

**messaging을 독립 계층으로 분리하는 것을 추천합니다:**

#### 이유:
1. **기능적 응집성**: Kafka(이벤트 스트리밍) + Redis(캐싱/세션) 모두 데이터 흐름 관리
2. **운영 관점**: 두 시스템 모두 고가용성과 성능이 중요
3. **개발 관점**: 메시지 스키마와 캐싱 전략이 밀접하게 연관
4. **확장성**: 향후 RabbitMQ, ElasticSearch 등 추가시 자연스럽게 포함

```typescript
// libs/messaging/src/index.ts
export { KafkaProducer, KafkaConsumer } from './kafka';
export { RedisClient, RedisCache } from './redis';
export { MessageBroker } from './message-broker';
export { CacheManager } from './cache-manager';

// 통합 메시지 브로커 인터페이스
export interface MessagingService {
  // Kafka 이벤트 스트리밍
  publishEvent(topic: string, event: any): Promise<void>;
  subscribeToEvents(topic: string, handler: EventHandler): void;
  
  // Redis 캐싱
  setCache(key: string, value: any, ttl?: number): Promise<void>;
  getCache(key: string): Promise<any>;
  
  // 분산 락 (Redis 기반)
  acquireLock(resource: string, ttl: number): Promise<boolean>;
  releaseLock(resource: string): Promise<void>;
}
```

## 업데이트된 시스템 아키텍처

```
┌──────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                            │
│                    (PWA + Mobile)                                │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                      Gateway Layer                               │
│                   (API Gateway)                                  │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                    Business Layer                                │
├────────────────┬────────────────┬────────────────┬───────────────┤
│ Strategy Engine│ Risk Management│Portfolio Tracker│Order Execution│
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
│      Kafka (Event Stream)     │        Redis (Cache/Lock)        │
└───────────────────────────────┴──────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                     Brokers Layer                                │
├─────────────┬─────────────┬─────────────┬─────────────────────────┤
│Creon Service│ KIS Service │Binance Serv.│      Upbit Service      │
│(Rate Limit) │(Rate Limit) │(Rate Limit) │      (Rate Limit)       │
└─────────────┴─────────────┴─────────────┴─────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                      Data Layer                                  │
├──────────────┬──────────────┬──────────────┬────────────────────────┤
│ PostgreSQL   │ ClickHouse   │   MongoDB    │     File Storage       │
│(Transactions)│(Time Series) │(Configuration)│    (Logs/Backups)     │
└──────────────┴──────────────┴──────────────┴────────────────────────┘
```

## 핵심 설계 원칙

### 1. Layer 간 통신 규칙
- **상위 계층만 하위 계층 호출**: Presentation → Gateway → Business → Integration → Brokers → Data
- **같은 계층 내 통신**: Messaging Layer를 통해서만 진행
- **의존성 역전**: 인터페이스를 통한 느슨한 결합

### 2. Rate Limiter 패턴
- **각 브로커 서비스 내부에 구현**: 브로커별 특성에 맞는 최적화
- **우선순위 큐**: 거래 실행 > 실시간 데이터 > 히스토리 데이터
- **백프레셔**: Rate limit 초과시 상위 서비스에 대기 신호 전송

### 3. PWA 알림 전략
- **중요도별 알림**: 거래 체결(즉시) > 리스크 알림(즉시) > 일일 요약(배치)
- **오프라인 지원**: Service Worker로 오프라인시에도 알림 큐잉
- **개인화**: 사용자별 알림 설정 및 필터링

이 구조는 각 계층의 책임을 명확히 분리하면서도, 실시간 거래 시스템의 요구사항을 만족하는 확장 가능한 아키텍처를 제공합니다.