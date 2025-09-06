# E13-F06: Security & Resilience Module

## Spec Information

- **Spec ID**: E13-F06
- **Title**: Security & Resilience Module
- **Parent**: E13
- **Type**: Feature
- **Status**: Draft
- **Priority**: Medium
- **Created**: 2025-09-05
- **Updated**: 2025-09-05
- **Dependencies**: E13-F02, E13-F03

## Description

Production-ready security hardening with comprehensive error handling and resilience patterns. This feature implements security controls, rate limiting, input validation, and fault tolerance mechanisms to ensure the spec API remains secure and reliable under various conditions.

## Context

Security and resilience are critical for production deployment of the spec API. This module provides defense-in-depth security controls, protects against common attack vectors, and ensures the service degrades gracefully under failure conditions rather than completely failing.

## Scope

### In Scope

- Rate limiting and throttling
- Request validation and sanitization
- CORS configuration
- Security headers implementation
- Circuit breaker patterns
- Graceful degradation strategies
- Error handling and recovery
- Request logging and auditing
- DDoS protection mechanisms

### Out of Scope

- User authentication/authorization (Phase 2)
- OAuth/JWT implementation
- Role-based access control
- Data encryption at rest
- SSL/TLS configuration (infrastructure)

## Acceptance Criteria

- [ ] Rate limiting prevents API abuse
- [ ] All inputs validated and sanitized
- [ ] Security headers properly configured
- [ ] Circuit breaker prevents cascading failures
- [ ] Graceful degradation under high load
- [ ] Zero security vulnerabilities in OWASP Top 10
- [ ] Comprehensive error logging without data leaks
- [ ] 99.9% uptime with resilience patterns

## Tasks

### T01: Rate Limiting Implementation

**Status**: Draft
**Priority**: Critical

Configure rate limiting to prevent API abuse and ensure fair usage.

**Deliverables**:

- @nestjs/throttler integration
- Endpoint-specific rate limits
- IP-based throttling
- Rate limit headers in responses
- Custom rate limit strategies

---

### T02: Input Validation & Sanitization

**Status**: Draft
**Priority**: Critical

Implement comprehensive input validation to prevent injection attacks.

**Deliverables**:

- Request validation pipes
- Query parameter sanitization
- Path parameter validation
- Body payload validation
- File path traversal prevention

---

### T03: Security Headers

**Status**: Draft
**Priority**: High

Configure security headers to protect against common web vulnerabilities.

**Deliverables**:

- Helmet.js integration
- CSP (Content Security Policy)
- HSTS headers
- X-Frame-Options
- X-Content-Type-Options

---

### T04: Circuit Breaker Pattern

**Status**: Draft
**Priority**: High

Implement circuit breaker to prevent cascading failures in external dependencies.

**Deliverables**:

- Circuit breaker for file operations
- Redis connection circuit breaker
- Failure threshold configuration
- Half-open state testing
- Fallback strategies

---

### T05: Error Handling & Recovery

**Status**: Draft
**Priority**: Medium

Comprehensive error handling with proper logging and recovery mechanisms.

**Deliverables**:

- Global exception filter
- Custom error classes
- Error response standardization
- Stack trace sanitization
- Recovery strategies

---

### T06: Audit Logging

**Status**: Draft
**Priority**: Medium

Implement audit logging for security monitoring and compliance.

**Deliverables**:

- Request/response logging
- Security event logging
- PII data masking
- Log rotation strategy
- Centralized log aggregation

---

### T07: DDoS Protection

**Status**: Draft
**Priority**: Low

Additional protection against distributed denial of service attacks.

**Deliverables**:

- Request size limits
- Connection limits
- Slow request detection
- IP blacklisting capability
- Traffic spike detection

## Technical Architecture

### Module Structure

```
apps/spec-api/src/modules/security/
├── guards/
│   ├── rate-limit.guard.ts
│   └── validation.guard.ts
├── filters/
│   ├── http-exception.filter.ts
│   └── validation-exception.filter.ts
├── interceptors/
│   ├── logging.interceptor.ts
│   └── timeout.interceptor.ts
├── middleware/
│   ├── security-headers.middleware.ts
│   └── request-validation.middleware.ts
├── services/
│   ├── circuit-breaker.service.ts
│   ├── audit-log.service.ts
│   └── threat-detection.service.ts
└── security.module.ts
```

### Rate Limiting Configuration

```typescript
@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60, // Time window in seconds
      limit: 100, // Max requests per window
      ignoreUserAgents: [/bot/i],
      storage: new ThrottlerStorageRedisService({
        host: 'localhost',
        port: 6379,
      }),
    }),
  ],
})
// Endpoint-specific limits
@Controller('api/specs')
export class SpecController {
  @Get()
  @Throttle(200, 60) // 200 requests per minute
  async listSpecs() {}

  @Get('stats')
  @Throttle(50, 60) // 50 requests per minute (expensive)
  async getStats() {}
}
```

### Input Validation

```typescript
// Validation DTOs
class SpecIdParamDto {
  @IsString()
  @Matches(/^E\d{2}(-F\d{2})?(-T\d{2})?$/)
  @MaxLength(20)
  id: string;
}

class QueryParamsDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  @Type(() => Number)
  limit?: number;

  @IsOptional()
  @IsEnum(['draft', 'in_progress', 'completed'])
  status?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  @Transform(({ value }) => sanitize(value))
  search?: string;
}

// Path traversal prevention
class FilePathValidator {
  validate(path: string): boolean {
    // Prevent ../ and absolute paths
    if (path.includes('..') || path.startsWith('/')) {
      throw new BadRequestException('Invalid path');
    }

    // Ensure path is within specs directory
    const resolved = resolve('specs', path);
    if (!resolved.startsWith(resolve('specs'))) {
      throw new ForbiddenException('Path traversal detected');
    }

    return true;
  }
}
```

### Security Headers

```typescript
// Helmet configuration
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
      },
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true,
    },
  }),
);

// CORS configuration
app.enableCors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  methods: ['GET', 'HEAD', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
});
```

### Circuit Breaker Implementation

```typescript
interface CircuitBreakerOptions {
  threshold: number; // Failure threshold
  timeout: number; // Timeout in ms
  resetTimeout: number; // Time before retry
  halfOpenRequests: number; // Requests in half-open state
}

class CircuitBreaker {
  private state: 'closed' | 'open' | 'half-open' = 'closed';
  private failures: number = 0;
  private lastFailureTime?: Date;

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (this.shouldAttemptReset()) {
        this.state = 'half-open';
      } else {
        throw new ServiceUnavailableException('Circuit breaker is open');
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess(): void {
    this.failures = 0;
    if (this.state === 'half-open') {
      this.state = 'closed';
    }
  }

  private onFailure(): void {
    this.failures++;
    this.lastFailureTime = new Date();

    if (this.failures >= this.options.threshold) {
      this.state = 'open';
    }
  }
}
```

### Error Handling

```typescript
@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = 500;
    let message = 'Internal server error';
    let error = 'INTERNAL_ERROR';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const response = exception.getResponse();
      message = response['message'] || exception.message;
      error = response['error'] || 'HTTP_ERROR';
    }

    // Log error without sensitive data
    this.logger.error({
      timestamp: new Date().toISOString(),
      path: request.url,
      method: request.method,
      status,
      error,
      message,
      // Don't log stack in production
      ...(process.env.NODE_ENV !== 'production' && {
        stack: exception['stack'],
      }),
    });

    // Sanitized error response
    response.status(status).json({
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      error,
      message: this.sanitizeMessage(message),
    });
  }

  private sanitizeMessage(message: string): string {
    // Remove sensitive information from error messages
    return message
      .replace(/\/home\/[^\/]+/g, '/***') // Hide file paths
      .replace(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/g, '***.***.***.***'); // Hide IPs
  }
}
```

### Graceful Degradation

```typescript
class DegradationService {
  private loadLevel: 'normal' | 'degraded' | 'critical' = 'normal';

  async executeWithDegradation<T>(
    primaryFn: () => Promise<T>,
    fallbackFn?: () => Promise<T>,
  ): Promise<T> {
    if (this.loadLevel === 'critical' && fallbackFn) {
      return fallbackFn();
    }

    try {
      return await primaryFn();
    } catch (error) {
      if (fallbackFn && this.loadLevel === 'degraded') {
        this.logger.warn('Primary function failed, using fallback');
        return fallbackFn();
      }
      throw error;
    }
  }

  // Degrade features under load
  getDegradedResponse(): any {
    return {
      message: 'Service is under heavy load',
      data: this.getCachedData(),
      degraded: true,
    };
  }
}
```

### Dependencies

- **@nestjs/throttler**: ^5.0.0 - Rate limiting
- **helmet**: ^7.1.0 - Security headers
- **express-rate-limit**: ^7.1.0 - Additional rate limiting
- **joi**: ^17.11.0 - Schema validation
- **winston**: ^3.11.0 - Logging

## Risk Analysis

| Risk                          | Impact | Mitigation                     |
| ----------------------------- | ------ | ------------------------------ |
| DDoS attack                   | High   | Rate limiting, CDN, monitoring |
| Injection attacks             | High   | Input validation, sanitization |
| Circuit breaker too sensitive | Medium | Tunable thresholds, monitoring |
| Over-restrictive security     | Low    | Configurable policies, testing |

## Success Metrics

- Zero security vulnerabilities
- < 0.1% requests blocked by rate limiting
- 99.9% uptime with resilience
- < 1s circuit breaker recovery
- 100% input validation coverage

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [NestJS Security](https://docs.nestjs.com/security/helmet)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [E13-F02 Spec API Gateway](../F02/spec.md)
- [E13 Epic Spec](../E13.spec.md)
