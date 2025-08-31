# CLAUDE.md - Optimized for Token Efficiency

## Quick Context

**Project**: JTS - Automated trading system (NestJS/TypeScript)
**Architecture**: Microservices, Docker, Nx monorepo
**DBs**: PostgreSQL, ClickHouse, MongoDB, Redis
**Queue**: Kafka | **APIs**: REST, gRPC, WebSocket

## Critical Rules

1. **NEVER** create files unless explicitly needed
2. **ALWAYS** edit existing files over creating new
3. **NO** documentation files unless requested
4. **NO** comments in code unless asked
5. **USE** existing patterns and libraries

## Commands Reference

```bash
npm install          # Install deps
npm run dev          # Start dev
npm run test         # Run tests
npm run lint         # Lint
npm run type-check   # TypeScript check
npx nx test <svc>    # Test specific service
npx nx serve <svc>   # Run specific service
```

## Spec Work Flow

```bash
# Capture discussions BEFORE implementation
/spec_work {id} --discussion "what was discussed"

# Track spec changes
/spec_work {id} --revision "what changed"

# Start implementation
/spec_work {id}

# Update index after completion
/spec_work --update-index
```

## Service Structure

```
apps/
  {service}/
    src/
      app/          # Main module
      domain/       # Business logic
      infra/        # External integrations
      shared/       # Common utilities
libs/
  common/          # Shared types/utils
```

## Database Guidelines

- PostgreSQL: Business data (users, orders)
- ClickHouse: Time-series market data
- MongoDB: Config/strategy params
- Redis: Cache, sessions, rate limiting

## Testing Standards

- 95% coverage for trading logic
- Mock external APIs
- Use existing test utilities
- Integration tests for service communication

## Security

- Env vars for secrets only
- TLS for all service comms
- Multi-factor for trading orders
- Never log sensitive data

## Performance

- Stream market data
- Cache in Redis
- Connection pooling
- Optimize time-series queries

## Broker Integration

- Creon (Windows/COM): Korean markets
- Rate limits: 200/min, 20/sec
- Implement circuit breaker
- Retry with exponential backoff

## Git Commits

```bash
# Format
type(scope): description

# Types
feat: New feature
fix: Bug fix
test: Testing
docs: Documentation
refactor: Code restructure
perf: Performance
chore: Maintenance
```

## File Context Rules

1. Read existing code patterns first
2. Check package.json for available libs
3. Follow existing naming conventions
4. Use TypeScript strict mode
5. Implement proper error handling

## Token Saving Tips

- Use `@file` references instead of explaining
- Batch related operations
- Skip obvious confirmations
- Focus on implementation, not explanation
- Let context files track history
