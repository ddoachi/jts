#!/usr/bin/env node
// Generated from spec: E01-F02-T06 (Development Scripts and Automation)
// Spec ID: 24146db4

const { exec } = require('child_process');
const { promisify } = require('util');
const net = require('net');
const http = require('http');
const execAsync = promisify(exec);

// Color codes for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

// Service definitions with health check configurations
const services = [
  {
    name: 'PostgreSQL',
    container: 'jts-postgres-dev',
    port: 5442,
    type: 'tcp',
    essential: true,
  },
  {
    name: 'ClickHouse',
    container: 'jts-clickhouse-dev',
    port: 8123,
    type: 'http',
    path: '/ping',
    essential: true,
  },
  {
    name: 'MongoDB',
    container: 'jts-mongodb-dev',
    port: 27017,
    type: 'tcp',
    essential: true,
  },
  {
    name: 'Redis',
    container: 'jts-redis-dev',
    port: 6379,
    type: 'tcp',
    essential: true,
  },
  {
    name: 'Kafka',
    container: 'jts-kafka-dev',
    port: 9092,
    type: 'tcp',
    essential: true,
  },
  {
    name: 'Zookeeper',
    container: 'jts-zookeeper-dev',
    port: 2181,
    type: 'tcp',
    essential: false,
  },
  {
    name: 'Kafka UI',
    container: 'jts-kafka-ui-dev',
    port: 8080,
    type: 'http',
    path: '/',
    essential: false,
  },
  {
    name: 'pgAdmin',
    container: 'jts-pgadmin-dev',
    port: 5050,
    type: 'http',
    path: '/login',
    essential: false,
  },
];

// Check if Docker is available
async function checkDockerAvailable() {
  try {
    await execAsync('docker --version');
    return true;
  } catch {
    return false;
  }
}

// Check if Docker daemon is running
async function checkDockerRunning() {
  try {
    await execAsync('docker info');
    return true;
  } catch {
    return false;
  }
}

// Check if container exists and get its status
async function getContainerStatus(containerName) {
  try {
    const { stdout } = await execAsync(
      `docker ps -a --filter "name=${containerName}" --format "{{.Status}}"`,
    );

    const status = stdout.trim();
    if (!status) {
      return { exists: false, running: false };
    }

    return {
      exists: true,
      running: status.toLowerCase().includes('up'),
      status: status,
    };
  } catch {
    return { exists: false, running: false };
  }
}

// Check TCP port connectivity
async function checkTcpPort(host, port, timeout = 3000) {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    let connected = false;

    socket.setTimeout(timeout);

    socket.on('connect', () => {
      connected = true;
      socket.destroy();
      resolve(true);
    });

    socket.on('timeout', () => {
      socket.destroy();
      resolve(false);
    });

    socket.on('error', () => {
      resolve(false);
    });

    socket.connect(port, host);
  });
}

// Check HTTP endpoint
async function checkHttpEndpoint(host, port, path = '/', timeout = 3000) {
  return new Promise((resolve) => {
    const options = {
      hostname: host,
      port: port,
      path: path,
      method: 'GET',
      timeout: timeout,
    };

    const req = http.request(options, (res) => {
      resolve(res.statusCode < 500);
    });

    req.on('error', () => {
      resolve(false);
    });

    req.on('timeout', () => {
      req.destroy();
      resolve(false);
    });

    req.end();
  });
}

// Check individual service health
async function checkService(service) {
  const result = {
    name: service.name,
    essential: service.essential,
    container: service.container,
    port: service.port,
  };

  // Check container status
  const containerStatus = await getContainerStatus(service.container);

  if (!containerStatus.exists) {
    return {
      ...result,
      status: 'missing',
      message: 'Container not found',
      healthy: false,
    };
  }

  if (!containerStatus.running) {
    return {
      ...result,
      status: 'stopped',
      message: 'Container is stopped',
      healthy: false,
    };
  }

  // Check port accessibility
  let portAccessible = false;

  if (service.type === 'tcp') {
    portAccessible = await checkTcpPort('localhost', service.port);
  } else if (service.type === 'http') {
    portAccessible = await checkHttpEndpoint('localhost', service.port, service.path);
  }

  if (!portAccessible) {
    return {
      ...result,
      status: 'unhealthy',
      message: `Port ${service.port} not accessible`,
      healthy: false,
    };
  }

  return {
    ...result,
    status: 'healthy',
    message: 'Service is running',
    healthy: true,
  };
}

// Format service status for display
function formatServiceStatus(result) {
  let icon, color;

  switch (result.status) {
    case 'healthy':
      icon = '✅';
      color = colors.green;
      break;
    case 'unhealthy':
      icon = '⚠️ ';
      color = colors.yellow;
      break;
    case 'stopped':
      icon = '🛑';
      color = colors.red;
      break;
    case 'missing':
      icon = '❌';
      color = colors.red;
      break;
    default:
      icon = '❓';
      color = colors.reset;
  }

  const essentialTag = result.essential ? ' [ESSENTIAL]' : '';
  return `${icon}  ${color}${result.name}${essentialTag}: ${result.message}${colors.reset}`;
}

// Check all services
async function checkAllServices(options = {}) {
  const { verbose = false, json = false } = options;

  if (!json) {
    console.log(`${colors.cyan}🏥 Checking service health...${colors.reset}\n`);
  }

  // Check Docker availability first
  const dockerAvailable = await checkDockerAvailable();
  if (!dockerAvailable) {
    const error = 'Docker is not installed or not in PATH';
    if (json) {
      console.log(JSON.stringify({ error }, null, 2));
    } else {
      console.log(`${colors.red}❌ ${error}${colors.reset}`);
    }
    process.exit(1);
  }

  const dockerRunning = await checkDockerRunning();
  if (!dockerRunning) {
    const error = 'Docker daemon is not running';
    if (json) {
      console.log(JSON.stringify({ error }, null, 2));
    } else {
      console.log(`${colors.red}❌ ${error}${colors.reset}`);
      console.log('Please start Docker Desktop or Docker service');
    }
    process.exit(1);
  }

  // Check all services
  const results = await Promise.all(services.map(checkService));

  if (json) {
    console.log(JSON.stringify({ services: results }, null, 2));
    return;
  }

  // Display results
  const essentialServices = results.filter((r) => r.essential);
  const optionalServices = results.filter((r) => !r.essential);

  console.log(`${colors.blue}Essential Services:${colors.reset}`);
  essentialServices.forEach((result) => {
    console.log('  ' + formatServiceStatus(result));
  });

  if (optionalServices.length > 0) {
    console.log(`\n${colors.blue}Optional Services:${colors.reset}`);
    optionalServices.forEach((result) => {
      console.log('  ' + formatServiceStatus(result));
    });
  }

  // Summary
  const healthyEssential = essentialServices.filter((r) => r.healthy).length;
  const totalEssential = essentialServices.length;
  const healthyOptional = optionalServices.filter((r) => r.healthy).length;
  const totalOptional = optionalServices.length;

  console.log(`\n${colors.cyan}Summary:${colors.reset}`);
  console.log(`  Essential: ${healthyEssential}/${totalEssential} healthy`);
  if (totalOptional > 0) {
    console.log(`  Optional: ${healthyOptional}/${totalOptional} healthy`);
  }

  // Check if all essential services are healthy
  const allEssentialHealthy = essentialServices.every((r) => r.healthy);

  if (allEssentialHealthy) {
    console.log(`\n${colors.green}✅ All essential services are healthy!${colors.reset}`);
    process.exit(0);
  } else {
    console.log(`\n${colors.yellow}⚠️  Some essential services are not healthy${colors.reset}`);

    if (verbose) {
      console.log('\nTroubleshooting tips:');
      console.log('  1. Check container logs: yarn dev:logs');
      console.log('  2. Restart services: yarn dev:restart');
      console.log('  3. Clean and restart: yarn dev:clean && yarn dev:start');
    }

    process.exit(1);
  }
}

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    verbose: false,
    json: false,
    help: false,
  };

  for (const arg of args) {
    switch (arg) {
      case '-v':
      case '--verbose':
        options.verbose = true;
        break;
      case '-j':
      case '--json':
        options.json = true;
        break;
      case '-h':
      case '--help':
        options.help = true;
        break;
      default:
        console.error(`Unknown option: ${arg}`);
        options.help = true;
    }
  }

  return options;
}

// Show help message
function showHelp() {
  console.log('Usage: node check-services-health.js [OPTIONS]');
  console.log('\nOptions:');
  console.log('  -v, --verbose  Show additional troubleshooting information');
  console.log('  -j, --json     Output results in JSON format');
  console.log('  -h, --help     Show this help message');
  console.log('\nExamples:');
  console.log('  node check-services-health.js');
  console.log('  node check-services-health.js --verbose');
  console.log('  node check-services-health.js --json');
}

// Main execution
async function main() {
  const options = parseArgs();

  if (options.help) {
    showHelp();
    process.exit(0);
  }

  try {
    await checkAllServices(options);
  } catch (error) {
    if (options.json) {
      console.log(JSON.stringify({ error: error.message }, null, 2));
    } else {
      console.error(`${colors.red}Error: ${error.message}${colors.reset}`);
    }
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

// Export for use as module
module.exports = {
  checkService,
  checkAllServices,
  checkTcpPort,
  checkHttpEndpoint,
};
