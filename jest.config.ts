import { getJestProjects } from '@nx/jest';

export default {
  projects: getJestProjects(),
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'apps/**/*.ts',
    'libs/**/*.ts',
    '!**/*.spec.ts',
    '!**/*.e2e-spec.ts',
    '!**/node_modules/**',
    '!**/dist/**',
    '!**/*.d.ts',
    '!**/main.ts',
    '!**/test-setup.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 95,
      functions: 95,
      lines: 95,
      statements: 95,
    },
  },
  testMatch: ['<rootDir>/{apps,libs}/**/*(*.)@(spec|test).[jt]s?(x)'],
  transform: {
    '^.+\\.[jt]s$': [
      '@swc/jest',
      {
        jsc: {
          parser: {
            syntax: 'typescript',
            decorators: true,
          },
          transform: {
            legacyDecorator: true,
            decoratorMetadata: true,
          },
        },
      },
    ],
  },
  moduleNameMapper: {
    '^@jts/(.*)$': '<rootDir>/libs/$1/src',
  },
  setupFilesAfterEnv: ['<rootDir>/tools/test-setup.ts'],
  testEnvironment: 'node',
  maxWorkers: '50%',
  verbose: true,
};
