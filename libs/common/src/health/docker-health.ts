/**
 * Docker Health Check Utilities for JTS Trading System
 * 
 * This module provides comprehensive health checking capabilities for containerized
 * microservices in the JTS trading platform. It implements a modular, extensible
 * health check system that integrates with Docker's native health check mechanism
 * and Kubernetes liveness/readiness probes.
 * 
 * Key Features:
 * - Modular health check registration
 * - Service-specific health validations
 * - Performance metrics collection
 * - Circuit breaker integration
 * - Graceful degradation support
 */

import { Injectable, Logger } from '@nestjs/common';
import { HealthCheckService, HealthCheck, HealthCheckResult } from '@nestjs/terminus';

/**
 * Health check status enumeration
 * Provides standardized status values for health checks
 */
export enum HealthStatus {
  HEALTHY = 'healthy',
  UNHEALTHY = 'unhealthy',
  DEGRADED = 'degraded',
  STARTING = 'starting',
}

/**
 * Individual health check result interface
 * Represents the outcome of a single health check
 */
export interface HealthCheckDetail {
  name: string;
  status: HealthStatus;
  message?: string;
  responseTime?: number;
  metadata?: Record<string, any>;
}

/**
 * Complete health check response interface
 * Aggregates all health check results
 */
export interface DockerHealthResponse {
  status: HealthStatus;
  timestamp: string;
  service: string;
  version: string;
  uptime: number;
  checks: HealthCheckDetail[];
  metrics?: {
    memoryUsage: NodeJS.MemoryUsage;
    cpuUsage?: NodeJS.CpuUsage;
    responseTime: number;
  };
}

/**
 * Health check function type definition
 * Async function that performs a health check and returns status
 */
export type HealthCheckFunction = () => Promise<HealthCheckDetail>;

/**
 * DockerHealthCheck Service
 * 
 * Core service for managing health checks in containerized environments.
 * This service provides a flexible framework for registering and executing
 * health checks with proper error handling and timeout management.
 * 
 * Usage Example:
 * ```typescript
 * const healthService = new DockerHealthCheck('api-gateway', '1.0.0');
 * 
 * // Register database health check
 * healthService.registerCheck('database', async () => {
 *   const isConnected = await db.ping();
 *   return {
 *     name: 'database',
 *     status: isConnected ? HealthStatus.HEALTHY : HealthStatus.UNHEALTHY,
 *     message: isConnected ? 'Database connected' : 'Database connection failed'
 *   };
 * });
 * 
 * // Perform health check
 * const result = await healthService.performHealthCheck();
 * ```
 */
@Injectable()
export class DockerHealthCheck {
  private readonly logger = new Logger(DockerHealthCheck.name);
  private readonly checks = new Map<string, HealthCheckFunction>();
  private readonly startTime = Date.now();
  private readonly timeout = 10000; // 10 second timeout for health checks

  constructor(
    private readonly serviceName: string,
    private readonly serviceVersion: string,
  ) {
    this.logger.log(`Initializing health checks for ${serviceName} v${serviceVersion}`);
    this.registerDefaultChecks();
  }

  /**
   * Register default health checks
   * These checks are common to all services
   */
  private registerDefaultChecks(): void {
    // Memory usage check
    this.registerCheck('memory', async () => {
      const memUsage = process.memoryUsage();
      const heapUsedMB = memUsage.heapUsed / 1024 / 1024;
      const heapTotalMB = memUsage.heapTotal / 1024 / 1024;
      const usagePercent = (heapUsedMB / heapTotalMB) * 100;

      return {
        name: 'memory',
        status: usagePercent < 90 ? HealthStatus.HEALTHY : 
                usagePercent < 95 ? HealthStatus.DEGRADED : HealthStatus.UNHEALTHY,
        message: `Heap usage: ${heapUsedMB.toFixed(2)}MB / ${heapTotalMB.toFixed(2)}MB (${usagePercent.toFixed(1)}%)`,
        metadata: {
          heapUsedMB,
          heapTotalMB,
          usagePercent
        }
      };
    });

    // Process uptime check
    this.registerCheck('uptime', async () => {
      const uptimeMs = Date.now() - this.startTime;
      const uptimeHours = uptimeMs / (1000 * 60 * 60);

      return {
        name: 'uptime',
        status: uptimeMs > 5000 ? HealthStatus.HEALTHY : HealthStatus.STARTING,
        message: `Service uptime: ${uptimeHours.toFixed(2)} hours`,
        metadata: {
          uptimeMs,
          uptimeHours
        }
      };
    });
  }

  /**
   * Register a custom health check
   * 
   * @param name - Unique identifier for the health check
   * @param check - Async function that performs the health check
   */
  public registerCheck(name: string, check: HealthCheckFunction): void {
    this.logger.debug(`Registering health check: ${name}`);
    this.checks.set(name, check);
  }

  /**
   * Remove a health check
   * 
   * @param name - Name of the health check to remove
   */
  public unregisterCheck(name: string): void {
    this.logger.debug(`Unregistering health check: ${name}`);
    this.checks.delete(name);
  }

  /**
   * Execute all registered health checks
   * 
   * @returns Comprehensive health check response
   */
  public async performHealthCheck(): Promise<DockerHealthResponse> {
    const startTime = Date.now();
    const checkPromises: Promise<HealthCheckDetail>[] = [];

    // Execute all health checks with timeout
    for (const [name, checkFn] of this.checks.entries()) {
      const checkPromise = this.executeCheckWithTimeout(name, checkFn);
      checkPromises.push(checkPromise);
    }

    // Wait for all checks to complete
    const results = await Promise.allSettled(checkPromises);

    // Process results
    const checks: HealthCheckDetail[] = results.map((result, index) => {
      if (result.status === 'fulfilled') {
        return result.value;
      } else {
        const checkName = Array.from(this.checks.keys())[index];
        this.logger.error(`Health check '${checkName}' failed:`, result.reason);
        return {
          name: checkName,
          status: HealthStatus.UNHEALTHY,
          message: `Check failed: ${result.reason?.message || 'Unknown error'}`
        };
      }
    });

    // Determine overall status
    const overallStatus = this.determineOverallStatus(checks);

    // Calculate response time
    const responseTime = Date.now() - startTime;

    return {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      service: this.serviceName,
      version: this.serviceVersion,
      uptime: Date.now() - this.startTime,
      checks,
      metrics: {
        memoryUsage: process.memoryUsage(),
        cpuUsage: process.cpuUsage ? process.cpuUsage() : undefined,
        responseTime
      }
    };
  }

  /**
   * Execute a health check with timeout protection
   * 
   * @param name - Name of the health check
   * @param checkFn - Health check function to execute
   * @returns Health check result or timeout error
   */
  private async executeCheckWithTimeout(
    name: string,
    checkFn: HealthCheckFunction
  ): Promise<HealthCheckDetail> {
    const timeoutPromise = new Promise<HealthCheckDetail>((_, reject) => {
      setTimeout(() => {
        reject(new Error(`Health check '${name}' timed out after ${this.timeout}ms`));
      }, this.timeout);
    });

    const checkPromise = (async () => {
      const startTime = Date.now();
      try {
        const result = await checkFn();
        result.responseTime = Date.now() - startTime;
        return result;
      } catch (error) {
        this.logger.error(`Health check '${name}' error:`, error);
        return {
          name,
          status: HealthStatus.UNHEALTHY,
          message: `Check error: ${error.message}`,
          responseTime: Date.now() - startTime
        };
      }
    })();

    return Promise.race([checkPromise, timeoutPromise]);
  }

  /**
   * Determine overall health status based on individual check results
   * 
   * @param checks - Array of individual health check results
   * @returns Overall health status
   */
  private determineOverallStatus(checks: HealthCheckDetail[]): HealthStatus {
    // If any check is unhealthy, overall status is unhealthy
    if (checks.some(c => c.status === HealthStatus.UNHEALTHY)) {
      return HealthStatus.UNHEALTHY;
    }

    // If any check is degraded, overall status is degraded
    if (checks.some(c => c.status === HealthStatus.DEGRADED)) {
      return HealthStatus.DEGRADED;
    }

    // If any check is starting, overall status is starting
    if (checks.some(c => c.status === HealthStatus.STARTING)) {
      return HealthStatus.STARTING;
    }

    // All checks are healthy
    return HealthStatus.HEALTHY;
  }

  /**
   * Express/Fastify compatible health check endpoint handler
   * Can be used directly as a route handler
   * 
   * @returns Express-compatible request handler
   */
  public getExpressHandler() {
    return async (req: any, res: any) => {
      try {
        const health = await this.performHealthCheck();
        const statusCode = health.status === HealthStatus.HEALTHY ? 200 :
                          health.status === HealthStatus.DEGRADED ? 200 :
                          health.status === HealthStatus.STARTING ? 503 : 503;
        
        res.status(statusCode).json(health);
      } catch (error) {
        this.logger.error('Health check handler error:', error);
        res.status(503).json({
          status: HealthStatus.UNHEALTHY,
          error: error.message
        });
      }
    };
  }
}

/**
 * Service-specific health check implementations
 * These are specialized health checks for different service types
 */

/**
 * Database health check
 * Validates database connectivity and query performance
 */
export class DatabaseHealthCheck {
  static create(dbConnection: any): HealthCheckFunction {
    return async (): Promise<HealthCheckDetail> => {
      try {
        const startTime = Date.now();
        // Perform a simple query to test connection
        await dbConnection.query('SELECT 1');
        const responseTime = Date.now() - startTime;

        return {
          name: 'database',
          status: responseTime < 1000 ? HealthStatus.HEALTHY : HealthStatus.DEGRADED,
          message: `Database responding in ${responseTime}ms`,
          responseTime,
          metadata: {
            connectionPool: dbConnection.pool?.size || 0,
            activeConnections: dbConnection.pool?.activeConnections || 0
          }
        };
      } catch (error) {
        return {
          name: 'database',
          status: HealthStatus.UNHEALTHY,
          message: `Database connection failed: ${error.message}`
        };
      }
    };
  }
}

/**
 * Redis health check
 * Validates Redis connectivity and performance
 */
export class RedisHealthCheck {
  static create(redisClient: any): HealthCheckFunction {
    return async (): Promise<HealthCheckDetail> => {
      try {
        const startTime = Date.now();
        await redisClient.ping();
        const responseTime = Date.now() - startTime;

        return {
          name: 'redis',
          status: responseTime < 100 ? HealthStatus.HEALTHY : HealthStatus.DEGRADED,
          message: `Redis responding in ${responseTime}ms`,
          responseTime
        };
      } catch (error) {
        return {
          name: 'redis',
          status: HealthStatus.UNHEALTHY,
          message: `Redis connection failed: ${error.message}`
        };
      }
    };
  }
}

/**
 * Kafka health check
 * Validates Kafka connectivity and consumer group status
 */
export class KafkaHealthCheck {
  static create(kafkaClient: any): HealthCheckFunction {
    return async (): Promise<HealthCheckDetail> => {
      try {
        const admin = kafkaClient.admin();
        await admin.connect();
        const topics = await admin.listTopics();
        await admin.disconnect();

        return {
          name: 'kafka',
          status: HealthStatus.HEALTHY,
          message: `Kafka connected with ${topics.length} topics`,
          metadata: {
            topicCount: topics.length
          }
        };
      } catch (error) {
        return {
          name: 'kafka',
          status: HealthStatus.UNHEALTHY,
          message: `Kafka connection failed: ${error.message}`
        };
      }
    };
  }
}

/**
 * External API health check
 * Validates connectivity to external services (brokers, exchanges)
 */
export class ExternalAPIHealthCheck {
  static create(apiName: string, healthEndpoint: string): HealthCheckFunction {
    return async (): Promise<HealthCheckDetail> => {
      try {
        const startTime = Date.now();
        const response = await fetch(healthEndpoint, {
          method: 'GET',
          timeout: 5000
        });
        const responseTime = Date.now() - startTime;

        return {
          name: `external-api-${apiName}`,
          status: response.ok ? HealthStatus.HEALTHY : HealthStatus.DEGRADED,
          message: `${apiName} API responding with status ${response.status}`,
          responseTime,
          metadata: {
            statusCode: response.status
          }
        };
      } catch (error) {
        return {
          name: `external-api-${apiName}`,
          status: HealthStatus.UNHEALTHY,
          message: `${apiName} API unreachable: ${error.message}`
        };
      }
    };
  }
}

/**
 * Circuit breaker health check
 * Monitors circuit breaker states for external services
 */
export class CircuitBreakerHealthCheck {
  static create(circuitBreaker: any): HealthCheckFunction {
    return async (): Promise<HealthCheckDetail> => {
      const state = circuitBreaker.getState();
      const stats = circuitBreaker.getStats();

      return {
        name: 'circuit-breaker',
        status: state === 'OPEN' ? HealthStatus.UNHEALTHY :
                state === 'HALF_OPEN' ? HealthStatus.DEGRADED :
                HealthStatus.HEALTHY,
        message: `Circuit breaker state: ${state}`,
        metadata: {
          state,
          successRate: stats.successRate,
          failureCount: stats.failureCount,
          requestCount: stats.requestCount
        }
      };
    };
  }
}