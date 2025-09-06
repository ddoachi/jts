import baseConfig from './jest.config';

export default {
  ...baseConfig,
  ci: true,
  coverage: true,
  coverageDirectory: 'coverage',
  collectCoverageFrom: baseConfig.collectCoverageFrom,
  coverageThreshold: baseConfig.coverageThreshold,
  reporters: [
    'default',
    [
      'jest-junit',
      {
        outputDirectory: 'test-results',
        outputName: 'junit.xml',
      },
    ],
  ],
  silent: true,
  maxWorkers: 3,
  bail: 1,
  testTimeout: 30000,
};
