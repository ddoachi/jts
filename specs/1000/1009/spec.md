---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '1009' # Numeric ID for stable reference
title: 'Security Foundation'
type: 'feature' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '1000' # Parent spec ID
children: [] # Child spec IDs (if any)
epic: '1000' # Root epic ID for this work
domain: 'infrastructure' # Business domain

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'high' # high | medium | low

# === TRACKING ===
created: '2025-08-24' # YYYY-MM-DD
updated: '2025-08-24' # YYYY-MM-DD
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 16 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: ['1003', '1005', '1007'] # Must be done before this (spec IDs)
blocks: ['2000', '3000', '4000', '5000', '6000'] # This blocks these specs (spec IDs)
related: ['1008'] # Related but not blocking (spec IDs)

# === IMPLEMENTATION ===
branch: 'feature/1009-security-foundation' # Git branch name
files: ['infrastructure/security/', 'libs/shared/security/', 'libs/shared/auth/', 'apps/api-gateway/src/auth/', 'docker-compose.security.yml', '.env.security'] # Key files to modify

# === METADATA ===
tags: ['security', 'authentication', 'authorization', 'jwt', 'ssl', 'tls', 'secrets', 'rate-limiting', 'compliance', 'scanning'] # Searchable tags
effort: 'large' # small | medium | large | epic
risk: 'high' # low | medium | high

# ============================================================================
---

# Security Foundation

## Overview

Establish comprehensive security infrastructure for the JTS automated trading system, implementing enterprise-grade authentication, authorization, API security, secrets management, SSL/TLS configuration, and security scanning capabilities. This feature creates the foundational security layer that protects critical trading operations, sensitive financial data, and ensures regulatory compliance across all system components.

## Acceptance Criteria

- [ ] **JWT Authentication System**: Complete JWT-based authentication with refresh tokens, secure token storage, and automatic token rotation
- [ ] **Role-Based Authorization**: Granular RBAC system with trading-specific permissions, resource-based access control, and audit logging
- [ ] **API Security Framework**: Comprehensive API protection including rate limiting, request validation, input sanitization, and CORS configuration
- [ ] **Secrets Management**: Production-ready secrets management using HashiCorp Vault with automatic secret rotation and encryption at rest
- [ ] **SSL/TLS Configuration**: Full SSL/TLS implementation with certificate management, perfect forward secrecy, and HSTS enforcement
- [ ] **Security Scanning Integration**: Automated vulnerability scanning with OWASP ZAP, dependency scanning, and container security analysis
- [ ] **Multi-Factor Authentication**: TOTP-based 2FA for administrative access and high-privilege trading operations
- [ ] **API Rate Limiting**: Advanced rate limiting with sliding windows, IP-based limits, and user-based quotas
- [ ] **Security Headers**: Complete security header configuration including CSP, HSTS, X-Frame-Options, and anti-clickjacking protection
- [ ] **Audit Logging**: Comprehensive security event logging with tamper-proof audit trails and compliance reporting

## Technical Approach

### Comprehensive Security Architecture

Implement a defense-in-depth security model specifically designed for high-frequency trading systems with strict compliance requirements and zero-tolerance for security breaches:

**Security Stack Components:**
- **Authentication**: JWT with RS256 signing, refresh token rotation, and session management
- **Authorization**: Attribute-based access control (ABAC) with trading-specific permissions
- **API Security**: Multi-layer protection with rate limiting, input validation, and threat detection
- **Secrets Management**: HashiCorp Vault with dynamic secrets and encryption as a service
- **Network Security**: TLS 1.3, certificate pinning, and network segmentation
- **Monitoring**: Real-time security event monitoring with automated incident response

### Key Components

#### 1. JWT Authentication and Authorization System
**Purpose**: Secure, stateless authentication for all system components with fine-grained authorization
**Key Features**:
- RS256 JWT signing with rotating keys
- Refresh token mechanism with secure storage
- Role-based and attribute-based access control
- Trading-specific permissions (view positions, execute orders, modify strategies)
- Multi-factor authentication integration
- Session management with concurrent session limits

**JWT Implementation Strategy**:
```typescript
// libs/shared/auth/src/lib/jwt.service.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService as NestJwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { Redis } from 'ioredis';

@Injectable()
export class JwtAuthService {
  private readonly accessTokenExpiry = '15m';
  private readonly refreshTokenExpiry = '7d';
  private readonly jwtAlgorithm = 'RS256';
  
  constructor(
    private readonly jwtService: NestJwtService,
    private readonly configService: ConfigService,
    private readonly redis: Redis
  ) {}

  // Generate secure JWT token pair
  async generateTokenPair(user: User, deviceId: string): Promise<TokenPair> {
    const jti = crypto.randomUUID();
    const sessionId = crypto.randomUUID();
    
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      roles: user.roles.map(r => r.name),
      permissions: this.extractPermissions(user.roles),
      deviceId,
      sessionId,
      jti,
      iat: Math.floor(Date.now() / 1000),
      tokenType: 'access'
    };

    const accessToken = this.jwtService.sign(payload, {
      expiresIn: this.accessTokenExpiry,
      algorithm: this.jwtAlgorithm,
      keyid: await this.getCurrentKeyId()
    });

    const refreshPayload = {
      sub: user.id,
      sessionId,
      jti: crypto.randomUUID(),
      tokenType: 'refresh'
    };

    const refreshToken = this.jwtService.sign(refreshPayload, {
      expiresIn: this.refreshTokenExpiry,
      algorithm: this.jwtAlgorithm,
      keyid: await this.getCurrentKeyId()
    });

    // Store session information
    await this.storeSession(sessionId, {
      userId: user.id,
      deviceId,
      accessJti: jti,
      refreshJti: refreshPayload.jti,
      createdAt: new Date(),
      lastActivity: new Date(),
      ipAddress: payload.ipAddress,
      userAgent: payload.userAgent
    });

    return { accessToken, refreshToken, expiresIn: 900 }; // 15 minutes
  }

  // Validate and decode JWT token
  async validateToken(token: string): Promise<JwtPayload> {
    try {
      const payload = this.jwtService.verify(token, {
        algorithms: [this.jwtAlgorithm],
        ignoreExpiration: false
      }) as JwtPayload;

      // Check if token is revoked
      const isRevoked = await this.redis.get(`revoked:${payload.jti}`);
      if (isRevoked) {
        throw new UnauthorizedException('Token has been revoked');
      }

      // Check session validity
      const session = await this.getSession(payload.sessionId);
      if (!session || session.accessJti !== payload.jti) {
        throw new UnauthorizedException('Invalid session');
      }

      // Update last activity
      await this.updateSessionActivity(payload.sessionId);

      return payload;
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }

  // Refresh access token
  async refreshToken(refreshToken: string): Promise<TokenPair> {
    const payload = this.jwtService.verify(refreshToken) as JwtPayload;
    
    if (payload.tokenType !== 'refresh') {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const session = await this.getSession(payload.sessionId);
    if (!session || session.refreshJti !== payload.jti) {
      throw new UnauthorizedException('Invalid refresh session');
    }

    const user = await this.getUserById(payload.sub);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Generate new token pair
    return this.generateTokenPair(user, session.deviceId);
  }

  // Revoke token (logout)
  async revokeToken(token: string): Promise<void> {
    const payload = this.jwtService.decode(token) as JwtPayload;
    
    // Add to revocation list
    await this.redis.setex(
      `revoked:${payload.jti}`,
      payload.exp - Math.floor(Date.now() / 1000),
      'true'
    );

    // Remove session
    await this.removeSession(payload.sessionId);
  }

  // Extract trading permissions from roles
  private extractPermissions(roles: Role[]): string[] {
    const permissions = new Set<string>();
    
    roles.forEach(role => {
      role.permissions.forEach(permission => {
        permissions.add(permission.name);
      });
    });

    return Array.from(permissions);
  }

  // Rotate JWT signing keys
  async rotateSigningKeys(): Promise<void> {
    const newKeyPair = crypto.generateKeyPairSync('rsa', {
      modulusLength: 2048,
      publicKeyEncoding: { type: 'spki', format: 'pem' },
      privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
    });

    const keyId = crypto.randomUUID();
    
    // Store new key pair
    await this.storeKeyPair(keyId, newKeyPair);
    
    // Update current key ID
    await this.redis.set('current_key_id', keyId);
    
    // Schedule old key cleanup (after token expiry)
    setTimeout(() => {
      this.cleanupOldKeys();
    }, 24 * 60 * 60 * 1000); // 24 hours
  }
}

// JWT Authorization Guard
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtAuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);

    if (!token) {
      throw new UnauthorizedException('No token provided');
    }

    try {
      const payload = await this.jwtService.validateToken(token);
      request.user = payload;
      return true;
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}

// Permission-based authorization decorator
export const RequirePermissions = (...permissions: string[]) =>
  SetMetadata('permissions', permissions);

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredPermissions = this.reflector.get<string[]>(
      'permissions',
      context.getHandler()
    );

    if (!requiredPermissions) {
      return true;
    }

    const user = context.switchToHttp().getRequest().user;
    
    return requiredPermissions.every(permission =>
      user.permissions?.includes(permission)
    );
  }
}
```

#### 2. API Security and Rate Limiting
**Purpose**: Comprehensive API protection against abuse, DDoS attacks, and unauthorized access
**Key Features**:
- Advanced rate limiting with sliding windows and burst protection
- Request validation and input sanitization
- CORS configuration for cross-origin requests
- API versioning and deprecation management
- Real-time threat detection and blocking

**API Security Implementation**:
```typescript
// libs/shared/security/src/lib/rate-limiting.service.ts
import { Injectable } from '@nestjs/common';
import { Redis } from 'ioredis';
import { ConfigService } from '@nestjs/config';

export interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  keyGenerator?: (req: any) => string;
  skipIf?: (req: any) => boolean;
  onLimitReached?: (req: any) => void;
}

@Injectable()
export class RateLimitingService {
  constructor(
    private readonly redis: Redis,
    private readonly configService: ConfigService
  ) {}

  // Sliding window rate limiter
  async checkRateLimit(
    identifier: string,
    config: RateLimitConfig
  ): Promise<{ allowed: boolean; remaining: number; resetTime: number }> {
    const now = Date.now();
    const window = config.windowMs;
    const windowStart = now - window;
    
    const pipeline = this.redis.pipeline();
    
    // Remove expired entries
    pipeline.zremrangebyscore(identifier, 0, windowStart);
    
    // Add current request
    pipeline.zadd(identifier, now, `${now}-${Math.random()}`);
    
    // Count requests in window
    pipeline.zcard(identifier);
    
    // Set expiry
    pipeline.expire(identifier, Math.ceil(window / 1000));
    
    const results = await pipeline.exec();
    const requestCount = results[2][1] as number;
    
    const allowed = requestCount <= config.maxRequests;
    const remaining = Math.max(0, config.maxRequests - requestCount);
    const resetTime = now + window;

    if (!allowed && config.onLimitReached) {
      config.onLimitReached({ identifier, requestCount, window });
    }

    return { allowed, remaining, resetTime };
  }

  // Advanced rate limiting with multiple tiers
  async checkTieredRateLimit(
    userId: string,
    endpoint: string,
    userTier: 'basic' | 'premium' | 'enterprise' = 'basic'
  ): Promise<RateLimitResult> {
    const configs = this.getTierConfigs(userTier);
    const checks = await Promise.all([
      // Per-user global limit
      this.checkRateLimit(`user:${userId}:global`, configs.global),
      // Per-user per-endpoint limit
      this.checkRateLimit(`user:${userId}:${endpoint}`, configs.endpoint),
      // Global endpoint limit
      this.checkRateLimit(`endpoint:${endpoint}:global`, configs.endpointGlobal)
    ]);

    const mostRestrictive = checks.reduce((prev, current) => 
      current.remaining < prev.remaining ? current : prev
    );

    return {
      allowed: checks.every(check => check.allowed),
      remaining: mostRestrictive.remaining,
      resetTime: mostRestrictive.resetTime,
      limits: {
        global: checks[0],
        endpoint: checks[1],
        endpointGlobal: checks[2]
      }
    };
  }

  // Trading-specific rate limiting
  async checkTradingRateLimit(
    userId: string,
    action: 'place_order' | 'cancel_order' | 'modify_order' | 'query_positions'
  ): Promise<RateLimitResult> {
    const tradingConfigs = {
      place_order: { windowMs: 60000, maxRequests: 100 },    // 100 orders per minute
      cancel_order: { windowMs: 60000, maxRequests: 200 },   // 200 cancels per minute
      modify_order: { windowMs: 60000, maxRequests: 150 },   // 150 modifications per minute
      query_positions: { windowMs: 1000, maxRequests: 10 }   // 10 queries per second
    };

    return this.checkRateLimit(
      `user:${userId}:trading:${action}`,
      tradingConfigs[action]
    );
  }

  private getTierConfigs(tier: string) {
    const baseConfigs = {
      basic: {
        global: { windowMs: 60000, maxRequests: 1000 },
        endpoint: { windowMs: 60000, maxRequests: 100 },
        endpointGlobal: { windowMs: 1000, maxRequests: 1000 }
      },
      premium: {
        global: { windowMs: 60000, maxRequests: 5000 },
        endpoint: { windowMs: 60000, maxRequests: 500 },
        endpointGlobal: { windowMs: 1000, maxRequests: 2000 }
      },
      enterprise: {
        global: { windowMs: 60000, maxRequests: 20000 },
        endpoint: { windowMs: 60000, maxRequests: 2000 },
        endpointGlobal: { windowMs: 1000, maxRequests: 5000 }
      }
    };

    return baseConfigs[tier] || baseConfigs.basic;
  }
}

// API Security Middleware
@Injectable()
export class ApiSecurityMiddleware implements NestMiddleware {
  constructor(
    private readonly rateLimitingService: RateLimitingService,
    private readonly logger: Logger
  ) {}

  async use(req: Request, res: Response, next: NextFunction) {
    // Input validation and sanitization
    await this.validateAndSanitizeInput(req);
    
    // Rate limiting
    await this.applyRateLimit(req, res);
    
    // Security headers
    this.setSecurityHeaders(res);
    
    // Request logging for security monitoring
    this.logSecurityEvent(req);
    
    next();
  }

  private async validateAndSanitizeInput(req: Request): Promise<void> {
    // Validate content type
    if (req.method !== 'GET' && req.headers['content-type']) {
      const contentType = req.headers['content-type'].toLowerCase();
      if (!contentType.includes('application/json') && 
          !contentType.includes('application/x-www-form-urlencoded')) {
        throw new BadRequestException('Unsupported content type');
      }
    }

    // Validate request size
    const contentLength = parseInt(req.headers['content-length'] || '0');
    if (contentLength > 10 * 1024 * 1024) { // 10MB limit
      throw new PayloadTooLargeException('Request payload too large');
    }

    // SQL injection prevention
    if (req.body) {
      this.detectSqlInjection(JSON.stringify(req.body));
    }
    
    // XSS prevention
    this.sanitizeXSS(req);
  }

  private async applyRateLimit(req: Request, res: Response): Promise<void> {
    const identifier = this.getRateLimitIdentifier(req);
    const config = this.getRateLimitConfig(req);
    
    const result = await this.rateLimitingService.checkRateLimit(identifier, config);
    
    // Set rate limit headers
    res.setHeader('X-RateLimit-Limit', config.maxRequests);
    res.setHeader('X-RateLimit-Remaining', result.remaining);
    res.setHeader('X-RateLimit-Reset', result.resetTime);
    
    if (!result.allowed) {
      throw new TooManyRequestsException('Rate limit exceeded');
    }
  }

  private setSecurityHeaders(res: Response): void {
    // Security headers for API protection
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
    
    // HSTS for HTTPS connections
    if (req.secure) {
      res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
    }
    
    // CSP for API endpoints
    res.setHeader('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
  }

  private detectSqlInjection(input: string): void {
    const sqlInjectionPatterns = [
      /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|ALTER|CREATE)\b)/gi,
      /(\b(OR|AND)\s+\d+\s*=\s*\d+)/gi,
      /(\'|\";?\s*(OR|AND|SELECT|INSERT|UPDATE|DELETE))/gi,
      /(\bEXEC\s*\()/gi
    ];

    for (const pattern of sqlInjectionPatterns) {
      if (pattern.test(input)) {
        this.logger.warn('SQL injection attempt detected', { input: input.substring(0, 200) });
        throw new BadRequestException('Invalid input detected');
      }
    }
  }

  private sanitizeXSS(req: Request): void {
    const xssPatterns = [
      /<script[^>]*>.*?<\/script>/gi,
      /javascript:/gi,
      /on\w+\s*=/gi,
      /<iframe[^>]*>.*?<\/iframe>/gi
    ];

    const checkForXSS = (obj: any): void => {
      if (typeof obj === 'string') {
        for (const pattern of xssPatterns) {
          if (pattern.test(obj)) {
            this.logger.warn('XSS attempt detected', { value: obj.substring(0, 100) });
            throw new BadRequestException('Invalid input detected');
          }
        }
      } else if (typeof obj === 'object' && obj !== null) {
        Object.values(obj).forEach(checkForXSS);
      }
    };

    if (req.body) {
      checkForXSS(req.body);
    }
    
    if (req.query) {
      checkForXSS(req.query);
    }
  }
}
```

#### 3. Secrets Management with HashiCorp Vault
**Purpose**: Secure storage, rotation, and management of all application secrets and certificates
**Key Features**:
- Dynamic secrets generation for database connections
- Automatic secret rotation with zero-downtime updates
- Encrypted storage with multiple authentication methods
- Audit logging for all secret access
- Integration with CI/CD pipelines for secure deployment

**Vault Integration Implementation**:
```typescript
// libs/shared/security/src/lib/vault.service.ts
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as vault from 'node-vault';

@Injectable()
export class VaultService implements OnModuleInit {
  private readonly logger = new Logger(VaultService.name);
  private vaultClient: any;
  private isInitialized = false;

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit() {
    await this.initialize();
  }

  private async initialize(): Promise<void> {
    const vaultConfig = {
      apiVersion: 'v1',
      endpoint: this.configService.get<string>('VAULT_ENDPOINT', 'http://localhost:8200'),
      token: this.configService.get<string>('VAULT_TOKEN'),
      requestOptions: {
        timeout: 5000,
        headers: {
          'X-Vault-Request': 'true'
        }
      }
    };

    this.vaultClient = vault(vaultConfig);

    try {
      // Verify vault connection and authentication
      const health = await this.vaultClient.health();
      this.logger.log(`Vault connection established. Sealed: ${health.sealed}, Version: ${health.version}`);

      // Initialize KV secrets engine if needed
      await this.ensureSecretsEngine();
      
      this.isInitialized = true;
    } catch (error) {
      this.logger.error('Failed to initialize Vault connection', error.message);
      throw error;
    }
  }

  // Get secret from Vault
  async getSecret(path: string): Promise<any> {
    this.ensureInitialized();
    
    try {
      const response = await this.vaultClient.read(`kv/data/${path}`);
      this.logger.debug(`Secret retrieved from path: ${path}`);
      return response.data?.data;
    } catch (error) {
      this.logger.error(`Failed to retrieve secret from path: ${path}`, error.message);
      throw error;
    }
  }

  // Store secret in Vault
  async setSecret(path: string, data: Record<string, any>): Promise<void> {
    this.ensureInitialized();
    
    try {
      await this.vaultClient.write(`kv/data/${path}`, { data });
      this.logger.log(`Secret stored at path: ${path}`);
    } catch (error) {
      this.logger.error(`Failed to store secret at path: ${path}`, error.message);
      throw error;
    }
  }

  // Get database credentials with automatic rotation
  async getDatabaseCredentials(database: string): Promise<DatabaseCredentials> {
    this.ensureInitialized();
    
    try {
      const response = await this.vaultClient.read(`database/creds/${database}`);
      
      return {
        username: response.data.username,
        password: response.data.password,
        leaseId: response.lease_id,
        leaseDuration: response.lease_duration,
        renewable: response.renewable
      };
    } catch (error) {
      this.logger.error(`Failed to get database credentials for: ${database}`, error.message);
      throw error;
    }
  }

  // Generate JWT signing key pair
  async generateJwtKeyPair(): Promise<{ publicKey: string; privateKey: string; keyId: string }> {
    this.ensureInitialized();
    
    try {
      const response = await this.vaultClient.write('transit/keys/jwt-signing', {
        type: 'rsa-2048',
        exportable: true
      });

      const keyData = await this.vaultClient.read('transit/export/signing-key/jwt-signing');
      
      return {
        publicKey: keyData.data.keys['1'],
        privateKey: keyData.data.keys['1'],
        keyId: response.data.name
      };
    } catch (error) {
      this.logger.error('Failed to generate JWT key pair', error.message);
      throw error;
    }
  }

  // Encrypt sensitive data
  async encrypt(plaintext: string, keyName: string = 'application-key'): Promise<string> {
    this.ensureInitialized();
    
    try {
      const response = await this.vaultClient.write(`transit/encrypt/${keyName}`, {
        plaintext: Buffer.from(plaintext).toString('base64')
      });
      
      return response.data.ciphertext;
    } catch (error) {
      this.logger.error('Failed to encrypt data', error.message);
      throw error;
    }
  }

  // Decrypt sensitive data
  async decrypt(ciphertext: string, keyName: string = 'application-key'): Promise<string> {
    this.ensureInitialized();
    
    try {
      const response = await this.vaultClient.write(`transit/decrypt/${keyName}`, {
        ciphertext
      });
      
      return Buffer.from(response.data.plaintext, 'base64').toString();
    } catch (error) {
      this.logger.error('Failed to decrypt data', error.message);
      throw error;
    }
  }

  // Rotate encryption key
  async rotateKey(keyName: string): Promise<void> {
    this.ensureInitialized();
    
    try {
      await this.vaultClient.write(`transit/keys/${keyName}/rotate`);
      this.logger.log(`Encryption key rotated: ${keyName}`);
    } catch (error) {
      this.logger.error(`Failed to rotate key: ${keyName}`, error.message);
      throw error;
    }
  }

  // Get TLS certificate
  async getTLSCertificate(commonName: string): Promise<TLSCertificate> {
    this.ensureInitialized();
    
    try {
      const response = await this.vaultClient.write('pki/issue/jts-trading', {
        common_name: commonName,
        ttl: '8760h', // 1 year
        format: 'pem'
      });
      
      return {
        certificate: response.data.certificate,
        privateKey: response.data.private_key,
        caChain: response.data.ca_chain,
        serialNumber: response.data.serial_number,
        expiration: new Date(response.data.expiration * 1000)
      };
    } catch (error) {
      this.logger.error(`Failed to get TLS certificate for: ${commonName}`, error.message);
      throw error;
    }
  }

  // Renew lease for dynamic secrets
  async renewLease(leaseId: string): Promise<void> {
    this.ensureInitialized();
    
    try {
      await this.vaultClient.write('sys/leases/renew', {
        lease_id: leaseId
      });
      
      this.logger.debug(`Lease renewed: ${leaseId}`);
    } catch (error) {
      this.logger.error(`Failed to renew lease: ${leaseId}`, error.message);
      throw error;
    }
  }

  private async ensureSecretsEngine(): Promise<void> {
    try {
      // Enable KV secrets engine
      await this.vaultClient.mount({
        mount_point: 'kv',
        type: 'kv',
        config: {
          version: 2
        }
      });
    } catch (error) {
      // Engine might already exist
      if (!error.message.includes('path is already in use')) {
        throw error;
      }
    }

    try {
      // Enable database secrets engine
      await this.vaultClient.mount({
        mount_point: 'database',
        type: 'database'
      });
    } catch (error) {
      if (!error.message.includes('path is already in use')) {
        throw error;
      }
    }

    try {
      // Enable transit secrets engine for encryption
      await this.vaultClient.mount({
        mount_point: 'transit',
        type: 'transit'
      });
    } catch (error) {
      if (!error.message.includes('path is already in use')) {
        throw error;
      }
    }
  }

  private ensureInitialized(): void {
    if (!this.isInitialized) {
      throw new Error('VaultService is not initialized');
    }
  }
}

// Configuration service with Vault integration
@Injectable()
export class SecureConfigService {
  private configCache = new Map<string, { value: any; expiry: number }>();
  private readonly cacheTimeout = 300000; // 5 minutes

  constructor(
    private readonly vaultService: VaultService,
    private readonly configService: ConfigService
  ) {}

  async getSecureConfig<T>(key: string, defaultValue?: T): Promise<T> {
    // Check cache first
    const cached = this.configCache.get(key);
    if (cached && cached.expiry > Date.now()) {
      return cached.value;
    }

    try {
      // Try to get from Vault first
      const vaultPath = `config/jts/${key}`;
      const secret = await this.vaultService.getSecret(vaultPath);
      
      if (secret && secret.value !== undefined) {
        // Cache the value
        this.configCache.set(key, {
          value: secret.value,
          expiry: Date.now() + this.cacheTimeout
        });
        
        return secret.value;
      }
    } catch (error) {
      // Fall back to environment variables
      const envValue = this.configService.get<T>(key, defaultValue);
      if (envValue !== undefined) {
        return envValue;
      }
    }

    return defaultValue;
  }

  async setSecureConfig(key: string, value: any): Promise<void> {
    const vaultPath = `config/jts/${key}`;
    await this.vaultService.setSecret(vaultPath, { value });
    
    // Update cache
    this.configCache.set(key, {
      value,
      expiry: Date.now() + this.cacheTimeout
    });
  }
}
```

#### 4. SSL/TLS Configuration and Certificate Management
**Purpose**: Complete SSL/TLS implementation with automated certificate management
**Key Features**:
- TLS 1.3 with perfect forward secrecy
- Automated certificate generation and renewal
- Certificate pinning for API communications
- HSTS enforcement and security headers
- SNI support for multiple domains

**TLS Configuration Implementation**:
```yaml
# docker-compose.security.yml - TLS and Security Services
version: '3.8'

services:
  # HashiCorp Vault for secrets management
  vault:
    image: vault:1.15.0
    container_name: jts-vault
    restart: unless-stopped
    ports:
      - "8200:8200"
    volumes:
      - vault-data:/vault/data
      - vault-logs:/vault/logs
      - ./infrastructure/security/vault/config:/vault/config
    environment:
      - VAULT_ADDR=http://127.0.0.1:8200
      - VAULT_LOCAL_CONFIG={"ui":true,"api_addr":"http://127.0.0.1:8200","storage":{"file":{"path":"/vault/data"}},"listener":{"tcp":{"address":"0.0.0.0:8200","tls_disable":true}}}
    cap_add:
      - IPC_LOCK
    healthcheck:
      test: ["CMD", "vault", "status"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-security-network

  # Certificate Authority service
  step-ca:
    image: smallstep/step-ca:0.25.0
    container_name: jts-step-ca
    restart: unless-stopped
    ports:
      - "9443:9443"
    volumes:
      - step-ca-data:/home/step
      - ./infrastructure/security/step-ca/config:/etc/step-ca
    environment:
      - DOCKER_STEPCA_INIT_NAME=JTS Trading CA
      - DOCKER_STEPCA_INIT_DNS_NAMES=localhost,jts-ca,*.jts-trading.local
      - DOCKER_STEPCA_INIT_REMOTE_MANAGEMENT=true
    healthcheck:
      test: ["CMD", "step", "ca", "health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-security-network

  # NGINX proxy with TLS termination
  nginx-proxy:
    image: nginx:1.25-alpine
    container_name: jts-nginx-proxy
    restart: unless-stopped
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./infrastructure/security/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./infrastructure/security/nginx/conf.d:/etc/nginx/conf.d
      - nginx-certs:/etc/nginx/certs
      - nginx-logs:/var/log/nginx
    depends_on:
      - step-ca
      - vault
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jts-security-network
      - jts-app-network

  # Certificate manager service
  cert-manager:
    build:
      context: ./infrastructure/security/cert-manager
      dockerfile: Dockerfile
    container_name: jts-cert-manager
    restart: unless-stopped
    volumes:
      - nginx-certs:/certs
      - ./infrastructure/security/cert-manager/config:/config
    environment:
      - STEP_CA_URL=https://step-ca:9443
      - VAULT_ADDR=http://vault:8200
      - VAULT_TOKEN=${VAULT_TOKEN}
      - CERTS_PATH=/certs
    depends_on:
      - step-ca
      - vault
    networks:
      - jts-security-network

  # OWASP ZAP security scanner
  zap-baseline:
    image: owasp/zap2docker-stable
    container_name: jts-zap-scanner
    volumes:
      - ./infrastructure/security/zap/reports:/zap/wrk
    command: zap-baseline.py -t http://api-gateway:3000 -r zap-baseline-report.html
    depends_on:
      - nginx-proxy
    networks:
      - jts-security-network
      - jts-app-network

volumes:
  vault-data:
  vault-logs:
  step-ca-data:
  nginx-certs:
  nginx-logs:

networks:
  jts-security-network:
    driver: bridge
    internal: false
  jts-app-network:
    external: true
```

**NGINX TLS Configuration**:
```nginx
# infrastructure/security/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format with security information
    log_format security '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $body_bytes_sent '
                       '"$http_referer" "$http_user_agent" '
                       'rt=$request_time uct="$upstream_connect_time" '
                       'uht="$upstream_header_time" urt="$upstream_response_time" '
                       'ssl_protocol=$ssl_protocol ssl_cipher=$ssl_cipher '
                       'client_cert_verify=$ssl_client_verify';

    access_log /var/log/nginx/access.log security;

    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

    # SSL/TLS Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    # DH parameters for perfect forward secrecy
    ssl_dhparam /etc/nginx/certs/dhparam.pem;

    # HSTS (HTTP Strict Transport Security)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Rate limiting zones
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=30r/m;
    limit_req_zone $binary_remote_addr zone=trading:10m rate=1000r/m;

    # Connection limiting
    limit_conn_zone $binary_remote_addr zone=conn_per_ip:10m;
    limit_conn conn_per_ip 20;

    # Main server configuration
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    # API Gateway with TLS
    server {
        listen 443 ssl http2;
        server_name api.jts-trading.local;

        ssl_certificate /etc/nginx/certs/api.jts-trading.local.crt;
        ssl_certificate_key /etc/nginx/certs/api.jts-trading.local.key;

        # Client certificate verification for high-security endpoints
        ssl_client_certificate /etc/nginx/certs/ca.crt;
        ssl_verify_client optional;

        location / {
            # Rate limiting
            limit_req zone=api burst=20 nodelay;

            # Proxy configuration
            proxy_pass http://api-gateway:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Client-Cert $ssl_client_cert;
            proxy_set_header X-Client-Verify $ssl_client_verify;

            # Timeouts
            proxy_connect_timeout 5s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;

            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }

        # Trading endpoints with stricter rate limiting
        location /api/v1/trading/ {
            limit_req zone=trading burst=50 nodelay;
            
            # Require client certificate for trading operations
            if ($ssl_client_verify != SUCCESS) {
                return 403 "Client certificate required for trading operations";
            }

            proxy_pass http://api-gateway:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Client-Cert $ssl_client_cert;
            proxy_set_header X-Client-Verify $ssl_client_verify;
        }

        # Authentication endpoints
        location /api/v1/auth/ {
            limit_req zone=auth burst=10 nodelay;

            proxy_pass http://api-gateway:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check endpoint
        location /health {
            access_log off;
            proxy_pass http://api-gateway:3000/health;
        }

        # Security.txt for security disclosure
        location /.well-known/security.txt {
            alias /etc/nginx/security.txt;
            add_header Content-Type text/plain;
        }
    }

    # Web application with TLS
    server {
        listen 443 ssl http2;
        server_name app.jts-trading.local;

        ssl_certificate /etc/nginx/certs/app.jts-trading.local.crt;
        ssl_certificate_key /etc/nginx/certs/app.jts-trading.local.key;

        # CSP for web application
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss: https://api.jts-trading.local; font-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'" always;

        location / {
            proxy_pass http://web-app:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # Default catch-all server
    server {
        listen 443 ssl http2 default_server;
        server_name _;

        ssl_certificate /etc/nginx/certs/default.crt;
        ssl_certificate_key /etc/nginx/certs/default.key;

        return 444; # Close connection without response
    }
}
```

#### 5. Security Scanning and Compliance
**Purpose**: Automated security scanning and compliance monitoring
**Key Features**:
- Vulnerability scanning with OWASP ZAP
- Container security scanning
- Dependency vulnerability checking
- Code security analysis
- Compliance reporting and audit trails

**Security Scanning Implementation**:
```typescript
// libs/shared/security/src/lib/security-scanner.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { spawn } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class SecurityScannerService {
  private readonly logger = new Logger(SecurityScannerService.name);

  constructor(private readonly configService: ConfigService) {}

  // Run OWASP ZAP baseline scan
  async runZapScan(targetUrl: string): Promise<SecurityScanResult> {
    this.logger.log(`Starting ZAP scan for: ${targetUrl}`);

    return new Promise((resolve, reject) => {
      const reportPath = `/tmp/zap-report-${Date.now()}.html`;
      const jsonReportPath = `/tmp/zap-report-${Date.now()}.json`;

      const zapProcess = spawn('docker', [
        'run', '--rm',
        '-v', `/tmp:/zap/wrk/:rw`,
        'owasp/zap2docker-stable',
        'zap-baseline.py',
        '-t', targetUrl,
        '-r', path.basename(reportPath),
        '-J', path.basename(jsonReportPath),
        '-x', 'zap-results.xml'
      ]);

      let output = '';
      let errorOutput = '';

      zapProcess.stdout.on('data', (data) => {
        output += data.toString();
        this.logger.debug(`ZAP stdout: ${data}`);
      });

      zapProcess.stderr.on('data', (data) => {
        errorOutput += data.toString();
        this.logger.debug(`ZAP stderr: ${data}`);
      });

      zapProcess.on('close', (code) => {
        if (code === 0 || code === 1) { // ZAP returns 1 when vulnerabilities are found
          try {
            const results = this.parseZapResults(jsonReportPath);
            resolve({
              success: true,
              vulnerabilities: results,
              reportPath,
              summary: this.generateScanSummary(results)
            });
          } catch (error) {
            reject(new Error(`Failed to parse ZAP results: ${error.message}`));
          }
        } else {
          reject(new Error(`ZAP scan failed with code ${code}: ${errorOutput}`));
        }
      });
    });
  }

  // Run dependency vulnerability scan
  async runDependencyScan(): Promise<DependencyScanResult> {
    this.logger.log('Starting dependency vulnerability scan');

    return new Promise((resolve, reject) => {
      const auditProcess = spawn('npm', ['audit', '--json']);

      let output = '';
      let errorOutput = '';

      auditProcess.stdout.on('data', (data) => {
        output += data.toString();
      });

      auditProcess.stderr.on('data', (data) => {
        errorOutput += data.toString();
      });

      auditProcess.on('close', (code) => {
        try {
          const auditResults = JSON.parse(output);
          const vulnerabilities = this.processDependencyVulnerabilities(auditResults);
          
          resolve({
            success: true,
            vulnerabilities,
            summary: {
              total: vulnerabilities.length,
              critical: vulnerabilities.filter(v => v.severity === 'critical').length,
              high: vulnerabilities.filter(v => v.severity === 'high').length,
              moderate: vulnerabilities.filter(v => v.severity === 'moderate').length,
              low: vulnerabilities.filter(v => v.severity === 'low').length
            }
          });
        } catch (error) {
          reject(new Error(`Failed to parse npm audit results: ${error.message}`));
        }
      });
    });
  }

  // Run container security scan
  async runContainerScan(imageName: string): Promise<ContainerScanResult> {
    this.logger.log(`Starting container security scan for: ${imageName}`);

    return new Promise((resolve, reject) => {
      const trivyProcess = spawn('docker', [
        'run', '--rm',
        '-v', '/var/run/docker.sock:/var/run/docker.sock',
        '-v', '/tmp:/tmp',
        'aquasec/trivy:latest',
        'image', '--format', 'json',
        '--output', '/tmp/trivy-results.json',
        imageName
      ]);

      let output = '';
      let errorOutput = '';

      trivyProcess.stdout.on('data', (data) => {
        output += data.toString();
      });

      trivyProcess.stderr.on('data', (data) => {
        errorOutput += data.toString();
      });

      trivyProcess.on('close', (code) => {
        if (code === 0) {
          try {
            const results = JSON.parse(fs.readFileSync('/tmp/trivy-results.json', 'utf8'));
            const vulnerabilities = this.processTrivyResults(results);
            
            resolve({
              success: true,
              image: imageName,
              vulnerabilities,
              summary: this.generateContainerScanSummary(vulnerabilities)
            });
          } catch (error) {
            reject(new Error(`Failed to parse Trivy results: ${error.message}`));
          }
        } else {
          reject(new Error(`Container scan failed with code ${code}: ${errorOutput}`));
        }
      });
    });
  }

  // Generate security compliance report
  async generateComplianceReport(): Promise<ComplianceReport> {
    this.logger.log('Generating security compliance report');

    const [zapScan, depScan, containerScans] = await Promise.all([
      this.runZapScan(this.configService.get('APP_URL', 'http://localhost:3000')),
      this.runDependencyScan(),
      this.runAllContainerScans()
    ]);

    const complianceScore = this.calculateComplianceScore({
      zapScan,
      depScan,
      containerScans
    });

    return {
      timestamp: new Date(),
      complianceScore,
      scans: {
        webApplication: zapScan,
        dependencies: depScan,
        containers: containerScans
      },
      recommendations: this.generateRecommendations({
        zapScan,
        depScan,
        containerScans
      }),
      nextScanDue: this.calculateNextScanDate()
    };
  }

  private parseZapResults(jsonPath: string): SecurityVulnerability[] {
    const results = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    
    return results.site.map(site => 
      site.alerts.map(alert => ({
        id: alert.pluginid,
        name: alert.name,
        severity: this.mapZapSeverity(alert.riskdesc),
        description: alert.desc,
        solution: alert.solution,
        reference: alert.reference,
        instances: alert.instances.length,
        urls: alert.instances.map(instance => instance.uri)
      }))
    ).flat();
  }

  private processDependencyVulnerabilities(auditResults: any): DependencyVulnerability[] {
    const vulnerabilities: DependencyVulnerability[] = [];
    
    for (const [name, advisory] of Object.entries(auditResults.advisories || {})) {
      vulnerabilities.push({
        package: advisory.module_name,
        version: advisory.findings[0]?.version || 'unknown',
        severity: advisory.severity,
        title: advisory.title,
        overview: advisory.overview,
        recommendation: advisory.recommendation,
        references: advisory.references,
        cwe: advisory.cwe,
        cvssScore: advisory.cvss?.score,
        patchedVersions: advisory.patched_versions
      });
    }
    
    return vulnerabilities;
  }

  private processTrivyResults(results: any): ContainerVulnerability[] {
    const vulnerabilities: ContainerVulnerability[] = [];
    
    results.Results?.forEach(result => {
      result.Vulnerabilities?.forEach(vuln => {
        vulnerabilities.push({
          vulnerabilityId: vuln.VulnerabilityID,
          package: vuln.PkgName,
          installedVersion: vuln.InstalledVersion,
          fixedVersion: vuln.FixedVersion,
          severity: vuln.Severity,
          title: vuln.Title,
          description: vuln.Description,
          references: vuln.References || [],
          cvssScore: vuln.CVSS?.nvd?.V3Score || vuln.CVSS?.redhat?.V3Score
        });
      });
    });
    
    return vulnerabilities;
  }

  private async runAllContainerScans(): Promise<ContainerScanResult[]> {
    const containers = [
      'jts-api-gateway:latest',
      'jts-web-app:latest',
      'jts-strategy-engine:latest'
    ];

    const results = await Promise.allSettled(
      containers.map(container => this.runContainerScan(container))
    );

    return results
      .filter(result => result.status === 'fulfilled')
      .map(result => result.value);
  }

  private calculateComplianceScore(scans: any): number {
    let score = 100;

    // Deduct points for vulnerabilities
    scans.zapScan.vulnerabilities.forEach(vuln => {
      switch (vuln.severity) {
        case 'critical': score -= 15; break;
        case 'high': score -= 10; break;
        case 'medium': score -= 5; break;
        case 'low': score -= 2; break;
      }
    });

    scans.depScan.vulnerabilities.forEach(vuln => {
      switch (vuln.severity) {
        case 'critical': score -= 12; break;
        case 'high': score -= 8; break;
        case 'moderate': score -= 4; break;
        case 'low': score -= 1; break;
      }
    });

    return Math.max(0, Math.min(100, score));
  }

  private generateRecommendations(scans: any): string[] {
    const recommendations = [];

    if (scans.zapScan.summary.critical > 0) {
      recommendations.push('Critical web vulnerabilities detected - immediate remediation required');
    }

    if (scans.depScan.summary.critical > 0) {
      recommendations.push('Critical dependency vulnerabilities - update packages immediately');
    }

    if (scans.containerScans.some(scan => scan.summary.critical > 0)) {
      recommendations.push('Critical container vulnerabilities - rebuild images with security patches');
    }

    return recommendations;
  }

  private calculateNextScanDate(): Date {
    const nextScan = new Date();
    nextScan.setDate(nextScan.getDate() + 7); // Weekly scans
    return nextScan;
  }

  private mapZapSeverity(riskDesc: string): string {
    const severity = riskDesc.split(' ')[0].toLowerCase();
    return severity === 'informational' ? 'low' : severity;
  }
}
```

### Implementation Steps

#### Phase 1: JWT Authentication System (Days 1-4)
1. **JWT Service Implementation**
   - Implement RS256 JWT signing with key rotation
   - Create token validation and refresh mechanisms
   - Implement session management with Redis
   - Add multi-factor authentication support

2. **Authorization Framework**
   - Create role-based access control system
   - Implement trading-specific permissions
   - Add attribute-based access control
   - Create authorization guards and decorators

#### Phase 2: API Security and Rate Limiting (Days 5-8)
3. **Rate Limiting Implementation**
   - Implement sliding window rate limiters
   - Create tiered rate limiting for different user types
   - Add trading-specific rate limits
   - Implement IP-based and user-based quotas

4. **API Security Middleware**
   - Add input validation and sanitization
   - Implement XSS and SQL injection protection
   - Configure CORS and security headers
   - Add request/response logging

#### Phase 3: Secrets Management (Days 9-12)
5. **Vault Integration**
   - Deploy HashiCorp Vault with Docker
   - Implement secrets retrieval and storage
   - Add dynamic database credential generation
   - Configure encryption as a service

6. **Certificate Management**
   - Implement automated certificate generation
   - Add certificate renewal workflows
   - Configure PKI infrastructure
   - Integrate with application services

#### Phase 4: SSL/TLS and Security Scanning (Days 13-16)
7. **TLS Configuration**
   - Configure NGINX with TLS 1.3
   - Implement perfect forward secrecy
   - Add HSTS and security headers
   - Configure client certificate verification

8. **Security Scanning**
   - Integrate OWASP ZAP for web scanning
   - Add dependency vulnerability scanning
   - Implement container security scanning
   - Create compliance reporting system

## Dependencies

- **1003**: Monorepo Structure - Required for shared security libraries
- **1005**: Database Infrastructure - Required for secure database connections
- **1007**: Service Communication - Required for securing inter-service communication

## Testing Plan

### Authentication Testing
- **JWT Token Testing**: Test token generation, validation, and refresh workflows
- **Authorization Testing**: Verify role-based and permission-based access controls
- **Session Management**: Test concurrent sessions and session timeout handling
- **MFA Testing**: Validate multi-factor authentication flows

### Security Testing
- **Penetration Testing**: Run automated security scans with OWASP ZAP
- **Rate Limiting Testing**: Test rate limits under various load conditions
- **Input Validation**: Test XSS, SQL injection, and other input attack vectors
- **TLS Configuration**: Verify SSL/TLS configuration with SSL Labs testing

### Compliance Testing
- **Audit Logging**: Verify all security events are properly logged
- **Data Protection**: Test encryption at rest and in transit
- **Access Controls**: Verify principle of least privilege implementation
- **Vulnerability Management**: Test automated scanning and reporting

## Claude Code Instructions

```
When implementing this feature:
1. Deploy HashiCorp Vault with docker-compose.security.yml for secrets management
2. Implement JWT authentication service with RS256 signing and refresh token rotation
3. Create comprehensive API security middleware with rate limiting and input validation
4. Configure NGINX proxy with TLS 1.3, security headers, and client certificate support
5. Set up automated security scanning with OWASP ZAP, dependency scanning, and container scanning
6. Implement role-based authorization with trading-specific permissions
7. Create secure configuration service that integrates with Vault for secret retrieval
8. Configure automated certificate generation and renewal using step-ca
9. Implement comprehensive security event logging and audit trails
10. Create security compliance reporting with automated vulnerability assessment
11. Test all security controls with realistic attack scenarios
12. Document security procedures and incident response workflows
```

## Notes

- All security components must be highly available and cannot be single points of failure
- JWT tokens should have short expiry times with secure refresh mechanisms
- All API endpoints must implement proper authentication and authorization
- Security scanning must be integrated into CI/CD pipelines for continuous monitoring
- All cryptographic keys must be rotated regularly with zero-downtime procedures
- Security logs must be tamper-proof and stored securely for compliance requirements
- Rate limiting thresholds must be carefully tuned to prevent legitimate user blocking
- Multi-factor authentication is required for all administrative and high-privilege operations

## Status Updates

- **2025-08-24**: Feature specification created with comprehensive security architecture design