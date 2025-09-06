#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# Database Migration Safety Check Script
# ═══════════════════════════════════════════════════════════════════
#
# Generated from spec: [[E01-F04-T04] Deployment Pipeline Workflows]
# Purpose: Validate database migration safety before execution
#
# Usage: ./migration-safety-check.sh <environment> [--dry-run]
# Example: ./migration-safety-check.sh production --dry-run
#
# Exit Codes:
#   0 - Migration safe to proceed
#   1 - Migration unsafe or validation failed
#   2 - Configuration error
#   3 - Backup failure

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════

ENVIRONMENT="${1:-development}"
DRY_RUN="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

get_db_config() {
    # WHY: Need environment-specific database configuration
    # HOW: Parse environment variables based on environment
    # WHAT: Return database connection parameters
    
    case "$ENVIRONMENT" in
        production)
            DB_HOST="${PROD_DB_HOST:-localhost}"
            DB_PORT="${PROD_DB_PORT:-5432}"
            DB_NAME="${PROD_DB_NAME:-jts_production}"
            DB_USER="${PROD_DB_USER:-jts_prod}"
            CLICKHOUSE_HOST="${PROD_CLICKHOUSE_HOST:-localhost}"
            CLICKHOUSE_PORT="${PROD_CLICKHOUSE_PORT:-8123}"
            ;;
        staging)
            DB_HOST="${STAGING_DB_HOST:-localhost}"
            DB_PORT="${STAGING_DB_PORT:-5432}"
            DB_NAME="${STAGING_DB_NAME:-jts_staging}"
            DB_USER="${STAGING_DB_USER:-jts_staging}"
            CLICKHOUSE_HOST="${STAGING_CLICKHOUSE_HOST:-localhost}"
            CLICKHOUSE_PORT="${STAGING_CLICKHOUSE_PORT:-8123}"
            ;;
        development)
            DB_HOST="${DEV_DB_HOST:-localhost}"
            DB_PORT="${DEV_DB_PORT:-5442}"  # Note: Different port for dev
            DB_NAME="${DEV_DB_NAME:-jts_development}"
            DB_USER="${DEV_DB_USER:-jts_dev}"
            CLICKHOUSE_HOST="${DEV_CLICKHOUSE_HOST:-localhost}"
            CLICKHOUSE_PORT="${DEV_CLICKHOUSE_PORT:-8123}"
            ;;
        *)
            log_error "Unknown environment: $ENVIRONMENT"
            exit 2
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# Migration File Analysis
# ═══════════════════════════════════════════════════════════════════

check_pending_migrations() {
    log_info "Checking for pending migrations..."
    
    # WHY: Identify what changes will be applied
    # HOW: Compare migration files with applied migrations
    # WHAT: List of pending migration files
    
    local migrations_dir="$PROJECT_ROOT/migrations"
    
    if [[ ! -d "$migrations_dir" ]]; then
        log_warning "Migrations directory not found: $migrations_dir"
        return 0
    fi
    
    # Count pending migrations
    local pending_count=$(find "$migrations_dir" -name "*.sql" -type f 2>/dev/null | wc -l)
    
    if [[ "$pending_count" -eq 0 ]]; then
        log_info "No pending migrations found"
        return 0
    fi
    
    log_info "Found $pending_count pending migration files:"
    
    # List migration files
    find "$migrations_dir" -name "*.sql" -type f -exec basename {} \; | sort
    
    # Analyze migration content for dangerous operations
    local dangerous_operations=0
    local warnings=""
    
    for migration in $(find "$migrations_dir" -name "*.sql" -type f); do
        local filename=$(basename "$migration")
        
        # Check for dangerous DDL operations
        if grep -iE "DROP\s+(TABLE|DATABASE|SCHEMA|INDEX)" "$migration" > /dev/null; then
            warnings="${warnings}\n  - $filename contains DROP statements"
            ((dangerous_operations++))
        fi
        
        if grep -iE "TRUNCATE\s+TABLE" "$migration" > /dev/null; then
            warnings="${warnings}\n  - $filename contains TRUNCATE statements"
            ((dangerous_operations++))
        fi
        
        if grep -iE "ALTER\s+TABLE.*DROP\s+COLUMN" "$migration" > /dev/null; then
            warnings="${warnings}\n  - $filename drops columns"
            ((dangerous_operations++))
        fi
        
        # Check for missing transaction blocks
        if ! grep -iE "BEGIN|START TRANSACTION" "$migration" > /dev/null; then
            warnings="${warnings}\n  - $filename lacks explicit transaction"
        fi
    done
    
    if [[ "$dangerous_operations" -gt 0 ]]; then
        log_warning "Found $dangerous_operations potentially dangerous operations:"
        echo -e "$warnings"
        
        if [[ "$ENVIRONMENT" == "production" ]]; then
            log_error "Dangerous operations detected in production migrations"
            return 1
        fi
    fi
    
    log_success "Migration file analysis complete"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Database Connection Validation
# ═══════════════════════════════════════════════════════════════════

validate_database_connection() {
    log_info "Validating database connections..."
    
    # PostgreSQL connection test
    log_info "Testing PostgreSQL connection..."
    if command -v psql > /dev/null; then
        if PGPASSWORD="${DB_PASSWORD:-}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
            log_success "PostgreSQL connection successful"
        else
            log_error "PostgreSQL connection failed"
            return 1
        fi
    else
        log_warning "psql not installed, skipping PostgreSQL connection test"
    fi
    
    # ClickHouse connection test
    log_info "Testing ClickHouse connection..."
    if command -v clickhouse-client > /dev/null; then
        if clickhouse-client --host "$CLICKHOUSE_HOST" --port "$CLICKHOUSE_PORT" --query "SELECT 1" > /dev/null 2>&1; then
            log_success "ClickHouse connection successful"
        else
            log_warning "ClickHouse connection failed (non-critical)"
        fi
    else
        log_warning "clickhouse-client not installed, skipping ClickHouse test"
    fi
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Active Connection Check
# ═══════════════════════════════════════════════════════════════════

check_active_connections() {
    log_info "Checking active database connections..."
    
    # WHY: Ensure migration won't disrupt active operations
    # HOW: Query database for active connection count
    # WHAT: Validation of safe migration window
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        # For production, check active connections
        local active_connections=$(PGPASSWORD="${DB_PASSWORD:-}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
            SELECT COUNT(*) 
            FROM pg_stat_activity 
            WHERE datname = '$DB_NAME' 
            AND state = 'active' 
            AND pid != pg_backend_pid()
        " 2>/dev/null | xargs)
        
        if [[ -n "$active_connections" ]]; then
            log_info "Active connections: $active_connections"
            
            if [[ "$active_connections" -gt 100 ]]; then
                log_warning "High number of active connections ($active_connections)"
                
                # Check for long-running queries
                local long_queries=$(PGPASSWORD="${DB_PASSWORD:-}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
                    SELECT COUNT(*) 
                    FROM pg_stat_activity 
                    WHERE datname = '$DB_NAME' 
                    AND state = 'active' 
                    AND now() - query_start > interval '5 minutes'
                " 2>/dev/null | xargs)
                
                if [[ "$long_queries" -gt 0 ]]; then
                    log_error "Found $long_queries long-running queries (>5 minutes)"
                    return 1
                fi
            fi
        fi
    fi
    
    log_success "Connection check passed"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Backup Validation
# ═══════════════════════════════════════════════════════════════════

create_backup() {
    log_info "Creating database backup..."
    
    # WHY: Ensure we can recover if migration fails
    # HOW: Create timestamped backup with verification
    # WHAT: Validated backup file ready for restore
    
    local backup_dir="$PROJECT_ROOT/backups"
    mkdir -p "$backup_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/${ENVIRONMENT}_${DB_NAME}_${timestamp}.sql"
    
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        log_info "DRY RUN: Would create backup at $backup_file"
        return 0
    fi
    
    log_info "Creating backup: $backup_file"
    
    # Create backup with progress
    if command -v pv > /dev/null; then
        PGPASSWORD="${DB_PASSWORD:-}" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" | \
            pv -p -t -e -r -b > "$backup_file"
    else
        PGPASSWORD="${DB_PASSWORD:-}" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "$backup_file"
    fi
    
    if [[ ! -f "$backup_file" ]] || [[ ! -s "$backup_file" ]]; then
        log_error "Backup creation failed or file is empty"
        return 3
    fi
    
    # Compress backup
    log_info "Compressing backup..."
    gzip "$backup_file"
    backup_file="${backup_file}.gz"
    
    # Verify backup
    local backup_size=$(du -h "$backup_file" | cut -f1)
    log_success "Backup created successfully: $backup_file ($backup_size)"
    
    # Upload to S3 if configured
    if [[ -n "${AWS_S3_BACKUP_BUCKET:-}" ]]; then
        log_info "Uploading backup to S3..."
        aws s3 cp "$backup_file" "s3://${AWS_S3_BACKUP_BUCKET}/database-backups/${ENVIRONMENT}/" || {
            log_warning "S3 upload failed, keeping local backup"
        }
    fi
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Migration Simulation
# ═══════════════════════════════════════════════════════════════════

simulate_migration() {
    log_info "Simulating migration execution..."
    
    # WHY: Validate migration will execute successfully
    # HOW: Run migration in transaction and rollback
    # WHAT: Verification of migration syntax and logic
    
    if [[ "$DRY_RUN" != "--dry-run" ]]; then
        log_info "Skipping simulation (use --dry-run to enable)"
        return 0
    fi
    
    local migrations_dir="$PROJECT_ROOT/migrations"
    local simulation_failed=0
    
    for migration in $(find "$migrations_dir" -name "*.sql" -type f | sort); do
        local filename=$(basename "$migration")
        log_info "Simulating: $filename"
        
        # Create test transaction
        local test_script=$(cat <<EOF
BEGIN;
-- Migration simulation for $filename
$(cat "$migration")
-- Rollback simulation
ROLLBACK;
EOF
)
        
        # Execute simulation
        if PGPASSWORD="${DB_PASSWORD:-}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -c "$test_script" > /dev/null 2>&1; then
            log_success "Simulation passed: $filename"
        else
            log_error "Simulation failed: $filename"
            ((simulation_failed++))
        fi
    done
    
    if [[ "$simulation_failed" -gt 0 ]]; then
        log_error "$simulation_failed migration simulations failed"
        return 1
    fi
    
    log_success "All migration simulations passed"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Rollback Plan Generation
# ═══════════════════════════════════════════════════════════════════

generate_rollback_plan() {
    log_info "Generating rollback plan..."
    
    # WHY: Ensure we can quickly recover from failed migration
    # HOW: Create reverse migration scripts
    # WHAT: Ready-to-execute rollback procedures
    
    local rollback_dir="$PROJECT_ROOT/rollbacks"
    mkdir -p "$rollback_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local rollback_file="$rollback_dir/${ENVIRONMENT}_rollback_${timestamp}.md"
    
    cat > "$rollback_file" <<EOF
# Migration Rollback Plan

## Environment: ${ENVIRONMENT}
## Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

### Quick Rollback Commands

\`\`\`bash
# 1. Stop application servers
kubectl scale deployment --replicas=0 -n jts-${ENVIRONMENT} --all

# 2. Restore database from backup
gunzip -c ${backup_file:-backup.sql.gz} | \\
  PGPASSWORD=\${DB_PASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME}

# 3. Restart application servers
kubectl scale deployment --replicas=3 -n jts-${ENVIRONMENT} --all

# 4. Validate services
./scripts/deployment/validate-deployment.sh ${ENVIRONMENT}
\`\`\`

### Manual Rollback Steps

1. **Notify team** of rollback initiation
2. **Stop write operations** to database
3. **Create current state backup** (safety measure)
4. **Execute rollback** using commands above
5. **Verify data integrity** with test queries
6. **Resume operations** after validation
7. **Document incident** for post-mortem

### Emergency Contacts

- Database Team: db-team@jts.com
- DevOps Team: devops@jts.com
- On-Call: +1-555-EMERGENCY

### Validation Queries

\`\`\`sql
-- Check migration version
SELECT version, applied_at FROM schema_migrations ORDER BY version DESC LIMIT 5;

-- Verify data integrity
SELECT COUNT(*) FROM critical_table;

-- Check for data anomalies
SELECT * FROM audit_log WHERE timestamp > NOW() - INTERVAL '1 hour';
\`\`\`
EOF
    
    log_success "Rollback plan generated: $rollback_file"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Main Safety Check Flow
# ═══════════════════════════════════════════════════════════════════

main() {
    echo "═══════════════════════════════════════════════════════════════════"
    echo "   Database Migration Safety Check"
    echo "═══════════════════════════════════════════════════════════════════"
    echo "Environment: $ENVIRONMENT"
    echo "Mode: ${DRY_RUN:-normal}"
    echo "Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    
    # Load database configuration
    get_db_config
    
    # Track safety check results
    local checks_failed=0
    
    # 1. Check pending migrations
    if ! check_pending_migrations; then
        ((checks_failed++))
    fi
    
    # 2. Validate database connection
    if ! validate_database_connection; then
        log_error "Cannot proceed without database connection"
        exit 2
    fi
    
    # 3. Check active connections
    if ! check_active_connections; then
        ((checks_failed++))
    fi
    
    # 4. Create backup (critical for production)
    if [[ "$ENVIRONMENT" == "production" ]] || [[ "$DRY_RUN" != "--dry-run" ]]; then
        if ! create_backup; then
            log_error "Backup creation failed - cannot proceed"
            exit 3
        fi
    fi
    
    # 5. Simulate migration (dry-run only)
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        if ! simulate_migration; then
            ((checks_failed++))
        fi
    fi
    
    # 6. Generate rollback plan
    if ! generate_rollback_plan; then
        log_warning "Rollback plan generation failed (non-critical)"
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    
    if [[ "$checks_failed" -gt 0 ]]; then
        log_error "Migration safety check FAILED ($checks_failed checks failed)"
        echo "Please address the issues before proceeding with migration"
        exit 1
    else
        log_success "Migration safety check PASSED"
        echo "Safe to proceed with database migration"
        exit 0
    fi
}

# Run main function
main "$@"