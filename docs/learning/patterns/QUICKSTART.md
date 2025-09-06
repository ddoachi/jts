# JTS Quick Start Guide

> Generated from spec: E01-F02-T06 (Development Scripts and Automation)  
> Spec ID: 24146db4

**Get the JTS trading system running in 5 minutes!**

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Node.js 20+ installed
- [ ] Docker Desktop running
- [ ] Git installed
- [ ] 8GB+ free RAM
- [ ] 10GB+ free disk space

## 🚀 5-Minute Setup

### Step 1: Clone and Enter

```bash
git clone https://github.com/ddoachi/jts-monorepo.git
cd jts-monorepo
```

### Step 2: Run Automated Setup

```bash
yarn setup
```

This single command will:

- ✅ Check all prerequisites
- ✅ Install dependencies
- ✅ Set up environment
- ✅ Start Docker services
- ✅ Initialize databases
- ✅ Configure Git hooks

### Step 3: Start Development

```bash
yarn dev
```

Your services are now running at:

- 🌐 **API Gateway**: http://localhost:3000
- 📊 **Kafka UI**: http://localhost:8080
- 🗄️ **pgAdmin**: http://localhost:5050

## 🎯 Common Tasks

### Check Service Health

```bash
yarn dev:health
```

Expected output:

```
✅ PostgreSQL: Service is running
✅ ClickHouse: Service is running
✅ MongoDB: Service is running
✅ Redis: Service is running
✅ Kafka: Service is running
```

### View Logs

```bash
# All services
yarn dev:logs

# Specific service
docker logs jts-api-gateway-dev -f
```

### Stop Everything

```bash
yarn dev:stop
```

### Reset Everything

```bash
yarn dev:clean
yarn setup
```

## 🔧 Quick Configuration

### Update Credentials

Edit `.env.local`:

```bash
# Minimal required configuration
DATABASE_URL=postgresql://jts_user:jts_pass@localhost:5432/jts_dev
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secure-secret-here

# Optional: Trading API credentials
KIS_ACCOUNT_1_ENABLED=true
KIS_ACCOUNT_1_APPKEY=your_appkey
KIS_ACCOUNT_1_APPSECRET=your_secret
```

### Validate Configuration

```bash
yarn env:validate
```

## 📝 Essential Commands

| Task       | Command           | Description                |
| ---------- | ----------------- | -------------------------- |
| **Setup**  | `yarn setup`      | Complete environment setup |
| **Start**  | `yarn dev`        | Start all services         |
| **Stop**   | `yarn dev:stop`   | Stop all services          |
| **Logs**   | `yarn dev:logs`   | View service logs          |
| **Health** | `yarn dev:health` | Check service status       |
| **Test**   | `yarn test`       | Run all tests              |
| **Clean**  | `yarn dev:clean`  | Reset everything           |

## 🏗️ Project Structure

```
jts-monorepo/
├── apps/           # Microservices
│   ├── api-gateway/
│   ├── strategy-engine/
│   └── ...
├── libs/           # Shared code
├── scripts/        # Automation
└── docs/           # Documentation
```

## 🧪 Quick Test

### 1. Health Check Endpoint

```bash
curl http://localhost:3000/health
```

Expected response:

```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### 2. Run Tests

```bash
# Unit tests
yarn test

# Specific service
nx test api-gateway
```

## 🐛 Troubleshooting

### Docker Not Running

**Error**: "Docker daemon is not running"

**Solution**:

```bash
# Start Docker Desktop or
sudo systemctl start docker  # Linux
```

### Port Already in Use

**Error**: "Port 3000 is already in use"

**Solution**:

```bash
# Find and kill process
lsof -i :3000
kill -9 <PID>

# Or use different port
API_GATEWAY_PORT=3001 yarn dev
```

### Dependencies Installation Failed

**Error**: "yarn install failed"

**Solution**:

```bash
# Clear cache and retry
yarn cache clean
rm -rf node_modules
yarn install
```

### Service Won't Start

**Error**: "Service jts-postgres-dev is unhealthy"

**Solution**:

```bash
# Restart services
yarn dev:restart

# Or complete reset
yarn dev:clean
yarn dev:start
```

## 🚦 Next Steps

1. **Read Full Documentation**
   - [Development Guide](./DEVELOPMENT.md)
   - [Architecture Overview](./ARCHITECTURE.md)

2. **Explore the API**
   - Open http://localhost:3000/api
   - View Swagger documentation

3. **Join Development**
   - Create feature branch
   - Make changes
   - Run tests
   - Submit PR

## 💡 Pro Tips

### Quick Restart

```bash
# Restart everything quickly
yarn dev:restart && yarn dev
```

### Watch Mode Development

```bash
# Auto-reload on changes
nx serve api-gateway --watch
```

### Clean Slate

```bash
# Nuclear option - reset everything
yarn clean:all && yarn setup
```

## 📞 Getting Help

1. **Check Logs First**

   ```bash
   yarn dev:logs | grep ERROR
   ```

2. **Validate Environment**

   ```bash
   yarn env:validate
   ```

3. **Health Check**

   ```bash
   yarn dev:health --verbose
   ```

4. **Still Stuck?**
   - Check [DEVELOPMENT.md](./DEVELOPMENT.md#troubleshooting)
   - Search [GitHub Issues](https://github.com/ddoachi/jts-monorepo/issues)
   - Create new issue with error details

---

**Ready to trade! 🚀📈**

_Estimated setup time: 5 minutes_  
_First-time setup with downloads: 10-15 minutes_
