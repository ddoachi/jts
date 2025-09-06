#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# JTS Blue-Green Deployment Health Check Script
# ═══════════════════════════════════════════════════════════════════
#
# Purpose: Comprehensive health checks for blue-green deployments
# Usage: ./health-check.sh <color> <environment> [timeout]
# Example: ./health-check.sh green staging 300
#

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COLOR="${1:-green}"
readonly ENVIRONMENT="${2:-staging}"
readonly TIMEOUT="${3:-300}"
readonly RETRY_INTERVAL=10
readonly MAX_RETRIES=$((TIMEOUT / RETRY_INTERVAL))

# Health check thresholds
readonly RESPONSE_TIME_THRESHOLD=2000  # 2 seconds
readonly ERROR_RATE_THRESHOLD=0.01     # 1%
readonly CPU_THRESHOLD=80              # 80%
readonly MEMORY_THRESHOLD=85           # 85%

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Service endpoints
declare -A SERVICES=(
    ["api-gateway"]="/health"
    ["strategy-engine"]="/health"
    ["risk-management"]="/health"
    ["order-execution"]="/health"
    ["market-data"]="/health"
    ["portfolio-service"]="/health"
)

# ═══════════════════════════════════════════════════════════════════
# Utility Functions
# ═══════════════════════════════════════════════════════════════════

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC}  ${timestamp} - $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  ${timestamp} - $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message" ;;
    esac
}

get_service_url() {
    local service="$1"
    local namespace="${ENVIRONMENT}-${COLOR}"
    
    if command -v kubectl >/dev/null 2>&1; then
        # Kubernetes environment
        local service_name="${service}-${COLOR}"
        kubectl get service "$service_name" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || \
        kubectl get service "$service_name" -n "$namespace" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || \
        echo "localhost"
    else
        # Local/Docker environment
        echo "localhost"
    fi
}

get_service_port() {
    local service="$1"
    local namespace="${ENVIRONMENT}-${COLOR}"
    
    if command -v kubectl >/dev/null 2>&1; then
        local service_name="${service}-${COLOR}"
        kubectl get service "$service_name" -n "$namespace" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "3000"
    else
        # Default ports for local development
        case "$service" in
            "api-gateway")      echo "3000" ;;
            "strategy-engine")  echo "3001" ;;
            "risk-management")  echo "3002" ;;
            "order-execution")  echo "3003" ;;
            "market-data")      echo "3004" ;;
            "portfolio-service") echo "3005" ;;
            *)                  echo "3000" ;;
        esac
    fi
}

# ═══════════════════════════════════════════════════════════════════
# Health Check Functions
# ═══════════════════════════════════════════════════════════════════

check_service_health() {
    local service="$1"
    local endpoint="${SERVICES[$service]}"
    local host=$(get_service_url "$service")
    local port=$(get_service_port "$service")
    local url="http://${host}:${port}${endpoint}"
    
    log "DEBUG" "Checking health for $service at $url"
    
    # Health check with timeout and detailed metrics
    local response=$(curl -s -w "%{http_code}|%{time_total}|%{size_download}" \
        --max-time 10 \
        --connect-timeout 5 \
        "$url" 2>/dev/null || echo "000|0|0")
    
    IFS='|' read -r status_code response_time size <<< "$response"
    
    # Convert response time to milliseconds
    local response_time_ms=$(echo "$response_time * 1000" | bc -l 2>/dev/null || echo "0")
    
    if [[ "$status_code" == "200" ]]; then
        log "INFO" "$service: ✅ Healthy (${response_time_ms}ms)"
        return 0
    else
        log "ERROR" "$service: ❌ Unhealthy (HTTP $status_code, ${response_time_ms}ms)"
        return 1
    fi
}

check_readiness() {
    local service="$1"
    local host=$(get_service_url "$service")
    local port=$(get_service_port "$service")
    local url="http://${host}:${port}/ready"
    
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 5 \
        "$url" 2>/dev/null || echo "000")
    
    if [[ "$status_code" == "200" ]]; then
        log "INFO" "$service: ✅ Ready"
        return 0
    else
        log "WARN" "$service: ⏳ Not ready (HTTP $status_code)"
        return 1
    fi
}

check_kubernetes_resources() {
    if ! command -v kubectl >/dev/null 2>&1; then
        log "WARN" "kubectl not found, skipping Kubernetes resource checks"
        return 0
    fi
    
    local namespace="${ENVIRONMENT}-${COLOR}"
    
    log "INFO" "Checking Kubernetes resources in namespace: $namespace"
    
    # Check deployments
    local failed_deployments=0
    for service in "${!SERVICES[@]}"; do
        local deployment="${service}-${COLOR}"
        local ready_replicas=$(kubectl get deployment "$deployment" -n "$namespace" \
            -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas=$(kubectl get deployment "$deployment" -n "$namespace" \
            -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
        
        if [[ "$ready_replicas" != "$desired_replicas" ]]; then
            log "ERROR" "$deployment: ❌ $ready_replicas/$desired_replicas replicas ready"
            ((failed_deployments++))
        else
            log "INFO" "$deployment: ✅ $ready_replicas/$desired_replicas replicas ready"
        fi
    done
    
    return $failed_deployments
}

check_resource_usage() {
    if ! command -v kubectl >/dev/null 2>&1; then
        log "WARN" "kubectl not found, skipping resource usage checks"
        return 0
    fi
    
    local namespace="${ENVIRONMENT}-${COLOR}"
    
    log "INFO" "Checking resource usage for $COLOR environment"
    
    # Check CPU and memory usage for all pods
    local pods=$(kubectl get pods -n "$namespace" -l "deployment=$COLOR" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -z "$pods" ]]; then
        log "WARN" "No pods found in namespace $namespace with label deployment=$COLOR"
        return 1
    fi
    
    local high_usage_count=0
    for pod in $pods; do
        # Get resource usage (requires metrics-server)
        if kubectl top pod "$pod" -n "$namespace" >/dev/null 2>&1; then
            local usage=$(kubectl top pod "$pod" -n "$namespace" --no-headers 2>/dev/null || echo "")
            if [[ -n "$usage" ]]; then
                log "INFO" "$pod resource usage: $usage"
            fi
        else
            log "DEBUG" "Metrics not available for $pod (metrics-server may not be installed)"
        fi
    done
    
    return $high_usage_count
}

check_service_connectivity() {
    log "INFO" "Testing inter-service connectivity"
    
    # Test database connectivity
    for service in "${!SERVICES[@]}"; do
        local host=$(get_service_url "$service")
        local port=$(get_service_port "$service")
        local url="http://${host}:${port}/health/db"
        
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time 5 \
            "$url" 2>/dev/null || echo "000")
        
        if [[ "$status_code" == "200" ]]; then
            log "INFO" "$service: ✅ Database connectivity OK"
        else
            log "WARN" "$service: ⚠️  Database connectivity check failed (HTTP $status_code)"
        fi
    done
}

perform_smoke_tests() {
    log "INFO" "Performing smoke tests on $COLOR environment"
    
    # Test API Gateway endpoints
    local api_host=$(get_service_url "api-gateway")
    local api_port=$(get_service_port "api-gateway")
    local api_base="http://${api_host}:${api_port}/api/v1"
    
    # Test basic endpoints
    local endpoints=(
        "/health"
        "/info"
        "/metrics"
    )
    
    local failed_tests=0
    for endpoint in "${endpoints[@]}"; do
        local url="${api_base}${endpoint}"
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time 10 \
            "$url" 2>/dev/null || echo "000")
        
        if [[ "$status_code" =~ ^[23][0-9][0-9]$ ]]; then
            log "INFO" "Smoke test ✅: $endpoint (HTTP $status_code)"
        else
            log "ERROR" "Smoke test ❌: $endpoint (HTTP $status_code)"
            ((failed_tests++))
        fi
    done
    
    return $failed_tests
}

# ═══════════════════════════════════════════════════════════════════
# Main Health Check Function
# ═══════════════════════════════════════════════════════════════════

main() {
    log "INFO" "Starting health check for $COLOR environment ($ENVIRONMENT)"
    log "INFO" "Timeout: ${TIMEOUT}s, Max retries: $MAX_RETRIES"
    
    local retry_count=0
    local overall_health=1
    
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        overall_health=0
        local failed_checks=0
        
        log "INFO" "Health check attempt $((retry_count + 1))/$MAX_RETRIES"
        
        # 1. Check Kubernetes resources
        if ! check_kubernetes_resources; then
            log "WARN" "Some Kubernetes resources are not ready"
            ((failed_checks++))
        fi
        
        # 2. Check individual service health
        for service in "${!SERVICES[@]}"; do
            if ! check_service_health "$service"; then
                ((failed_checks++))
            fi
        done
        
        # 3. Check readiness
        for service in "${!SERVICES[@]}"; do
            check_readiness "$service" || true  # Don't fail on readiness check
        done
        
        # 4. Check resource usage
        check_resource_usage || true  # Don't fail on resource checks
        
        # 5. Test connectivity
        check_service_connectivity || true  # Don't fail on connectivity checks
        
        # 6. Perform smoke tests
        if ! perform_smoke_tests; then
            log "WARN" "Some smoke tests failed"
            ((failed_checks++))
        fi
        
        if [[ $failed_checks -eq 0 ]]; then
            log "INFO" "🎉 All health checks passed for $COLOR environment!"
            overall_health=0
            break
        else
            log "WARN" "Health check failed ($failed_checks issues). Retrying in ${RETRY_INTERVAL}s..."
            ((retry_count++))
            
            if [[ $retry_count -lt $MAX_RETRIES ]]; then
                sleep $RETRY_INTERVAL
            fi
        fi
    done
    
    if [[ $overall_health -eq 0 ]]; then
        log "INFO" "✅ $COLOR environment is healthy and ready for traffic"
    else
        log "ERROR" "❌ $COLOR environment failed health checks after $MAX_RETRIES attempts"
    fi
    
    return $overall_health
}

# ═══════════════════════════════════════════════════════════════════
# Script Entry Point
# ═══════════════════════════════════════════════════════════════════

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Validate arguments
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <color> <environment> [timeout]"
        echo "Example: $0 green staging 300"
        exit 1
    fi
    
    # Ensure bc is available for calculations
    if ! command -v bc >/dev/null 2>&1; then
        log "WARN" "bc command not found, response time calculations may be inaccurate"
    fi
    
    main "$@"
fi