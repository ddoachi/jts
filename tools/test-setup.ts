import 'reflect-metadata';

global.beforeEach(() => {
  jest.clearAllMocks();
});

jest.mock('@jts/infrastructure/logging', () => ({
  Logger: jest.fn().mockImplementation(() => ({
    log: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  })),
}));

export const createMockService = <T>(service: new (...args: any[]) => T): jest.Mocked<T> => {
  const mockService = {} as jest.Mocked<T>;
  Object.getOwnPropertyNames(service.prototype).forEach((name) => {
    if (name !== 'constructor') {
      mockService[name] = jest.fn();
    }
  });
  return mockService;
};

export const createMockRepository = <T>() => ({
  find: jest.fn(),
  findOne: jest.fn(),
  findOneBy: jest.fn(),
  save: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
  remove: jest.fn(),
  count: jest.fn(),
  createQueryBuilder: jest.fn(() => ({
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    orWhere: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(),
    addSelect: jest.fn().mockReturnThis(),
    leftJoin: jest.fn().mockReturnThis(),
    leftJoinAndSelect: jest.fn().mockReturnThis(),
    innerJoin: jest.fn().mockReturnThis(),
    innerJoinAndSelect: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    addOrderBy: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    take: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    offset: jest.fn().mockReturnThis(),
    getOne: jest.fn(),
    getMany: jest.fn(),
    getManyAndCount: jest.fn(),
    getCount: jest.fn(),
    getRawOne: jest.fn(),
    getRawMany: jest.fn(),
    execute: jest.fn(),
  })),
});

export const createMockRedis = () => ({
  get: jest.fn(),
  set: jest.fn(),
  setex: jest.fn(),
  del: jest.fn(),
  exists: jest.fn(),
  expire: jest.fn(),
  ttl: jest.fn(),
  keys: jest.fn(),
  scan: jest.fn(),
  hget: jest.fn(),
  hset: jest.fn(),
  hdel: jest.fn(),
  hgetall: jest.fn(),
  lpush: jest.fn(),
  rpush: jest.fn(),
  lpop: jest.fn(),
  rpop: jest.fn(),
  lrange: jest.fn(),
  sadd: jest.fn(),
  srem: jest.fn(),
  smembers: jest.fn(),
  sismember: jest.fn(),
  zadd: jest.fn(),
  zrem: jest.fn(),
  zrange: jest.fn(),
  zrangebyscore: jest.fn(),
  publish: jest.fn(),
  subscribe: jest.fn(),
  unsubscribe: jest.fn(),
  multi: jest.fn().mockReturnThis(),
  exec: jest.fn(),
  pipeline: jest.fn().mockReturnThis(),
});

export const createMockKafkaProducer = () => ({
  connect: jest.fn(),
  disconnect: jest.fn(),
  send: jest.fn(),
  sendBatch: jest.fn(),
});

export const createMockKafkaConsumer = () => ({
  connect: jest.fn(),
  disconnect: jest.fn(),
  subscribe: jest.fn(),
  run: jest.fn(),
  pause: jest.fn(),
  resume: jest.fn(),
  seek: jest.fn(),
  describeGroup: jest.fn(),
  commitOffsets: jest.fn(),
});

export const createMockHttpService = () => ({
  get: jest.fn(),
  post: jest.fn(),
  put: jest.fn(),
  patch: jest.fn(),
  delete: jest.fn(),
  head: jest.fn(),
  request: jest.fn(),
  axiosRef: {
    interceptors: {
      request: { use: jest.fn() },
      response: { use: jest.fn() },
    },
  },
});

export const createMockConfigService = () => ({
  get: jest.fn(),
  getOrThrow: jest.fn(),
  set: jest.fn(),
});

export const mockDate = (date: string | Date) => {
  const mockDate = new Date(date);
  jest.useFakeTimers();
  jest.setSystemTime(mockDate);
  return {
    restore: () => jest.useRealTimers(),
  };
};

export const expectToThrowWithMessage = async (
  fn: () => Promise<any> | any,
  errorClass: any,
  message: string | RegExp,
) => {
  let error: any;
  try {
    await fn();
  } catch (e) {
    error = e;
  }
  expect(error).toBeInstanceOf(errorClass);
  if (typeof message === 'string') {
    expect(error.message).toContain(message);
  } else {
    expect(error.message).toMatch(message);
  }
};

export const createTestModule = async (moduleOptions: any) => {
  const { Test } = require('@nestjs/testing');
  const module = await Test.createTestingModule(moduleOptions).compile();
  return module;
};

export const waitFor = (condition: () => boolean, timeout = 5000, interval = 100): Promise<void> => {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    const checkInterval = setInterval(() => {
      if (condition()) {
        clearInterval(checkInterval);
        resolve();
      } else if (Date.now() - startTime > timeout) {
        clearInterval(checkInterval);
        reject(new Error('Timeout waiting for condition'));
      }
    }, interval);
  });
};

export const delay = (ms: number): Promise<void> => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};