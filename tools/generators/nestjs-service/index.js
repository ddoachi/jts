'use strict';
/**
 * NestJS Service Generator
 *
 * WHY: Ensures consistent service creation across the JTS monorepo
 * HOW: Uses Nx devkit to generate standardized NestJS microservice structure
 * WHAT: Creates a new NestJS service with proper structure and configuration
 *
 * FLOW:
 * 1. Normalize options (names, paths, ports)
 * 2. Generate base NestJS application
 * 3. Apply custom templates for JTS patterns
 * 4. Update project configuration
 * 5. Format files and install packages
 *
 * GOTCHAS:
 * - Port assignment uses 3000+ range to avoid conflicts
 * - Tags are critical for Nx dependency graph
 * - Directory structure follows JTS conventions
 *
 * RELATED: tools/generators/jts-library/index.ts
 *
 * @example
 * nx g @tools/generators/nestjs-service --name=trading-service --port=3010
 * // Creates: apps/trading-service with standard JTS structure
 */
var __createBinding =
  (this && this.__createBinding) ||
  (Object.create
    ? function (o, m, k, k2) {
        if (k2 === undefined) k2 = k;
        var desc = Object.getOwnPropertyDescriptor(m, k);
        if (!desc || ('get' in desc ? !m.__esModule : desc.writable || desc.configurable)) {
          desc = {
            enumerable: true,
            get: function () {
              return m[k];
            },
          };
        }
        Object.defineProperty(o, k2, desc);
      }
    : function (o, m, k, k2) {
        if (k2 === undefined) k2 = k;
        o[k2] = m[k];
      });
var __setModuleDefault =
  (this && this.__setModuleDefault) ||
  (Object.create
    ? function (o, v) {
        Object.defineProperty(o, 'default', { enumerable: true, value: v });
      }
    : function (o, v) {
        o['default'] = v;
      });
var __importStar =
  (this && this.__importStar) ||
  (function () {
    var ownKeys = function (o) {
      ownKeys =
        Object.getOwnPropertyNames ||
        function (o) {
          var ar = [];
          for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
          return ar;
        };
      return ownKeys(o);
    };
    return function (mod) {
      if (mod && mod.__esModule) return mod;
      var result = {};
      if (mod != null)
        for (var k = ownKeys(mod), i = 0; i < k.length; i++)
          if (k[i] !== 'default') __createBinding(result, mod, k[i]);
      __setModuleDefault(result, mod);
      return result;
    };
  })();
Object.defineProperty(exports, '__esModule', { value: true });
exports.default = serviceGenerator;
const devkit_1 = require('@nx/devkit');
const nest_1 = require('@nx/nest');
const eslint_1 = require('@nx/eslint');
const path = __importStar(require('path'));
// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Main Generator Function ███
// ═══════════════════════════════════════════════════════════════════
/**
 * Main generator entry point
 *
 * WHY: Orchestrates the entire service generation process
 * HOW: Calls each generation step in sequence
 * WHAT: Returns a function that installs packages after generation
 */
async function serviceGenerator(tree, options) {
  // Step 1: Normalize and validate options
  const normalizedOptions = normalizeOptions(tree, options);
  // Step 2: Generate base NestJS application
  // Using Nx's built-in NestJS generator as foundation
  await (0, nest_1.applicationGenerator)(tree, {
    name: normalizedOptions.projectName,
    directory: normalizedOptions.projectDirectory,
    tags: normalizedOptions.parsedTags.join(','),
    unitTestRunner: 'jest',
    linter: eslint_1.Linter.EsLint,
    skipFormat: true, // We'll format at the end
  });
  // Step 3: Apply JTS-specific templates
  // These templates enforce our architecture patterns
  addCustomFiles(tree, normalizedOptions);
  // Step 4: Update project configuration
  // Adds JTS-specific build targets and options
  updateProjectConfig(tree, normalizedOptions);
  // Step 5: Update root package.json with service-specific scripts
  updateRootPackageJson(tree, normalizedOptions);
  // Step 6: Format all generated files
  await (0, devkit_1.formatFiles)(tree);
  // Return installer task to be executed after file generation
  return () => {
    (0, devkit_1.installPackagesTask)(tree);
  };
}
// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Option Normalization ███
// ═══════════════════════════════════════════════════════════════════
/**
 * Normalize generator options
 *
 * WHY: Ensures consistent naming and paths across the monorepo
 * HOW: Applies naming conventions and calculates paths
 * WHAT: Returns normalized options with all required fields
 *
 * GOTCHA: Port range starts at 3000, increments by service count
 */
function normalizeOptions(tree, options) {
  // Convert name to kebab-case for consistency
  const name = (0, devkit_1.names)(options.name).fileName;
  // Calculate project directory
  // If directory provided: apps/{directory}/{name}
  // Otherwise: apps/{name}
  const projectDirectory = options.directory
    ? `${(0, devkit_1.names)(options.directory).fileName}/${name}`
    : name;
  // Project name uses dashes instead of slashes
  const projectName = projectDirectory.replace(new RegExp('/', 'g'), '-');
  // Project root is always under apps/
  const projectRoot = `apps/${projectDirectory}`;
  // Parse tags for Nx dependency constraints
  const parsedTags = options.tags
    ? options.tags.split(',').map((s) => s.trim())
    : ['scope:apps', 'type:service'];
  // Auto-assign port if not provided
  // Uses 3000-3999 range for services
  const port = options.port || assignNextAvailablePort(tree);
  return {
    ...options,
    projectName,
    projectRoot,
    projectDirectory,
    parsedTags,
    port,
    className: (0, devkit_1.names)(options.name).className,
  };
}
/**
 * Assign next available port
 *
 * WHY: Prevents port conflicts between services
 * HOW: Scans existing services and finds next available port
 * WHAT: Returns port number in 3000-3999 range
 */
function assignNextAvailablePort(tree) {
  const basePort = 3000;
  const maxPort = 3999;
  let port = basePort;
  // Read all project.json files to find used ports
  const appsDir = tree.children('apps');
  const usedPorts = new Set();
  for (const app of appsDir) {
    const projectJsonPath = `apps/${app}/project.json`;
    if (tree.exists(projectJsonPath)) {
      const projectJson = JSON.parse(tree.read(projectJsonPath).toString());
      const serveOptions = projectJson.targets?.serve?.options;
      if (serveOptions?.port) {
        usedPorts.add(serveOptions.port);
      }
    }
  }
  // Find first available port
  while (usedPorts.has(port) && port <= maxPort) {
    port++;
  }
  if (port > maxPort) {
    throw new Error('No available ports in range 3000-3999');
  }
  return port;
}
// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Template Application ███
// ═══════════════════════════════════════════════════════════════════
/**
 * Add custom JTS template files
 *
 * WHY: Enforces JTS architecture patterns (domain, infra, shared)
 * HOW: Generates files from templates with variable substitution
 * WHAT: Creates standardized service structure
 */
function addCustomFiles(tree, options) {
  const templateOptions = {
    ...options,
    ...(0, devkit_1.names)(options.name),
    offsetFromRoot: (0, devkit_1.offsetFromRoot)(options.projectRoot),
    template: '', // Used by template engine for substitutions
  };
  // Generate files from templates
  (0, devkit_1.generateFiles)(
    tree,
    path.join(__dirname, 'files'),
    options.projectRoot,
    templateOptions,
  );
  // Add additional configurations based on options
  if (options.includeKafka) {
    generateKafkaConfig(tree, options);
  }
  if (options.includeGrpc) {
    generateGrpcConfig(tree, options);
  }
  if (options.includeWebsocket) {
    generateWebsocketConfig(tree, options);
  }
}
/**
 * Generate Kafka configuration
 *
 * WHY: Services often need async messaging
 * HOW: Adds Kafka module and configuration
 * WHAT: Creates Kafka producer/consumer setup
 */
function generateKafkaConfig(tree, options) {
  const kafkaModulePath = `${options.projectRoot}/src/infra/kafka/kafka.module.ts`;
  const kafkaModuleContent = `import { Module } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';

/**
 * Kafka Module
 *
 * WHY: Enables async messaging between services
 * HOW: Configures Kafka client with JTS conventions
 * WHAT: Provides Kafka producer/consumer capabilities
 */
@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'KAFKA_SERVICE',
        transport: Transport.KAFKA,
        options: {
          client: {
            clientId: '${options.projectName}',
            brokers: [process.env.KAFKA_BROKER || 'localhost:9092'],
          },
          consumer: {
            groupId: '${options.projectName}-group',
          },
        },
      },
    ]),
  ],
  exports: [ClientsModule],
})
export class KafkaModule {}
`;
  tree.write(kafkaModulePath, kafkaModuleContent);
}
/**
 * Generate gRPC configuration
 *
 * WHY: Services need efficient inter-service communication
 * HOW: Adds gRPC module with protobuf support
 * WHAT: Creates gRPC server/client setup
 */
function generateGrpcConfig(tree, options) {
  const grpcModulePath = `${options.projectRoot}/src/infra/grpc/grpc.module.ts`;
  const grpcModuleContent = `import { Module } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { join } from 'path';

/**
 * gRPC Module
 *
 * WHY: Enables high-performance RPC between services
 * HOW: Configures gRPC with protobuf definitions
 * WHAT: Provides type-safe service communication
 */
@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'GRPC_SERVICE',
        transport: Transport.GRPC,
        options: {
          package: '${options.name.toLowerCase()}',
          protoPath: join(__dirname, '../../proto/${options.name.toLowerCase()}.proto'),
          url: process.env.GRPC_URL || 'localhost:5000',
        },
      },
    ]),
  ],
  exports: [ClientsModule],
})
export class GrpcModule {}
`;
  tree.write(grpcModulePath, grpcModuleContent);
}
/**
 * Generate WebSocket configuration
 *
 * WHY: Real-time communication for market data and updates
 * HOW: Adds WebSocket gateway with Socket.io
 * WHAT: Creates WebSocket server setup
 */
function generateWebsocketConfig(tree, options) {
  const wsGatewayPath = `${options.projectRoot}/src/infra/websocket/websocket.gateway.ts`;
  const wsGatewayContent = `import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

/**
 * WebSocket Gateway
 *
 * WHY: Enables real-time bidirectional communication
 * HOW: Uses Socket.io for WebSocket management
 * WHAT: Provides event-driven real-time updates
 */
@WebSocketGateway({
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
  },
  namespace: '/${options.name.toLowerCase()}',
})
export class ${options.className}Gateway {
  @WebSocketServer()
  server: Server;

  /**
   * Handle connection event
   */
  handleConnection(client: Socket): void {
    console.log(\`Client connected: \${client.id}\`);
  }

  /**
   * Handle disconnection event
   */
  handleDisconnect(client: Socket): void {
    console.log(\`Client disconnected: \${client.id}\`);
  }

  /**
   * Example message handler
   */
  @SubscribeMessage('message')
  handleMessage(
    @MessageBody() data: any,
    @ConnectedSocket() client: Socket,
  ): void {
    // Broadcast to all clients
    this.server.emit('broadcast', data);
  }
}
`;
  tree.write(wsGatewayPath, wsGatewayContent);
}
// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Configuration Updates ███
// ═══════════════════════════════════════════════════════════════════
/**
 * Update project configuration
 *
 * WHY: Adds JTS-specific build and serve configurations
 * HOW: Modifies project.json with additional targets
 * WHAT: Configures port, Docker, and deployment settings
 */
function updateProjectConfig(tree, options) {
  const projectConfig = (0, devkit_1.readProjectConfiguration)(tree, options.projectName);
  // Update serve target with port
  if (projectConfig.targets?.serve) {
    projectConfig.targets.serve.options = {
      ...projectConfig.targets.serve.options,
      port: options.port,
    };
  }
  // Add Docker build target
  projectConfig.targets['docker-build'] = {
    executor: '@nx-tools/nx-docker:build',
    options: {
      context: options.projectRoot,
      dockerfile: `${options.projectRoot}/Dockerfile`,
      tags: [`jts/${options.projectName}:latest`],
    },
  };
  // Add health check target
  projectConfig.targets['health'] = {
    executor: 'nx:run-commands',
    options: {
      command: `curl -f http://localhost:${options.port}/health || exit 1`,
    },
  };
  // Update project configuration
  (0, devkit_1.updateProjectConfiguration)(tree, options.projectName, projectConfig);
}
/**
 * Update root package.json
 *
 * WHY: Adds convenience scripts for the new service
 * HOW: Modifies package.json scripts section
 * WHAT: Creates service-specific dev, test, and build scripts
 */
function updateRootPackageJson(tree, options) {
  (0, devkit_1.updateJson)(tree, 'package.json', (json) => {
    json.scripts = json.scripts || {};
    // Add service-specific scripts
    const scriptPrefix = options.projectName;
    json.scripts[`dev:${scriptPrefix}`] = `nx serve ${options.projectName}`;
    json.scripts[`test:${scriptPrefix}`] = `nx test ${options.projectName}`;
    json.scripts[`build:${scriptPrefix}`] = `nx build ${options.projectName}`;
    json.scripts[`docker:${scriptPrefix}`] = `nx docker-build ${options.projectName}`;
    return json;
  });
}
