# JTS 서비스 간 통신 아키텍처 및 플랫폼별 배포 전략

## 1. 서비스 간 통신 방식 선택

### 통신 패턴 분석

**"같은 계층 내 통신: Messaging Layer를 통해서만"의 의미 명확화:**

이 설명이 부정확했습니다. 올바른 통신 규칙은 다음과 같습니다:

```
┌──────────────────────────────────────────────────────────────────┐
│                    Business Layer                                │
├────────────────┬────────────────┬────────────────┬───────────────┤
│ Strategy Engine│ Risk Management│Portfolio Tracker│Order Execution│
│      (A)       │       (B)      │       (C)      │      (D)      │
└────────────────┴────────────────┴────────────────┴───────────────┘
         │                │                │               │
         └────────────────┼────────────────┼───────────────┘
                          │                │
                ┌─────────────────┐       │
                │     Kafka       │       │
                │ (Event Stream)  │       │
                └─────────────────┘       │
                          │               │
                          └───────────────┘

통신 규칙:
- A → B: 직접 HTTP/gRPC 호출 (동기)
- A → C: Kafka 이벤트 (비동기)
- B → D: 직접 HTTP/gRPC 호출 (동기)
```

### HTTP vs gRPC 선택 기준

| 통신 유형              | 권장 방식 | 이유                     | JTS 적용 예시                                   |
| ---------------------- | --------- | ------------------------ | ----------------------------------------------- |
| **실시간 동기 요청**   | gRPC      | 저지연, 타입 안전성      | Strategy Engine → Risk Management (리스크 체크) |
| **단순 REST API**      | HTTP      | 개발 편의성, 디버깅 용이 | Web App → API Gateway                           |
| **이벤트 기반 비동기** | Kafka     | 확장성, 장애 허용성      | Order Execution → Portfolio Tracker (체결 알림) |
| **외부 API 연동**      | HTTP      | 표준 호환성              | KIS API, Binance API                            |

### 권장 통신 아키텍처

```typescript
// gRPC 서비스 정의 (proto 파일)
syntax = "proto3";

service RiskManagementService {
  // 동기 리스크 체크 (빠른 응답 필요)
  rpc CheckTradingRisk(RiskCheckRequest) returns (RiskCheckResponse);

  // 포지션 사이징 계산
  rpc CalculatePositionSize(PositionSizeRequest) returns (PositionSizeResponse);
}

service PortfolioService {
  // 실시간 포트폴리오 조회
  rpc GetCurrentPortfolio(PortfolioRequest) returns (PortfolioResponse);

  // 포지션 업데이트 (스트리밍)
  rpc StreamPositionUpdates(Empty) returns (stream PositionUpdate);
}

message RiskCheckRequest {
  string correlation_id = 1;
  string symbol = 2;
  double quantity = 3;
  double price = 4;
  string side = 5; // "buy" or "sell"
  Portfolio current_portfolio = 6;
}

message RiskCheckResponse {
  bool approved = 1;
  double adjusted_quantity = 2;
  string rejection_reason = 3;
  double risk_score = 4;
}
```

### 실제 구현 예시

```typescript
// Strategy Engine에서 Risk Management 호출
class StrategyEngineService {
  constructor(
    private riskClient: RiskManagementClient,
    private kafkaProducer: KafkaProducer,
  ) {}

  async processTradingSignal(signal: TradingSignal): Promise<void> {
    const correlationId = signal.correlationId;

    // 1. 동기 리스크 체크 (gRPC)
    const riskCheck = await this.riskClient.checkTradingRisk({
      correlationId,
      symbol: signal.symbol,
      quantity: signal.quantity,
      price: signal.price,
      side: signal.side,
      currentPortfolio: await this.getPortfolio(),
    });

    if (!riskCheck.approved) {
      await this.kafkaProducer.send({
        topic: 'risk.alerts',
        value: {
          correlationId,
          reason: riskCheck.rejectionReason,
          signal,
        },
      });
      return;
    }

    // 2. 주문 실행 이벤트 발행 (Kafka)
    await this.kafkaProducer.send({
      topic: 'orders.signals',
      value: {
        correlationId,
        symbol: signal.symbol,
        quantity: riskCheck.adjustedQuantity,
        price: signal.price,
        side: signal.side,
        approvedAt: new Date().toISOString(),
      },
    });
  }
}
```

## 2. 플랫폼별 코드 분리 전략

### Nx 조건부 빌드 설정

#### 프로젝트 구조

```
apps/
├── brokers/
│   ├── creon-service/           # Windows 전용
│   │   ├── project.json
│   │   ├── src/
│   │   │   ├── main.py         # FastAPI 메인
│   │   │   ├── creon_client.py # Creon API 래퍼
│   │   │   └── rate_limiter.py
│   │   ├── Dockerfile.windows  # Windows 컨테이너
│   │   └── requirements.txt
│   ├── kis-service/            # Linux/Windows 공용
│   ├── binance-service/        # Linux/Windows 공용
│   └── upbit-service/          # Linux/Windows 공용
```

#### Nx 설정 (project.json)

```json
// apps/brokers/creon-service/project.json
{
  "name": "creon-service",
  "root": "apps/brokers/creon-service",
  "sourceRoot": "apps/brokers/creon-service/src",
  "projectType": "application",
  "targets": {
    "serve": {
      "executor": "@nx/python:execute",
      "options": {
        "command": "python",
        "args": ["src/main.py"]
      },
      "configurations": {
        "windows": {
          "command": "python",
          "args": ["src/main.py", "--platform=windows"]
        }
      }
    },
    "build": {
      "executor": "@nx/python:build",
      "options": {
        "outputPath": "dist/apps/creon-service"
      }
    },
    "docker-build-windows": {
      "executor": "@nx-tools/nx-docker:build",
      "options": {
        "context": ".",
        "file": "apps/brokers/creon-service/Dockerfile.windows",
        "tags": ["jts/creon-service:windows-latest"],
        "platforms": ["windows/amd64"]
      }
    }
  },
  "tags": ["broker", "windows-only", "python"]
}
```

#### 루트 package.json 스크립트

```json
{
  "scripts": {
    "build:linux": "nx run-many --target=build --exclude=*windows* --parallel",
    "build:windows": "nx run-many --target=build --projects=creon-service --parallel",
    "serve:linux": "nx run-many --target=serve --exclude=*windows* --parallel",
    "serve:windows": "nx serve creon-service:windows",

    "docker:linux": "nx run-many --target=docker-build --exclude=*windows*",
    "docker:windows": "nx docker-build-windows creon-service",

    "deploy:hybrid": "npm run docker:linux && npm run docker:windows"
  }
}
```

### 조건부 컴파일/실행

#### Python FastAPI (Windows 전용)

```python
# apps/brokers/creon-service/src/main.py
import os
import platform
from fastapi import FastAPI, HTTPException
from typing import Optional

# 플랫폼 체크
if platform.system() != "Windows":
    raise RuntimeError("Creon service can only run on Windows")

try:
    # Creon API는 Windows에서만 import 가능
    import win32com.client as win32
    from creon_client import CreonClient
except ImportError as e:
    raise RuntimeError(f"Creon dependencies not available: {e}")

app = FastAPI(title="JTS Creon Service", version="1.0.0")

creon_client: Optional[CreonClient] = None

@app.on_event("startup")
async def startup_event():
    global creon_client
    creon_client = CreonClient()
    await creon_client.initialize()

@app.post("/api/v1/market-data/candles")
async def get_candle_data(request: CandleDataRequest):
    if not creon_client:
        raise HTTPException(status_code=503, detail="Creon client not initialized")

    try:
        result = await creon_client.get_candle_data(
            symbol=request.symbol,
            timeframe=request.timeframe,
            start_date=request.start_date,
            end_date=request.end_date
        )
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
```

#### Docker 설정

```dockerfile
# apps/brokers/creon-service/Dockerfile.windows
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Python 설치
RUN powershell -Command \
    Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe' -OutFile 'python-installer.exe' ; \
    Start-Process python-installer.exe -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait ; \
    Remove-Item python-installer.exe

# 작업 디렉토리 설정
WORKDIR /app

# 의존성 설치
COPY apps/brokers/creon-service/requirements.txt .
RUN pip install -r requirements.txt

# 애플리케이션 코드 복사
COPY apps/brokers/creon-service/src/ ./src/
COPY libs/shared/ ./libs/shared/

# 포트 노출
EXPOSE 8001

# 실행 명령
CMD ["python", "src/main.py"]
```

### 개발 환경 분리

#### .env 파일 분리

```bash
# .env.linux
NODE_ENV=development
PLATFORM=linux
EXCLUDED_SERVICES=creon-service

# .env.windows
NODE_ENV=development
PLATFORM=windows
INCLUDED_SERVICES=creon-service
CREON_API_PATH=C:/PLUS/
```

#### 조건부 실행 스크립트

```bash
#!/bin/bash
# scripts/dev-linux.sh
export $(cat .env.linux | xargs)
nx run-many --target=serve --exclude=creon-service --parallel

# scripts/dev-windows.bat (Windows)
@echo off
for /f "tokens=*" %%a in (.env.windows) do set %%a
nx serve creon-service
```

## 3. Windows FastAPI와 전체 아키텍처 연결점

### 아키텍처 내 위치

```
┌──────────────────────────────────────────────────────────────────┐
│                     Integration Layer                            │
├───────────────────────────────┬──────────────────────────────────┤
│     Market Data Collector     │     Notification Service         │
│        (Linux)                │          (Linux)                 │
└───────────────────────────────┴──────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                    Messaging Layer                               │
├───────────────────────────────┬──────────────────────────────────┤
│      Kafka (Event Stream)     │        Redis (Cache/Lock)        │
│          (Linux)              │           (Linux)                │
└───────────────────────────────┴──────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                     Brokers Layer                                │
├─────────────┬─────────────┬─────────────┬─────────────────────────┤
│Creon Service│ KIS Service │Binance Serv.│      Upbit Service      │
│ (Windows11) │  (Linux)    │  (Linux)    │       (Linux)           │
│  FastAPI    │   Node.js   │   Node.js   │       Node.js           │
└─────────────┴─────────────┴─────────────┴─────────────────────────┘
```

### 연결 방식

**1. HTTP API 통합:**

```typescript
// libs/shared/api-client/src/creon.client.ts
export class CreonApiClient {
  private baseUrl: string;

  constructor(config: { windowsHost: string; port: number }) {
    this.baseUrl = `http://${config.windowsHost}:${config.port}`;
  }

  async getCandleData(request: CandleDataRequest): Promise<CandleData[]> {
    const response = await fetch(`${this.baseUrl}/api/v1/market-data/candles`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error(`Creon API error: ${response.statusText}`);
    }

    return response.json();
  }
}
```

**2. Market Data Collector에서 호출:**

```typescript
// apps/integration/market-data-collector/src/collectors/creon.collector.ts
export class CreonDataCollector implements DataCollector {
  constructor(
    private creonClient: CreonApiClient,
    private kafkaProducer: KafkaProducer,
  ) {}

  async collectDailyCandles(symbols: string[]): Promise<void> {
    for (const symbol of symbols) {
      try {
        const candleData = await this.creonClient.getCandleData({
          symbol,
          timeframe: '1D',
          startDate: this.getYesterday(),
          endDate: this.getToday(),
        });

        // Kafka로 정규화된 데이터 발행
        await this.kafkaProducer.send({
          topic: 'market-data.krx.candles',
          key: symbol,
          value: this.normalizeData(candleData),
        });
      } catch (error) {
        await this.handleError(symbol, error);
      }
    }
  }
}
```

**3. 네트워크 설정:**

```yaml
# docker-compose.yml
version: '3.8'
services:
  market-data-collector:
    build: ./apps/integration/market-data-collector
    networks:
      - jts-network
    environment:
      - CREON_API_HOST=192.168.1.100 # Windows 머신 IP
      - CREON_API_PORT=8001
    depends_on:
      - kafka
      - redis

networks:
  jts-network:
    external: true # Windows 머신과 통신 가능한 브리지 네트워크
```

### 하이브리드 배포 전략

```bash
# 배포 스크립트
#!/bin/bash

# Linux 서비스들 배포
docker-compose -f docker-compose.linux.yml up -d

# Windows 서비스 수동 시작 (Windows 머신에서)
# python apps/brokers/creon-service/src/main.py

# 연결성 테스트
curl http://192.168.1.100:8001/health
```

## 핵심 설계 원칙

### 1. 플랫폼 격리

- **Linux**: 모든 비즈니스 로직 서비스
- **Windows**: Creon API만 FastAPI로 분리
- **통신**: HTTP REST API로 플랫폼 간 통신

### 2. 장애 격리

- Windows 머신 장애시에도 다른 브로커(KIS, Binance) 서비스는 정상 동작
- Circuit Breaker 패턴으로 Creon API 장애 감지 및 대응

### 3. 개발 효율성

- 개발자는 Linux에서 대부분 작업
- Windows는 Creon API 래퍼만 개발
- 타입 안전성은 공통 인터페이스로 보장

이 아키텍처는 Windows 종속성을 최소화하면서도 JTS 시스템의 통합성을 유지하는 최적의 설계입니다.
