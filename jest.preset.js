const nxPreset = require('@nx/jest/preset').default;

module.exports = {
  ...nxPreset,
  coverageReporters: ['text', 'html', 'cobertura'],
  testTimeout: 10000,
  clearMocks: true,
  restoreMocks: true,
};
