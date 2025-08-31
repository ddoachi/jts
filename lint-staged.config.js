module.exports = {
  '*.{ts,tsx}': ['eslint --fix', 'prettier --write', 'jest --bail --findRelatedTests'],
  '*.{js,jsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml}': ['prettier --write'],
  '*.sql': ['prettier --write --parser sql'],
};
