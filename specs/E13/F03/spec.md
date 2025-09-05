# E13-F03: Real-time Updates Engine

## Spec Information
- **Spec ID**: E13-F03
- **Title**: Real-time Updates Engine
- **Parent**: E13
- **Type**: Feature
- **Status**: Draft
- **Priority**: High
- **Created**: 2025-09-05
- **Updated**: 2025-09-05
- **Dependencies**: E13-F01

## Description

WebSocket/SSE implementation for live spec change notifications and real-time collaboration support. This feature enables dashboard users to see spec updates instantly without manual refresh, supporting collaborative spec management workflows.

## Context

The real-time updates engine provides push notifications when spec files change, enabling multiple dashboard users to stay synchronized. It monitors file system changes detected by the parser service and broadcasts updates to connected clients through WebSocket or Server-Sent Events.

## Scope

### In Scope
- WebSocket server implementation with Socket.IO
- Server-Sent Events as fallback option
- File change event broadcasting
- Connection management and cleanup
- Room-based subscriptions for specific specs
- Heartbeat/ping-pong for connection health
- Reconnection handling
- Event filtering and throttling

### Out of Scope
- Collaborative editing (read-only updates)
- Conflict resolution (no concurrent writes)
- Message persistence/history
- User presence tracking
- Chat/messaging features

## Acceptance Criteria

- [ ] Updates delivered within 1 second of file change
- [ ] Support 100+ concurrent WebSocket connections
- [ ] Automatic reconnection on connection loss
- [ ] Graceful degradation to SSE if WebSocket fails
- [ ] Memory-efficient connection pooling
- [ ] Event throttling to prevent flooding
- [ ] Clean connection cleanup on disconnect
- [ ] 90% test coverage for event handling

## Tasks

### T01: WebSocket Server Setup
**Status**: Draft
**Priority**: Critical

Configure Socket.IO server with NestJS integration and proper namespace structure.

**Deliverables**:
- Socket.IO adapter configuration
- WebSocket gateway with @WebSocketGateway
- Namespace structure (/specs)
- CORS configuration for dashboard
- Connection lifecycle handling

---

### T02: Event Broadcasting System
**Status**: Draft
**Priority**: Critical

Implement event emission from file watcher to WebSocket clients with proper typing.

**Deliverables**:
- Event types (spec.created, spec.updated, spec.deleted)
- Event payload DTOs with validation
- Broadcasting to all connected clients
- Event queuing for reliability
- Error handling for broadcast failures

---

### T03: Subscription Management
**Status**: Draft
**Priority**: High

Enable clients to subscribe to specific specs or spec trees for targeted updates.

**Deliverables**:
- Room-based subscriptions (room per spec)
- Subscribe/unsubscribe endpoints
- Wildcard subscriptions (e.g., E13-*)
- Subscription state management
- Room cleanup on empty

---

### T04: SSE Fallback Implementation
**Status**: Draft
**Priority**: Medium

Provide Server-Sent Events as fallback for environments where WebSockets are blocked.

**Deliverables**:
- SSE controller endpoint (/api/events)
- Event stream formatting
- Connection management for SSE
- Automatic fallback detection
- Keep-alive messages

---

### T05: Connection Health Monitoring
**Status**: Draft
**Priority**: Medium

Implement heartbeat mechanism to detect and clean up stale connections.

**Deliverables**:
- Ping-pong interval configuration
- Connection timeout detection
- Automatic cleanup of dead connections
- Connection statistics tracking
- Health check endpoint

---

### T06: Event Throttling & Filtering
**Status**: Draft
**Priority**: Low

Optimize event delivery with intelligent throttling and client-side filtering options.

**Deliverables**:
- Debounce rapid file changes
- Batch multiple changes
- Client-configurable filters
- Rate limiting per connection
- Priority-based event delivery

## Technical Architecture

### Module Structure
```
apps/spec-api/src/modules/realtime/
├── gateways/
│   ├── spec.gateway.ts
│   └── sse.controller.ts
├── services/
│   ├── broadcast.service.ts
│   ├── subscription.service.ts
│   └── connection.service.ts
├── events/
│   ├── spec-change.event.ts
│   └── connection.event.ts
├── dto/
│   └── event-payload.dto.ts
└── realtime.module.ts
```

### WebSocket Events

#### Client → Server
```typescript
// Subscribe to spec updates
{
  event: 'subscribe',
  data: {
    specIds: string[] // ['E13', 'E13-F03']
    includeChildren?: boolean
  }
}

// Unsubscribe from updates
{
  event: 'unsubscribe',
  data: {
    specIds: string[]
  }
}

// Request current subscriptions
{
  event: 'subscriptions',
  data: {}
}
```

#### Server → Client
```typescript
// Spec created
{
  event: 'spec.created',
  data: {
    id: string
    metadata: SpecMetadata
    timestamp: string
  }
}

// Spec updated
{
  event: 'spec.updated',
  data: {
    id: string
    metadata: SpecMetadata
    changes: string[] // Changed fields
    timestamp: string
  }
}

// Spec deleted
{
  event: 'spec.deleted',
  data: {
    id: string
    timestamp: string
  }
}

// Batch update
{
  event: 'specs.batch',
  data: {
    changes: ChangeEvent[]
    timestamp: string
  }
}
```

### Gateway Implementation
```typescript
@WebSocketGateway({
  namespace: '/specs',
  cors: {
    origin: process.env.DASHBOARD_URL,
    credentials: true
  }
})
export class SpecGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server

  @SubscribeMessage('subscribe')
  async handleSubscribe(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: SubscribeDto
  ): Promise<void> {
    // Join rooms for requested specs
    for (const specId of data.specIds) {
      await client.join(`spec:${specId}`)
    }
  }

  async broadcastSpecUpdate(specId: string, event: SpecChangeEvent): Promise<void> {
    this.server
      .to(`spec:${specId}`)
      .emit('spec.updated', event)
  }
}
```

### SSE Implementation
```typescript
@Controller('api/events')
export class SseController {
  @Sse('specs')
  specEvents(): Observable<MessageEvent> {
    return this.broadcastService.getEventStream().pipe(
      map(event => ({
        data: event,
        type: event.type,
        id: event.timestamp
      }))
    )
  }
}
```

### Connection Management
```typescript
interface ConnectionState {
  clientId: string
  connectedAt: Date
  lastPing: Date
  subscriptions: Set<string>
  metadata: {
    userAgent: string
    ip: string
  }
}

class ConnectionService {
  private connections = new Map<string, ConnectionState>()
  
  register(client: Socket): void
  unregister(clientId: string): void
  getActiveConnections(): number
  pruneStale(timeout: number): void
}
```

### Dependencies
- **socket.io**: ^4.6.0 - WebSocket server
- **@nestjs/websockets**: ^10.3.0 - NestJS WebSocket support
- **@nestjs/platform-socket.io**: ^10.3.0 - Socket.IO adapter
- **rxjs**: ^7.8.1 - Reactive event streams

## Risk Analysis

| Risk | Impact | Mitigation |
|------|--------|------------|
| Memory leaks from connections | High | Proper cleanup, connection limits |
| Event flooding | Medium | Throttling, batching, rate limits |
| WebSocket proxy issues | Medium | SSE fallback, documentation |
| Stale connections | Low | Heartbeat monitoring, timeouts |

## Success Metrics

- < 1 second update latency
- Support 100+ concurrent connections
- < 10MB memory per 100 connections
- 99.9% message delivery rate
- Zero memory leaks in 24h test

## References

- [Socket.IO Documentation](https://socket.io/docs/v4/)
- [NestJS WebSockets](https://docs.nestjs.com/websockets/gateways)
- [E13-F01 Spec Parser Service](../F01/spec.md)
- [E13 Epic Spec](../E13.spec.md)