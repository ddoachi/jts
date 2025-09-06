// Generated from spec: E01-F02-T03 (Docker and Database Services Setup)
// Spec ID: ce5140df
// MongoDB initialization script for JTS configuration storage

// Switch to the jts_config_dev database
db = db.getSiblingDB('jts_config_dev');

// Create collections with schema validation
db.createCollection('strategies', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'type', 'isActive', 'createdAt'],
      properties: {
        name: {
          bsonType: 'string',
          description: 'Strategy name - required',
        },
        type: {
          bsonType: 'string',
          enum: ['momentum', 'mean_reversion', 'arbitrage', 'market_making', 'custom'],
          description: 'Strategy type - required',
        },
        description: {
          bsonType: 'string',
          description: 'Strategy description',
        },
        isActive: {
          bsonType: 'bool',
          description: 'Whether strategy is active - required',
        },
        parameters: {
          bsonType: 'object',
          description: 'Strategy parameters',
        },
        symbols: {
          bsonType: 'array',
          items: {
            bsonType: 'string',
          },
          description: 'List of symbols this strategy trades',
        },
        accounts: {
          bsonType: 'array',
          items: {
            bsonType: 'string',
          },
          description: 'List of account IDs this strategy uses',
        },
        riskLimits: {
          bsonType: 'object',
          properties: {
            maxPositionSize: { bsonType: 'number' },
            maxDailyLoss: { bsonType: 'number' },
            maxOpenPositions: { bsonType: 'int' },
          },
        },
        createdAt: {
          bsonType: 'date',
          description: 'Creation timestamp - required',
        },
        updatedAt: {
          bsonType: 'date',
          description: 'Last update timestamp',
        },
      },
    },
  },
});

db.createCollection('brokerConfig', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['broker', 'accountId', 'credentials', 'createdAt'],
      properties: {
        broker: {
          bsonType: 'string',
          enum: ['KIS', 'EBEST', 'NH', 'KIWOOM'],
          description: 'Broker name - required',
        },
        accountId: {
          bsonType: 'string',
          description: 'Account identifier - required',
        },
        credentials: {
          bsonType: 'object',
          required: ['appKey', 'appSecret'],
          properties: {
            appKey: { bsonType: 'string' },
            appSecret: { bsonType: 'string' },
            accountNumber: { bsonType: 'string' },
            accountType: { bsonType: 'string' },
          },
          description: 'Encrypted credentials - required',
        },
        settings: {
          bsonType: 'object',
          properties: {
            apiUrl: { bsonType: 'string' },
            wsUrl: { bsonType: 'string' },
            sandbox: { bsonType: 'bool' },
            rateLimits: {
              bsonType: 'object',
              properties: {
                ordersPerSecond: { bsonType: 'int' },
                requestsPerMinute: { bsonType: 'int' },
              },
            },
          },
        },
        isActive: {
          bsonType: 'bool',
          description: 'Whether account is active',
        },
        createdAt: {
          bsonType: 'date',
          description: 'Creation timestamp - required',
        },
        updatedAt: {
          bsonType: 'date',
          description: 'Last update timestamp',
        },
      },
    },
  },
});

db.createCollection('symbols', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['symbol', 'exchange', 'type', 'createdAt'],
      properties: {
        symbol: {
          bsonType: 'string',
          description: 'Symbol/ticker - required',
        },
        name: {
          bsonType: 'string',
          description: 'Full name of the instrument',
        },
        exchange: {
          bsonType: 'string',
          enum: ['KOSPI', 'KOSDAQ', 'KONEX', 'KRX'],
          description: 'Exchange - required',
        },
        type: {
          bsonType: 'string',
          enum: ['stock', 'etf', 'futures', 'options', 'bond'],
          description: 'Instrument type - required',
        },
        sector: {
          bsonType: 'string',
          description: 'Market sector',
        },
        tradingHours: {
          bsonType: 'object',
          properties: {
            open: { bsonType: 'string' },
            close: { bsonType: 'string' },
            timezone: { bsonType: 'string' },
          },
        },
        tickSize: {
          bsonType: 'number',
          description: 'Minimum price movement',
        },
        lotSize: {
          bsonType: 'int',
          description: 'Minimum order quantity',
        },
        marginRequirement: {
          bsonType: 'number',
          description: 'Margin requirement percentage',
        },
        isActive: {
          bsonType: 'bool',
          description: 'Whether symbol is actively traded',
        },
        metadata: {
          bsonType: 'object',
          description: 'Additional symbol-specific data',
        },
        createdAt: {
          bsonType: 'date',
          description: 'Creation timestamp - required',
        },
        updatedAt: {
          bsonType: 'date',
          description: 'Last update timestamp',
        },
      },
    },
  },
});

db.createCollection('alerts', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['type', 'level', 'message', 'createdAt'],
      properties: {
        type: {
          bsonType: 'string',
          enum: ['price', 'volume', 'risk', 'system', 'strategy', 'account'],
          description: 'Alert type - required',
        },
        level: {
          bsonType: 'string',
          enum: ['info', 'warning', 'error', 'critical'],
          description: 'Alert level - required',
        },
        message: {
          bsonType: 'string',
          description: 'Alert message - required',
        },
        details: {
          bsonType: 'object',
          description: 'Additional alert details',
        },
        acknowledged: {
          bsonType: 'bool',
          description: 'Whether alert has been acknowledged',
        },
        acknowledgedBy: {
          bsonType: 'string',
          description: 'User who acknowledged the alert',
        },
        acknowledgedAt: {
          bsonType: 'date',
          description: 'When alert was acknowledged',
        },
        createdAt: {
          bsonType: 'date',
          description: 'Creation timestamp - required',
        },
      },
    },
  },
});

db.createCollection('systemConfig', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['key', 'value', 'createdAt'],
      properties: {
        key: {
          bsonType: 'string',
          description: 'Configuration key - required',
        },
        value: {
          bsonType: ['string', 'int', 'double', 'bool', 'object', 'array'],
          description: 'Configuration value - required',
        },
        description: {
          bsonType: 'string',
          description: 'Configuration description',
        },
        category: {
          bsonType: 'string',
          description: 'Configuration category',
        },
        isEncrypted: {
          bsonType: 'bool',
          description: 'Whether value is encrypted',
        },
        createdAt: {
          bsonType: 'date',
          description: 'Creation timestamp - required',
        },
        updatedAt: {
          bsonType: 'date',
          description: 'Last update timestamp',
        },
      },
    },
  },
});

// Create indexes
db.strategies.createIndex({ name: 1 }, { unique: true });
db.strategies.createIndex({ type: 1 });
db.strategies.createIndex({ isActive: 1 });
db.strategies.createIndex({ createdAt: -1 });

db.brokerConfig.createIndex({ broker: 1, accountId: 1 }, { unique: true });
db.brokerConfig.createIndex({ isActive: 1 });
db.brokerConfig.createIndex({ createdAt: -1 });

db.symbols.createIndex({ symbol: 1, exchange: 1 }, { unique: true });
db.symbols.createIndex({ exchange: 1 });
db.symbols.createIndex({ type: 1 });
db.symbols.createIndex({ isActive: 1 });
db.symbols.createIndex({ sector: 1 });

db.alerts.createIndex({ type: 1 });
db.alerts.createIndex({ level: 1 });
db.alerts.createIndex({ acknowledged: 1 });
db.alerts.createIndex({ createdAt: -1 });

db.systemConfig.createIndex({ key: 1 }, { unique: true });
db.systemConfig.createIndex({ category: 1 });

// Insert default system configuration
db.systemConfig.insertMany([
  {
    key: 'trading.enabled',
    value: false,
    description: 'Global trading enable/disable flag',
    category: 'trading',
    isEncrypted: false,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    key: 'trading.maxDailyLoss',
    value: 1000000,
    description: 'Maximum daily loss limit in KRW',
    category: 'risk',
    isEncrypted: false,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    key: 'trading.maxOpenPositions',
    value: 10,
    description: 'Maximum number of open positions',
    category: 'risk',
    isEncrypted: false,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    key: 'monitoring.alertEmail',
    value: 'admin@jts.local',
    description: 'Email for critical alerts',
    category: 'monitoring',
    isEncrypted: false,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    key: 'system.maintenanceMode',
    value: false,
    description: 'System maintenance mode flag',
    category: 'system',
    isEncrypted: false,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
]);

// Insert sample broker configuration (with dummy encrypted credentials)
db.brokerConfig.insertOne({
  broker: 'KIS',
  accountId: 'KIS_ACCOUNT_1',
  credentials: {
    appKey: 'ENCRYPTED_APP_KEY_1',
    appSecret: 'ENCRYPTED_APP_SECRET_1',
    accountNumber: 'ENCRYPTED_ACCOUNT_NUMBER_1',
    accountType: 'trading',
  },
  settings: {
    apiUrl: 'https://openapi.koreainvestment.com:9443',
    wsUrl: 'ws://ops.koreainvestment.com:21000',
    sandbox: true,
    rateLimits: {
      ordersPerSecond: 5,
      requestsPerMinute: 180,
    },
  },
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date(),
});

// Insert sample strategy
db.strategies.insertOne({
  name: 'Sample Momentum Strategy',
  type: 'momentum',
  description: 'A sample momentum trading strategy for testing',
  isActive: false,
  parameters: {
    lookbackPeriod: 20,
    momentumThreshold: 0.05,
    stopLoss: 0.02,
    takeProfit: 0.05,
  },
  symbols: ['005930', '000660'], // Samsung Electronics, SK Hynix
  accounts: ['KIS_ACCOUNT_1'],
  riskLimits: {
    maxPositionSize: 1000000,
    maxDailyLoss: 50000,
    maxOpenPositions: 5,
  },
  createdAt: new Date(),
  updatedAt: new Date(),
});

// Print confirmation
print('MongoDB initialization completed successfully');
print('Created collections: strategies, brokerConfig, symbols, alerts, systemConfig');
print('Inserted default configurations and sample data');
