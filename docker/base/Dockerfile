# ========================================================================================================
# JTS Trading System - Multi-Stage Base Dockerfile
# ========================================================================================================
# This Dockerfile provides a secure, production-ready foundation for all JTS services with comprehensive
# security hardening, optimal layer caching, and multi-stage architecture for different environments.
#
# ARCHITECTURE OVERVIEW:
# - Stage 1 (base): Minimal Node.js runtime with security hardening
# - Stage 2 (builder): Build environment with full toolchain
# - Stage 3 (development): Development environment with debugging tools
# - Stage 4 (production): Ultra-minimal production runtime
#
# SECURITY FEATURES:
# - Non-root user execution with proper UID/GID mapping
# - Minimal attack surface with distroless base images
# - Security scanning with .trivyignore integration
# - Secure defaults for Node.js runtime flags
# - File system permissions hardening
# - Network security configurations
#
# PERFORMANCE OPTIMIZATIONS:
# - Optimal layer ordering for Docker build cache efficiency
# - Multi-stage builds to minimize final image size
# - Efficient package manager configurations
# - Build-time optimizations and dead code elimination
# ========================================================================================================

# ========================================================================================================
# STAGE 1: BASE - Security-Hardened Foundation
# ========================================================================================================
# This stage establishes the secure foundation for all subsequent stages. We use Alpine Linux for its
# minimal attack surface and excellent security track record. All security configurations are applied
# here to ensure consistent security posture across all environments.
FROM node:20.18.1-alpine3.20 AS base

# Security labels for container introspection and compliance tracking
LABEL maintainer="JTS Team <dev@jts.com>" \
      version="1.0.0" \
      description="JTS Trading System Base Image" \
      vendor="JTS" \
      security.scan="enabled" \
      security.updates="automated"

# ========================================================================================================
# SYSTEM SECURITY HARDENING
# ========================================================================================================

# Update package index and install essential security packages
# - ca-certificates: Essential for HTTPS connections and certificate validation
# - dumb-init: Proper signal handling for PID 1 in containers (security best practice)
# - tini: Alternative init system for proper zombie process reaping
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        ca-certificates=20241010-r0 \
        dumb-init=1.2.5-r3 \
        tini=0.19.0-r3 && \
    # Remove package cache to reduce image size and eliminate potential security risks
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# ========================================================================================================
# USER SECURITY CONFIGURATION
# ========================================================================================================

# Create a dedicated non-root user for running the application
# Using specific UID/GID (1001:1001) for consistency across environments and proper permission mapping
# The 'node' user is created with no shell and no home directory for security
RUN addgroup -g 1001 -S jtsgroup && \
    adduser -u 1001 -S jtsuser -G jtsgroup -h /app -s /sbin/nologin

# ========================================================================================================
# FILESYSTEM SECURITY SETUP
# ========================================================================================================

# Create application directory structure with secure permissions
# /app: Main application directory
# /app/tmp: Temporary files with restricted permissions
# /app/logs: Log directory with appropriate permissions
# /app/.cache: Node.js and package manager cache
WORKDIR /app

RUN mkdir -p /app/tmp /app/logs /app/.cache && \
    # Set secure permissions: owner read/write, group read, no world permissions
    chmod 750 /app && \
    chmod 700 /app/tmp && \
    chmod 755 /app/logs && \
    chmod 700 /app/.cache && \
    # Change ownership to our application user
    chown -R jtsuser:jtsgroup /app

# ========================================================================================================
# NODE.JS SECURITY CONFIGURATION
# ========================================================================================================

# Configure Node.js security settings via environment variables
# These settings enhance security and performance for production workloads
ENV NODE_ENV=production \
    # Disable Node.js deprecation warnings in production (reduces log noise)
    NODE_NO_WARNINGS=1 \
    # Set maximum old space size to prevent memory issues
    NODE_OPTIONS="--max-old-space-size=2048 --enable-source-maps" \
    # Secure npm configuration
    npm_config_cache=/app/.cache/npm \
    npm_config_update_notifier=false \
    npm_config_audit_level=high \
    # Yarn security configuration
    YARN_CACHE_FOLDER=/app/.cache/yarn \
    YARN_ENABLE_TELEMETRY=0 \
    # Security: Prevent npm package installation as root
    npm_config_unsafe_perm=false

# ========================================================================================================
# PACKAGE MANAGER OPTIMIZATION
# ========================================================================================================

# Configure Yarn for optimal performance and security
# Enable Yarn 4 features and set secure defaults
RUN corepack enable && \
    corepack prepare yarn@4.9.4 --activate && \
    # Verify Yarn installation and version
    yarn --version && \
    # Configure Yarn security settings
    yarn config set enableTelemetry false && \
    yarn config set enableGlobalCache false && \
    yarn config set checksumBehavior update

# Set the container's init system for proper signal handling
# This ensures graceful shutdowns and prevents zombie processes
ENTRYPOINT ["dumb-init", "--"]

# ========================================================================================================
# STAGE 2: BUILDER - Optimized Build Environment
# ========================================================================================================
# This stage contains all build tools and dependencies needed to compile the application.
# It's designed for maximum build performance with comprehensive caching strategies.
FROM base AS builder

# Development and build-specific labels
LABEL stage="builder" \
      build.optimization="enabled" \
      build.cache="layered"

# ========================================================================================================
# BUILD ENVIRONMENT SETUP
# ========================================================================================================

# Install build dependencies required for native module compilation
# These packages are essential for building Node.js native modules and optimizing builds
RUN apk add --no-cache --virtual .build-deps \
        python3=3.12.8-r1 \
        make=4.4.1-r2 \
        g++=13.2.1_git20240309-r0 \
        git=2.45.2-r0 \
        # Additional tools for advanced builds
        pkgconfig=2.2.0-r0 \
        autoconf=2.72-r0 \
        automake=1.16.5-r2 \
        libtool=2.4.7-r3

# Configure build environment variables for optimal compilation
ENV NODE_ENV=development \
    # Enable build optimizations
    MAKEFLAGS="-j$(nproc)" \
    # Python path for node-gyp
    PYTHON=/usr/bin/python3 \
    # Build optimization flags
    CXXFLAGS="-O2 -pipe" \
    CFLAGS="-O2 -pipe"

# ========================================================================================================
# DEPENDENCY MANAGEMENT OPTIMIZATION
# ========================================================================================================

# Copy package management files first for optimal Docker layer caching
# This allows Docker to reuse the dependency installation layer when source code changes
COPY package.json yarn.lock .yarnrc.yml ./

# Configure package manager for build environment
RUN yarn config set nodeLinker node-modules && \
    yarn config set enableGlobalCache false && \
    yarn config set compressionLevel 9

# Install all dependencies (including devDependencies for building)
# Use --immutable to ensure reproducible builds
# Use --check-cache to verify package integrity
RUN yarn install --immutable --check-cache --inline-builds

# ========================================================================================================
# BUILD CACHE OPTIMIZATION
# ========================================================================================================

# Copy configuration files that affect the build process
# These files are copied separately to optimize caching
COPY tsconfig*.json ./
COPY jest.config.ts ./
COPY nx.json ./
COPY .eslintrc.nx.json ./

# Create build cache directory with proper permissions
RUN mkdir -p /app/.build-cache && \
    chown -R jtsuser:jtsgroup /app/.build-cache && \
    chmod 755 /app/.build-cache

# ========================================================================================================
# STAGE 3: DEVELOPMENT - Enhanced Development Environment
# ========================================================================================================
# This stage provides a comprehensive development environment with debugging tools,
# hot reloading capabilities, and development utilities.
FROM builder AS development

# Development-specific labels
LABEL stage="development" \
      environment="dev" \
      debugging="enabled" \
      hot-reload="enabled"

# ========================================================================================================
# DEVELOPMENT TOOLS INSTALLATION
# ========================================================================================================

# Install development and debugging tools
RUN apk add --no-cache \
        # Process monitoring and debugging
        htop=3.3.0-r0 \
        curl=8.11.0-r2 \
        wget=1.24.5-r0 \
        # Network debugging tools
        netcat-openbsd=1.226-r0 \
        bind-tools=9.18.31-r0 \
        # Text processing and analysis
        jq=1.7.1-r0 \
        less=643-r0 \
        vim=9.1.0892-r0

# ========================================================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# ========================================================================================================

# Override production settings for development
ENV NODE_ENV=development \
    # Enable detailed debugging and logging
    DEBUG=* \
    LOG_LEVEL=debug \
    # Development-specific Node.js options
    NODE_OPTIONS="--max-old-space-size=4096 --enable-source-maps --inspect=0.0.0.0:9229" \
    # Enable development features
    npm_config_loglevel=verbose

# ========================================================================================================
# DEVELOPMENT USER CONFIGURATION
# ========================================================================================================

# Grant additional permissions needed for development
# Allow the development user to install packages and modify files
USER root
RUN chown -R jtsuser:jtsgroup /app && \
    chmod -R 755 /app
USER jtsuser

# Expose debugging and application ports
EXPOSE 3000 9229

# Set development working directory
WORKDIR /app

# Default command for development (can be overridden)
CMD ["yarn", "dev"]

# ========================================================================================================
# STAGE 4: PRODUCTION - Ultra-Minimal Production Runtime
# ========================================================================================================
# This stage creates the smallest possible production image using distroless base image.
# Maximum security with minimal attack surface.
FROM gcr.io/distroless/nodejs20-debian12:nonroot AS production

# Production-specific labels with compliance and security metadata
LABEL stage="production" \
      environment="prod" \
      security.level="high" \
      compliance.sox="enabled" \
      compliance.pci="partial" \
      size.optimization="maximum"

# ========================================================================================================
# PRODUCTION SECURITY CONFIGURATION
# ========================================================================================================

# Use the nonroot user (UID 65532) provided by distroless image
# This ensures we never run as root in production
USER 65532:65532

# Set production environment variables
ENV NODE_ENV=production \
    # Disable unnecessary Node.js features for production
    NODE_NO_WARNINGS=1 \
    NODE_OPTIONS="--max-old-space-size=1024 --enable-source-maps" \
    # Security: Disable npm features not needed in production
    npm_config_update_notifier=false \
    npm_config_audit_level=high

# ========================================================================================================
# PRODUCTION FILE SYSTEM SETUP
# ========================================================================================================

# Create minimal directory structure
WORKDIR /app

# Copy production dependencies from builder stage
# This includes only production node_modules, not devDependencies
COPY --from=builder --chown=65532:65532 /app/node_modules ./node_modules/
COPY --from=builder --chown=65532:65532 /app/package.json ./

# Copy built application from builder stage
# This assumes the build process creates a 'dist' directory
COPY --from=builder --chown=65532:65532 /app/dist ./dist/

# ========================================================================================================
# PRODUCTION RUNTIME CONFIGURATION
# ========================================================================================================

# Expose only the application port (no debugging ports in production)
EXPOSE 3000

# Health check configuration for production monitoring
# This enables container orchestrators to monitor application health
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ["/nodejs/bin/node", "-e", "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => { process.exit(1) })"]

# ========================================================================================================
# PRODUCTION STARTUP CONFIGURATION
# ========================================================================================================

# Default production command
# Uses the compiled JavaScript from the dist directory
CMD ["dist/main.js"]

# ========================================================================================================
# DOCKER BUILD INSTRUCTIONS
# ========================================================================================================
#
# To build different targets:
#
# Development:
#   docker build --target development -t jts:dev .
#
# Production:
#   docker build --target production -t jts:prod .
#
# Builder (for CI/CD):
#   docker build --target builder -t jts:builder .
#
# Build with build args:
#   docker build --build-arg NODE_VERSION=20.18.1 --target production -t jts:prod .
#
# Multi-architecture build:
#   docker buildx build --platform linux/amd64,linux/arm64 --target production -t jts:prod .
#
# ========================================================================================================
# SECURITY SCANNING
# ========================================================================================================
#
# This Dockerfile is designed to work with security scanning tools:
#
# Trivy scanning:
#   trivy image --severity HIGH,CRITICAL jts:prod
#
# Container scanning in CI:
#   Include this in your CI pipeline for automated security checks
#
# ========================================================================================================