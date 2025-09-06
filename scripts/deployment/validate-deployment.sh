#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# Deployment Validation Script
# ═══════════════════════════════════════════════════════════════════
#
# Generated from spec: [[E01-F04-T04] Deployment Pipeline Workflows]
# Purpose: Comprehensive deployment validation for all environments
#
# Usage: ./validate-deployment.sh <environment> <deployment-type>
# Example: ./validate-deployment.sh production blue-green
#
# Exit Codes:
#   0 - Validation successful
#   1 - Validation failed
#   2 - Configuration error
#   3 - Timeout exceeded

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════

ENVIRONMENT="${1:-development}"
DEPLOYMENT_TYPE="${2:-standard}"
TIMEOUT="${VALIDATION_TIMEOUT:-300}"
NAMESPACE="jts-${ENVIRONMENT}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisite() {
    # WHY: Ensure required tools are available
    # HOW: Check for command existence
    # WHAT: Validate kubectl and curl availability
    
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd is required but not installed"
        exit 2
    fi
}

# ═══════════════════════════════════════════════════════════════════
# Kubernetes Validation
# ═══════════════════════════════════════════════════════════════════

validate_kubernetes_deployment() {
    log_info "Validating Kubernetes deployment..."
    
    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_error "Namespace $NAMESPACE does not exist"
        return 1
    fi
    
    # Get all deployments in namespace
    local deployments=$(kubectl get deployments -n "$NAMESPACE" -o json)
    local total_deployments=$(echo "$deployments" | jq '.items | length')
    
    if [[ "$total_deployments" -eq 0 ]]; then
        log_error "No deployments found in namespace $NAMESPACE"
        return 1
    fi
    
    log_info "Found $total_deployments deployments"
    
    # Check each deployment
    local failed_deployments=0
    for i in $(seq 0 $((total_deployments - 1))); do
        local name=$(echo "$deployments" | jq -r ".items[$i].metadata.name")
        local replicas=$(echo "$deployments" | jq ".items[$i].spec.replicas")
        local ready_replicas=$(echo "$deployments" | jq ".items[$i].status.readyReplicas // 0")
        
        if [[ "$ready_replicas" -lt "$replicas" ]]; then
            log_warning "Deployment $name: $ready_replicas/$replicas replicas ready"
            ((failed_deployments++))
        else
            log_success "Deployment $name: $ready_replicas/$replicas replicas ready"
        fi
    done
    
    if [[ "$failed_deployments" -gt 0 ]]; then
        log_error "$failed_deployments deployments not fully ready"
        return 1
    fi
    
    log_success "All deployments are ready"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Blue-Green Validation
# ═══════════════════════════════════════════════════════════════════

validate_blue_green() {
    log_info "Validating blue-green deployment..."
    
    # WHY: Ensure blue-green environments are properly configured
    # HOW: Check both environments and active service selector
    # WHAT: Validate zero-downtime capability
    
    local active_service="api-gateway-active"
    
    # Get active environment
    local active_env=$(kubectl get service "$active_service" -n "$NAMESPACE" \
        -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "unknown")
    
    if [[ "$active_env" == "unknown" ]]; then
        log_error "Cannot determine active environment"
        return 1
    fi
    
    log_info "Active environment: $active_env"
    
    # Check blue environment
    local blue_pods=$(kubectl get pods -n "$NAMESPACE" -l "version=blue" --no-headers 2>/dev/null | wc -l)
    log_info "Blue environment: $blue_pods pods"
    
    # Check green environment
    local green_pods=$(kubectl get pods -n "$NAMESPACE" -l "version=green" --no-headers 2>/dev/null | wc -l)
    log_info "Green environment: $green_pods pods"
    
    # Validate at least one environment is ready
    if [[ "$blue_pods" -eq 0 ]] && [[ "$green_pods" -eq 0 ]]; then
        log_error "No pods found in either blue or green environment"
        return 1
    fi
    
    # Check inactive environment is scaled down (for resource optimization)
    local inactive_env=$([ "$active_env" = "blue" ] && echo "green" || echo "blue")
    local inactive_pods=$(kubectl get pods -n "$NAMESPACE" -l "version=$inactive_env" --no-headers 2>/dev/null | wc -l)
    
    if [[ "$ENVIRONMENT" == "production" ]] && [[ "$inactive_pods" -eq 0 ]]; then
        log_warning "Inactive environment ($inactive_env) has no pods - rollback capability compromised"
    fi
    
    log_success "Blue-green deployment validated"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Health Check Validation
# ═══════════════════════════════════════════════════════════════════

validate_health_endpoints() {
    log_info "Validating health endpoints..."
    
    # Determine base URL based on environment
    local base_url=""
    case "$ENVIRONMENT" in
        production)
            base_url="https://api.jts.com"
            ;;
        staging)
            base_url="https://staging.jts.com"
            ;;
        development)
            base_url="https://dev.jts.com"
            ;;
        *)
            log_error "Unknown environment: $ENVIRONMENT"
            return 2
            ;;
    esac
    
    # Health endpoints to check
    local endpoints=(
        "/health"
        "/api/trading/health"
        "/api/market/health"
        "/api/order/health"
        "/api/risk/health"
    )
    
    local failed_checks=0
    for endpoint in "${endpoints[@]}"; do
        local url="${base_url}${endpoint}"
        log_info "Checking: $url"
        
        local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 10)
        
        if [[ "$response_code" == "200" ]]; then
            log_success "$endpoint - OK (${response_code})"
        else
            log_error "$endpoint - FAILED (${response_code})"
            ((failed_checks++))
        fi
    done
    
    if [[ "$failed_checks" -gt 0 ]]; then
        log_error "$failed_checks health checks failed"
        return 1
    fi
    
    log_success "All health endpoints are responding"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Performance Validation
# ═══════════════════════════════════════════════════════════════════

validate_performance_metrics() {
    log_info "Validating performance metrics..."
    
    # WHY: Ensure deployment meets performance requirements
    # HOW: Check response times and error rates
    # WHAT: Validate SLA compliance
    
    local base_url=""
    case "$ENVIRONMENT" in
        production)
            base_url="https://api.jts.com"
            local max_response_time=200  # 200ms for production
            ;;
        staging)
            base_url="https://staging.jts.com"
            local max_response_time=500  # 500ms for staging
            ;;
        development)
            base_url="https://dev.jts.com"
            local max_response_time=1000  # 1s for development
            ;;
    esac
    
    # Perform 10 requests and calculate average
    local total_time=0
    local successful_requests=0
    
    for i in {1..10}; do
        local response_time=$(curl -s -o /dev/null -w "%{time_total}" "${base_url}/health" --max-time 5 || echo "5")
        
        # Convert to milliseconds
        response_time=$(echo "$response_time * 1000" | bc | cut -d. -f1)
        
        if [[ "$response_time" -lt 5000 ]]; then
            total_time=$((total_time + response_time))
            ((successful_requests++))
        fi
        
        sleep 0.5
    done
    
    if [[ "$successful_requests" -eq 0 ]]; then
        log_error "All performance test requests failed"
        return 1
    fi
    
    local avg_response_time=$((total_time / successful_requests))
    log_info "Average response time: ${avg_response_time}ms (${successful_requests}/10 successful)"
    
    if [[ "$avg_response_time" -gt "$max_response_time" ]]; then
        log_error "Response time ${avg_response_time}ms exceeds threshold ${max_response_time}ms"
        return 1
    fi
    
    log_success "Performance metrics within acceptable range"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Database Validation
# ═══════════════════════════════════════════════════════════════════

validate_database_connectivity() {
    log_info "Validating database connectivity..."
    
    # WHY: Ensure all database connections are healthy
    # HOW: Check pod logs for connection errors
    # WHAT: Validate data layer health
    
    local deployments=("api-gateway" "strategy-engine" "order-execution" "risk-management")
    local connection_errors=0
    
    for deployment in "${deployments[@]}"; do
        log_info "Checking database connections for $deployment..."
        
        # Get pod name
        local pod=$(kubectl get pods -n "$NAMESPACE" -l "app=$deployment" \
            -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        
        if [[ -z "$pod" ]]; then
            log_warning "No pods found for $deployment"
            continue
        fi
        
        # Check recent logs for database errors
        local db_errors=$(kubectl logs "$pod" -n "$NAMESPACE" --since=5m 2>/dev/null | \
            grep -iE "database|connection|postgres|clickhouse|mongodb|redis" | \
            grep -iE "error|failed|refused|timeout" | wc -l)
        
        if [[ "$db_errors" -gt 0 ]]; then
            log_warning "$deployment has $db_errors database-related errors in recent logs"
            ((connection_errors++))
        else
            log_success "$deployment database connections healthy"
        fi
    done
    
    if [[ "$connection_errors" -gt 0 ]]; then
        log_warning "$connection_errors services have database connection issues"
        # Don't fail for development environment
        if [[ "$ENVIRONMENT" == "production" ]]; then
            return 1
        fi
    fi
    
    log_success "Database connectivity validated"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Trading System Validation (Production Only)
# ═══════════════════════════════════════════════════════════════════

validate_trading_systems() {
    if [[ "$ENVIRONMENT" != "production" ]]; then
        log_info "Skipping trading system validation for $ENVIRONMENT"
        return 0
    fi
    
    log_info "Validating trading systems..."
    
    # WHY: Critical for financial system integrity
    # HOW: Check trading-specific endpoints and order flow
    # WHAT: Ensure trading capabilities are operational
    
    local trading_checks=(
        "https://api.jts.com/api/trading/status:trading_enabled:true"
        "https://api.jts.com/api/market/status:market_data_flowing:true"
        "https://api.jts.com/api/risk/status:risk_checks_enabled:true"
        "https://api.jts.com/api/settlement/status:settlement_active:true"
    )
    
    local failed_checks=0
    for check in "${trading_checks[@]}"; do
        IFS=':' read -r url json_path expected_value <<< "$check"
        
        log_info "Validating: $url"
        
        local response=$(curl -s "$url" --max-time 10)
        local actual_value=$(echo "$response" | jq -r ".$json_path" 2>/dev/null)
        
        if [[ "$actual_value" == "$expected_value" ]]; then
            log_success "Trading check passed: $json_path = $actual_value"
        else
            log_error "Trading check failed: $json_path = $actual_value (expected: $expected_value)"
            ((failed_checks++))
        fi
    done
    
    if [[ "$failed_checks" -gt 0 ]]; then
        log_error "$failed_checks trading system checks failed"
        return 1
    fi
    
    log_success "All trading systems operational"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Main Validation Flow
# ═══════════════════════════════════════════════════════════════════

main() {
    echo "═══════════════════════════════════════════════════════════════════"
    echo "   Deployment Validation Script"
    echo "═══════════════════════════════════════════════════════════════════"
    echo "Environment: $ENVIRONMENT"
    echo "Deployment Type: $DEPLOYMENT_TYPE"
    echo "Namespace: $NAMESPACE"
    echo "Timeout: ${TIMEOUT}s"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    
    # Check prerequisites
    check_prerequisite "kubectl"
    check_prerequisite "curl"
    check_prerequisite "jq"
    check_prerequisite "bc"
    
    # Track validation results
    local validation_failed=0
    
    # Run validations with timeout
    timeout "$TIMEOUT" bash -c "
        # Kubernetes validation
        if ! validate_kubernetes_deployment; then
            exit 1
        fi
        
        # Blue-green validation (if applicable)
        if [[ '$DEPLOYMENT_TYPE' == 'blue-green' ]]; then
            if ! validate_blue_green; then
                exit 1
            fi
        fi
        
        # Health endpoint validation
        if ! validate_health_endpoints; then
            exit 1
        fi
        
        # Performance validation
        if ! validate_performance_metrics; then
            exit 1
        fi
        
        # Database connectivity validation
        if ! validate_database_connectivity; then
            exit 1
        fi
        
        # Trading system validation (production only)
        if ! validate_trading_systems; then
            exit 1
        fi
    " || validation_failed=$?
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    
    if [[ "$validation_failed" -eq 124 ]]; then
        log_error "Validation timeout exceeded (${TIMEOUT}s)"
        exit 3
    elif [[ "$validation_failed" -ne 0 ]]; then
        log_error "Deployment validation FAILED"
        exit 1
    else
        log_success "Deployment validation PASSED"
        echo "═══════════════════════════════════════════════════════════════════"
        exit 0
    fi
}

# Run main function
main "$@"