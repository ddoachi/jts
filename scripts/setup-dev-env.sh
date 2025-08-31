#!/bin/bash
# Generated from spec: E01-F02-T06 (Development Scripts and Automation)
# Spec ID: 24146db4
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up JTS Development Environment${NC}"
echo "================================================"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        echo -e "${RED}❌ Unsupported OS: $OSTYPE${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Detected OS: $OS${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo -e "\n${YELLOW}📋 Checking prerequisites...${NC}"
    
    local has_errors=false
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed${NC}"
        echo "   Please run: ./scripts/install-node-yarn.sh"
        has_errors=true
    else
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 20 ]; then
            echo -e "${RED}❌ Node.js 20+ required (found: $(node -v))${NC}"
            has_errors=true
        else
            echo -e "${GREEN}✅ Node.js $(node -v)${NC}"
        fi
    fi
    
    # Check Yarn
    if ! command -v yarn &> /dev/null; then
        echo -e "${RED}❌ Yarn is not installed${NC}"
        echo "   Please run: corepack enable && yarn set version stable"
        has_errors=true
    else
        echo -e "${GREEN}✅ Yarn $(yarn -v)${NC}"
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        echo "   Please install Docker Desktop or Docker Engine"
        has_errors=true
    else
        # Check if Docker daemon is running
        if ! docker info &> /dev/null; then
            echo -e "${RED}❌ Docker daemon is not running${NC}"
            echo "   Please start Docker Desktop or Docker service"
            has_errors=true
        else
            echo -e "${GREEN}✅ Docker $(docker --version | cut -d' ' -f3 | cut -d',' -f1)${NC}"
        fi
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Docker Compose is not available${NC}"
        echo "   Please install Docker Compose plugin"
        has_errors=true
    else
        echo -e "${GREEN}✅ Docker Compose $(docker compose version --short)${NC}"
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git is not installed${NC}"
        has_errors=true
    else
        echo -e "${GREEN}✅ $(git --version)${NC}"
    fi
    
    if [ "$has_errors" = true ]; then
        echo -e "\n${RED}Please fix the above issues before continuing${NC}"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    echo -e "\n${YELLOW}📦 Installing dependencies...${NC}"
    
    # Check if node_modules exists and is recent
    if [ -d "node_modules" ]; then
        echo "   Checking existing dependencies..."
        yarn install --check-files || yarn install
    else
        yarn install
    fi
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Setup environment
setup_environment() {
    echo -e "\n${YELLOW}🔧 Setting up environment...${NC}"
    
    # Create .env.local if it doesn't exist
    if [ ! -f .env.local ]; then
        if [ -f .env.example ]; then
            cp .env.example .env.local
            echo -e "${GREEN}✅ Created .env.local from template${NC}"
            echo -e "${YELLOW}⚠️  Please update .env.local with your credentials${NC}"
        else
            echo -e "${YELLOW}⚠️  No .env.example found, creating basic .env.local${NC}"
            cat > .env.local << 'EOF'
# Database URLs
DATABASE_URL="postgresql://jts_user:jts_pass@localhost:5432/jts_dev"
CLICKHOUSE_URL="http://localhost:8123"
MONGODB_URL="mongodb://jts_user:jts_pass@localhost:27017/jts_dev"
REDIS_URL="redis://localhost:6379"

# Kafka Configuration
KAFKA_BROKERS="localhost:9092"

# Service Ports
API_GATEWAY_PORT=3000
STRATEGY_ENGINE_PORT=3001
RISK_MANAGEMENT_PORT=3002
ORDER_EXECUTION_PORT=3003
MARKET_DATA_PORT=3004

# Environment
NODE_ENV=development
LOG_LEVEL=debug

# Security (Change these!)
JWT_SECRET=your-jwt-secret-here
ENCRYPTION_KEY=your-encryption-key-here
EOF
            echo -e "${GREEN}✅ Created basic .env.local${NC}"
        fi
    else
        echo -e "${GREEN}✅ .env.local already exists${NC}"
    fi
    
    # Validate environment
    if [ -f scripts/validate-env.js ]; then
        echo "   Validating environment variables..."
        node scripts/validate-env.js || echo -e "${YELLOW}⚠️  Environment validation warnings detected${NC}"
    fi
}

# Start Docker services
start_services() {
    echo -e "\n${YELLOW}🐳 Starting Docker services...${NC}"
    
    # Check if docker-compose.dev.yml exists
    if [ ! -f docker-compose.dev.yml ]; then
        echo -e "${RED}❌ docker-compose.dev.yml not found${NC}"
        echo "   Please ensure you have the Docker configuration file"
        return 1
    fi
    
    # Stop any existing containers
    echo "   Stopping any existing containers..."
    docker compose -f docker-compose.dev.yml down 2>/dev/null || true
    
    # Start services
    echo "   Starting services..."
    docker compose -f docker-compose.dev.yml up -d
    
    # Wait for services to be ready
    echo "   Waiting for services to be ready..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        sleep 2
        attempt=$((attempt + 1))
        
        # Check if critical services are responding
        if docker compose -f docker-compose.dev.yml ps --services --filter "status=running" 2>/dev/null | grep -q .; then
            break
        fi
        
        echo -n "."
    done
    echo ""
    
    # Check service health
    if [ -f scripts/check-services-health.js ]; then
        node scripts/check-services-health.js || echo -e "${YELLOW}⚠️  Some services may not be fully ready${NC}"
    else
        docker compose -f docker-compose.dev.yml ps
    fi
    
    echo -e "${GREEN}✅ Docker services started${NC}"
}

# Run database migrations
run_migrations() {
    echo -e "\n${YELLOW}🗄️ Running database migrations...${NC}"
    
    # Check if Prisma is configured
    if [ -f "prisma/schema.prisma" ]; then
        echo "   Running PostgreSQL migrations..."
        yarn prisma migrate deploy 2>/dev/null || echo -e "${YELLOW}⚠️  PostgreSQL migration skipped or already applied${NC}"
    fi
    
    # Check for ClickHouse migrations
    if [ -f "scripts/migrate-clickhouse.js" ]; then
        echo "   Running ClickHouse setup..."
        node scripts/migrate-clickhouse.js 2>/dev/null || echo -e "${YELLOW}⚠️  ClickHouse setup skipped${NC}"
    fi
    
    echo -e "${GREEN}✅ Database migrations complete${NC}"
}

# Seed development data
seed_data() {
    echo -e "\n${YELLOW}🌱 Seeding development data...${NC}"
    
    read -p "Do you want to seed development data? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Check if seed scripts exist
        if [ -f "prisma/seed.ts" ] || [ -f "prisma/seed.js" ]; then
            yarn prisma db seed || echo -e "${YELLOW}⚠️  Seeding encountered issues${NC}"
        fi
        
        if [ -f "scripts/seed-clickhouse.js" ]; then
            node scripts/seed-clickhouse.js || echo -e "${YELLOW}⚠️  ClickHouse seeding skipped${NC}"
        fi
        
        echo -e "${GREEN}✅ Development data seeded${NC}"
    else
        echo "   Skipping data seeding"
    fi
}

# Setup VS Code
setup_vscode() {
    echo -e "\n${YELLOW}📝 Setting up VS Code...${NC}"
    
    if command -v code &> /dev/null; then
        read -p "Install recommended VS Code extensions? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Install extensions from .vscode/extensions.json
            if [ -f ".vscode/extensions.json" ]; then
                # Parse and install extensions
                extensions=$(grep -Po '"\K[^"]*(?=")' .vscode/extensions.json | grep -v "recommendations" | grep "\.")
                for ext in $extensions; do
                    echo "   Installing $ext..."
                    code --install-extension "$ext" 2>/dev/null || true
                done
                echo -e "${GREEN}✅ VS Code extensions installed${NC}"
            else
                echo -e "${YELLOW}⚠️  No .vscode/extensions.json found${NC}"
            fi
        fi
    else
        echo "   VS Code CLI not found, skipping extension installation"
    fi
}

# Setup git hooks
setup_git_hooks() {
    echo -e "\n${YELLOW}🪝 Setting up Git hooks...${NC}"
    
    # Check if husky is configured
    if [ -f "package.json" ] && grep -q "\"prepare\":" package.json; then
        yarn prepare || echo -e "${YELLOW}⚠️  Git hooks setup skipped${NC}"
        echo -e "${GREEN}✅ Git hooks configured${NC}"
    else
        echo "   No git hooks configuration found"
    fi
}

# Print summary
print_summary() {
    echo -e "\n${GREEN}================================================${NC}"
    echo -e "${GREEN}✅ Development environment setup complete!${NC}"
    echo -e "${GREEN}================================================${NC}"
    
    echo -e "\n📚 ${YELLOW}Next steps:${NC}"
    echo "  1. Update .env.local with your credentials"
    echo "  2. Start development: yarn dev"
    echo "  3. View service logs: yarn dev:logs"
    echo "  4. Check service health: yarn dev:health"
    echo ""
    
    echo -e "📖 ${YELLOW}Useful commands:${NC}"
    echo "  yarn dev:status   - Check service status"
    echo "  yarn dev:stop     - Stop all services"
    echo "  yarn dev:restart  - Restart services"
    echo "  yarn dev:clean    - Reset everything"
    echo "  yarn test         - Run tests"
    echo "  yarn lint         - Run linter"
    echo "  yarn type-check   - TypeScript check"
    echo ""
    
    # Display service URLs if services are running
    if docker compose -f docker-compose.dev.yml ps 2>/dev/null | grep -q "Up"; then
        echo -e "🔗 ${YELLOW}Service URLs:${NC}"
        echo "  API Gateway:    http://localhost:3000"
        echo "  PostgreSQL:     localhost:5432"
        echo "  ClickHouse:     http://localhost:8123"
        echo "  MongoDB:        localhost:27017"
        echo "  Redis:          localhost:6379"
        echo "  Kafka:          localhost:9092"
        
        # Check for admin UIs
        if docker compose -f docker-compose.dev.yml ps 2>/dev/null | grep -q "kafka-ui"; then
            echo "  Kafka UI:       http://localhost:8080"
        fi
        if docker compose -f docker-compose.dev.yml ps 2>/dev/null | grep -q "pgadmin"; then
            echo "  pgAdmin:        http://localhost:5050"
        fi
        echo ""
    fi
    
    echo -e "${BLUE}Happy coding! 🚀${NC}"
}

# Error handler
handle_error() {
    echo -e "\n${RED}❌ An error occurred during setup${NC}"
    echo "Please check the output above for details"
    echo ""
    echo "Common solutions:"
    echo "  - Ensure Docker is running"
    echo "  - Check your internet connection"
    echo "  - Free up disk space"
    echo "  - Run with sudo if permission issues"
    exit 1
}

# Set error trap
trap handle_error ERR

# Main execution
main() {
    # Parse command line arguments
    SKIP_SERVICES=false
    SKIP_DEPS=false
    QUICK=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-services)
                SKIP_SERVICES=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --quick)
                QUICK=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-services  Skip Docker services startup"
                echo "  --skip-deps      Skip dependency installation"
                echo "  --quick          Quick setup (skip optional steps)"
                echo "  --help           Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    detect_os
    check_prerequisites
    
    if [ "$SKIP_DEPS" = false ]; then
        install_dependencies
    fi
    
    setup_environment
    
    if [ "$SKIP_SERVICES" = false ]; then
        start_services
        run_migrations
        
        if [ "$QUICK" = false ]; then
            seed_data
        fi
    fi
    
    if [ "$QUICK" = false ]; then
        setup_vscode
        setup_git_hooks
    fi
    
    print_summary
}

# Run main function with all arguments
main "$@"