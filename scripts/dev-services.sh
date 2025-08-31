#!/bin/bash
# Generated from spec: E01-F02-T03 (Docker and Database Services Setup)
# Spec ID: ce5140df
# Service management script for JTS development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.dev.yml"
PROJECT_NAME="jts"

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_message $RED "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to check if docker-compose file exists
check_compose_file() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_message $RED "Docker Compose file not found: $COMPOSE_FILE"
        print_message $YELLOW "Please run this script from the project root directory"
        exit 1
    fi
}

# Function to start all services
start_services() {
    print_message $GREEN "Starting all JTS development services..."
    docker compose -f $COMPOSE_FILE -p $PROJECT_NAME up -d
    print_message $GREEN "Services started successfully"
    show_status
}

# Function to stop all services
stop_services() {
    print_message $YELLOW "Stopping all JTS development services..."
    docker compose -f $COMPOSE_FILE -p $PROJECT_NAME stop
    print_message $GREEN "Services stopped"
}

# Function to restart all services
restart_services() {
    print_message $YELLOW "Restarting all JTS development services..."
    docker compose -f $COMPOSE_FILE -p $PROJECT_NAME restart
    print_message $GREEN "Services restarted"
    show_status
}

# Function to remove all services and volumes
destroy_services() {
    print_message $RED "WARNING: This will remove all containers and volumes!"
    read -p "Are you sure you want to destroy all services and data? (yes/no): " -r
    if [[ $REPLY == "yes" ]]; then
        print_message $YELLOW "Destroying all services and volumes..."
        docker compose -f $COMPOSE_FILE -p $PROJECT_NAME down -v
        print_message $GREEN "All services and volumes removed"
    else
        print_message $YELLOW "Operation cancelled"
    fi
}

# Function to show service status
show_status() {
    print_message $BLUE "=== JTS Development Services Status ==="
    docker compose -f $COMPOSE_FILE -p $PROJECT_NAME ps
}

# Function to show service logs
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        print_message $BLUE "Showing logs for all services (Ctrl+C to exit)..."
        docker compose -f $COMPOSE_FILE -p $PROJECT_NAME logs -f
    else
        print_message $BLUE "Showing logs for $service (Ctrl+C to exit)..."
        docker compose -f $COMPOSE_FILE -p $PROJECT_NAME logs -f $service
    fi
}

# Function to execute command in a service
exec_service() {
    local service=$1
    shift
    local cmd=$@
    
    if [ -z "$service" ] || [ -z "$cmd" ]; then
        print_message $RED "Usage: $0 exec <service> <command>"
        exit 1
    fi
    
    print_message $BLUE "Executing in $service: $cmd"
    docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $service $cmd
}

# Function to test database connections
test_connections() {
    print_message $BLUE "=== Testing Database Connections ==="
    
    # Test PostgreSQL
    print_message $YELLOW "Testing PostgreSQL..."
    if docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T postgres pg_isready -U jts_admin &> /dev/null; then
        print_message $GREEN "✓ PostgreSQL is ready"
    else
        print_message $RED "✗ PostgreSQL is not ready"
    fi
    
    # Test MongoDB
    print_message $YELLOW "Testing MongoDB..."
    if docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T mongodb mongosh --eval "db.adminCommand('ping')" &> /dev/null; then
        print_message $GREEN "✓ MongoDB is ready"
    else
        print_message $RED "✗ MongoDB is not ready"
    fi
    
    # Test Redis
    print_message $YELLOW "Testing Redis..."
    if docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T redis redis-cli ping &> /dev/null; then
        print_message $GREEN "✓ Redis is ready"
    else
        print_message $RED "✗ Redis is not ready"
    fi
    
    # Test ClickHouse
    print_message $YELLOW "Testing ClickHouse..."
    if curl -s http://localhost:8123/ping &> /dev/null; then
        print_message $GREEN "✓ ClickHouse is ready"
    else
        print_message $RED "✗ ClickHouse is not ready"
    fi
    
    # Test Kafka
    print_message $YELLOW "Testing Kafka..."
    if docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T kafka kafka-broker-api-versions --bootstrap-server localhost:9093 &> /dev/null; then
        print_message $GREEN "✓ Kafka is ready"
    else
        print_message $RED "✗ Kafka is not ready"
    fi
}

# Function to backup databases
backup_databases() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p $backup_dir
    
    print_message $BLUE "=== Backing up databases to $backup_dir ==="
    
    # Backup PostgreSQL
    print_message $YELLOW "Backing up PostgreSQL..."
    docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T postgres pg_dump -U jts_admin jts_trading_dev > "$backup_dir/postgres.sql"
    print_message $GREEN "✓ PostgreSQL backed up"
    
    # Backup MongoDB
    print_message $YELLOW "Backing up MongoDB..."
    docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T mongodb mongodump --archive --db jts_config_dev > "$backup_dir/mongodb.archive"
    print_message $GREEN "✓ MongoDB backed up"
    
    # Backup Redis
    print_message $YELLOW "Backing up Redis..."
    docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T redis redis-cli --rdb "$backup_dir/redis.rdb"
    print_message $GREEN "✓ Redis backed up"
    
    print_message $GREEN "All databases backed up to: $backup_dir"
}

# Function to restore databases
restore_databases() {
    local backup_dir=$1
    
    if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
        print_message $RED "Usage: $0 restore <backup_directory>"
        exit 1
    fi
    
    print_message $BLUE "=== Restoring databases from $backup_dir ==="
    
    # Restore PostgreSQL
    if [ -f "$backup_dir/postgres.sql" ]; then
        print_message $YELLOW "Restoring PostgreSQL..."
        docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T postgres psql -U jts_admin jts_trading_dev < "$backup_dir/postgres.sql"
        print_message $GREEN "✓ PostgreSQL restored"
    fi
    
    # Restore MongoDB
    if [ -f "$backup_dir/mongodb.archive" ]; then
        print_message $YELLOW "Restoring MongoDB..."
        docker compose -f $COMPOSE_FILE -p $PROJECT_NAME exec -T mongodb mongorestore --archive < "$backup_dir/mongodb.archive"
        print_message $GREEN "✓ MongoDB restored"
    fi
    
    print_message $GREEN "Databases restored from: $backup_dir"
}

# Function to show help
show_help() {
    echo "JTS Development Services Management Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start       Start all services"
    echo "  stop        Stop all services"
    echo "  restart     Restart all services"
    echo "  status      Show service status"
    echo "  logs [svc]  Show logs (optionally for specific service)"
    echo "  test        Test database connections"
    echo "  exec <svc>  Execute command in a service"
    echo "  backup      Backup all databases"
    echo "  restore     Restore databases from backup"
    echo "  destroy     Remove all services and volumes"
    echo "  help        Show this help message"
    echo ""
    echo "Services:"
    echo "  postgres    PostgreSQL database"
    echo "  clickhouse  ClickHouse database"
    echo "  mongodb     MongoDB database"
    echo "  redis       Redis cache"
    echo "  kafka       Kafka message broker"
    echo "  zookeeper   Zookeeper (Kafka dependency)"
    echo "  grafana     Grafana monitoring"
    echo ""
    echo "Examples:"
    echo "  $0 start                      # Start all services"
    echo "  $0 logs postgres              # Show PostgreSQL logs"
    echo "  $0 exec postgres psql         # Connect to PostgreSQL"
    echo "  $0 exec redis redis-cli       # Connect to Redis"
    echo "  $0 exec mongodb mongosh       # Connect to MongoDB"
}

# Main script logic
main() {
    check_docker
    check_compose_file
    
    case "$1" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs $2
            ;;
        test)
            test_connections
            ;;
        exec)
            shift
            exec_service $@
            ;;
        backup)
            backup_databases
            ;;
        restore)
            restore_databases $2
            ;;
        destroy)
            destroy_services
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_message $RED "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main $@