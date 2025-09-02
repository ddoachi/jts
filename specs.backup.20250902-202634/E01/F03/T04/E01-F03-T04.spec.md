---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: bdb106a0 # Unique identifier (never changes)
title: Implement TypeScript Configuration and Linting
type: task
category: infrastructure

# === HIERARCHY ===
parent: 'E01-F03'
children: []
epic: 'E01'
domain: infrastructure

# === WORKFLOW ===
status: completed
priority: high
assignee: 'claude'
reviewer: ''

# === TRACKING ===
created: '2025-08-28'
updated: '2025-09-01'
due_date: ''
estimated_hours: 2
actual_hours: 2

# === DEPENDENCIES ===
dependencies:
  - 'E01-F03-T02'
blocks:
  - 'E01-F03-T05'
  - 'E01-F03-T06'
related:
  - 'E01-F03-T03'
pull_requests:
  - text: 'Implement TypeScript Configuration and Linting'
    number: 71
    link: 'https://github.com/ddoachi/jts/pull/71'
commits:
  - text: 'feat(config): configure strict TypeScript settings'
    hash: '8cd39d8'
    link: 'https://github.com/ddoachi/jts/commit/8cd39d8'
  - text: 'feat(lint): Configure ESLint with Nx module boundary rules'
    hash: 'c6bbfb4'
    link: 'https://github.com/ddoachi/jts/commit/c6bbfb4'
  - text: 'feat(format): Configure Prettier for consistent code formatting'
    hash: '087e8a5'
    link: 'https://github.com/ddoachi/jts/commit/087e8a5'
  - text: 'feat(hooks): Update npm scripts for monorepo linting and type checking'
    hash: '2808860'
    link: 'https://github.com/ddoachi/jts/commit/2808860'
  - text: 'feat(nx): Add type-check target to nx configuration'
    hash: 'd8ab86f'
    link: 'https://github.com/ddoachi/jts/commit/d8ab86f'
context_file: '[context.md](./context.md)'
worktree: 'E01-F03-T04'
github_issue:
  number: 70
  link: 'https://github.com/ddoachi/jts/issues/70'
  status: 'open'
files:
  - tsconfig.base.json
  - .eslintrc.json
  - .prettierrc
  - .husky/*

# === METADATA ===
tags:
  - typescript
  - eslint
  - prettier
  - linting
  - code-quality
effort: small
risk: low
---

# Task T04: Implement TypeScript Configuration and Linting

## Overview

Configure strict TypeScript settings for type safety, set up comprehensive ESLint rules with Nx module boundaries, configure Prettier for consistent formatting, and implement pre-commit hooks to maintain code quality.

## Acceptance Criteria

- [x] TypeScript configured with strict mode and ES2022 target
- [x] ESLint rules enforce architectural constraints
- [x] Prettier integrated for consistent formatting
- [x] Pre-commit hooks validate code quality
- [x] All configurations work across the monorepo
- [x] IDE integration configured

## Technical Details

### 1. TypeScript Base Configuration

```json
// tsconfig.base.json
{
  "compileOnSave": false,
  "compilerOptions": {
    "rootDir": ".",
    "sourceMap": true,
    "declaration": false,
    "moduleResolution": "node",
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "importHelpers": true,
    "target": "ES2022",
    "module": "ESNext",
    "lib": ["ES2022", "DOM"],
    "skipLibCheck": true,
    "skipDefaultLibCheck": true,

    // Strict type checking
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": false, // For NestJS
    "noImplicitThis": true,
    "alwaysStrict": true,

    // Additional checks
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,

    // Module resolution
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "incremental": true,

    "baseUrl": ".",
    "paths": {
      // Path mappings configured in task T02
    }
  },
  "exclude": ["node_modules", "tmp", "dist"]
}
```

### 2. ESLint Configuration

```json
// .eslintrc.json
{
  "root": true,
  "ignorePatterns": ["**/*"],
  "plugins": ["@nx", "@typescript-eslint", "import", "prettier"],
  "extends": [
    "@nx/eslint-plugin",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
    "plugin:import/recommended",
    "plugin:import/typescript",
    "prettier"
  ],
  "overrides": [
    {
      "files": ["*.ts", "*.tsx"],
      "parserOptions": {
        "project": ["./tsconfig.*?.json"]
      },
      "rules": {
        // Nx module boundaries
        "@nx/enforce-module-boundaries": [
          "error",
          {
            "enforceBuildableLibDependency": true,
            "allow": [],
            "depConstraints": [
              {
                "sourceTag": "scope:shared",
                "onlyDependOnLibsWithTags": ["scope:shared"]
              },
              {
                "sourceTag": "scope:domain",
                "onlyDependOnLibsWithTags": ["scope:shared", "scope:domain"]
              },
              {
                "sourceTag": "scope:infrastructure",
                "onlyDependOnLibsWithTags": ["scope:shared", "scope:domain", "scope:infrastructure"]
              },
              {
                "sourceTag": "scope:brokers",
                "onlyDependOnLibsWithTags": ["scope:shared", "scope:domain", "scope:infrastructure"]
              },
              {
                "sourceTag": "scope:apps",
                "onlyDependOnLibsWithTags": ["*"]
              }
            ]
          }
        ],

        // TypeScript rules
        "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
        "@typescript-eslint/no-explicit-any": "warn",
        "@typescript-eslint/explicit-function-return-type": "warn",
        "@typescript-eslint/no-floating-promises": "error",
        "@typescript-eslint/await-thenable": "error",
        "@typescript-eslint/no-misused-promises": "error",
        "@typescript-eslint/require-await": "error",
        "@typescript-eslint/no-unsafe-assignment": "warn",
        "@typescript-eslint/no-unsafe-call": "warn",
        "@typescript-eslint/no-unsafe-member-access": "warn",
        "@typescript-eslint/no-unsafe-return": "warn",

        // Import rules
        "import/order": [
          "error",
          {
            "groups": ["builtin", "external", "internal", "parent", "sibling", "index"],
            "newlines-between": "always",
            "alphabetize": {
              "order": "asc",
              "caseInsensitive": true
            }
          }
        ],
        "import/no-duplicates": "error",
        "import/no-cycle": "error",

        // General rules
        "prefer-const": "error",
        "no-var": "error",
        "no-console": ["warn", { "allow": ["warn", "error"] }],
        "no-debugger": "error"
      }
    },
    {
      "files": ["*.spec.ts", "*.test.ts"],
      "rules": {
        "@typescript-eslint/no-explicit-any": "off",
        "@typescript-eslint/no-non-null-assertion": "off",
        "@typescript-eslint/no-unsafe-assignment": "off"
      }
    }
  ]
}
```

### 3. Prettier Configuration

```json
// .prettierrc
{
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "trailingComma": "all",
  "bracketSpacing": true,
  "bracketSameLine": false,
  "arrowParens": "always",
  "endOfLine": "lf"
}
```

### 4. Pre-commit Hooks Setup

```bash
# Install husky and lint-staged
npm install --save-dev husky lint-staged

# Initialize husky
npx husky install

# Add pre-commit hook
npx husky add .husky/pre-commit "npx lint-staged"
```

```json
// package.json additions
{
  "scripts": {
    "prepare": "husky install",
    "lint": "nx run-many --target=lint --all",
    "lint:fix": "nx run-many --target=lint --all --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "type-check": "nx run-many --target=type-check --all"
  },
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md,yaml,yml}": ["prettier --write"]
  }
}
```

### 5. Type Check Target

```json
// nx.json addition
{
  "targetDefaults": {
    "type-check": {
      "executor": "@nx/js:tsc",
      "options": {
        "tsConfig": "{projectRoot}/tsconfig.lib.json",
        "noEmit": true
      },
      "dependsOn": ["^type-check"],
      "inputs": ["default"],
      "cache": true
    }
  }
}
```

## Implementation Steps

1. **Configure TypeScript** (30 min)
   - Update tsconfig.base.json with strict settings
   - Configure compiler options for ES2022
   - Set up strict type checking rules

2. **Set up ESLint** (45 min)
   - Install ESLint plugins and configs
   - Configure architectural boundary rules
   - Set up TypeScript-specific rules

3. **Configure Prettier** (15 min)
   - Create .prettierrc configuration
   - Add .prettierignore for excluded files
   - Test formatting across different file types

4. **Implement pre-commit hooks** (20 min)
   - Install and configure husky
   - Set up lint-staged configuration
   - Test pre-commit workflow

5. **Add type-check target** (10 min)
   - Configure type-check in nx.json
   - Add npm scripts for type checking
   - Verify across all projects

## Testing

```bash
# Run linting
nx lint

# Fix linting issues
nx lint --fix

# Format code
npm run format

# Check formatting
npm run format:check

# Run type checking
npm run type-check

# Test pre-commit hook
git add .
git commit -m "test: pre-commit hooks"

# Verify module boundaries
nx lint shared-utils
```

## Success Metrics

- Zero TypeScript compiler errors
- ESLint runs without errors on clean code
- Prettier formatting is consistent
- Pre-commit hooks prevent bad code commits
- Module boundary violations are caught

## Notes

- TypeScript strict mode catches many bugs early
- ESLint module boundaries maintain architecture
- Prettier removes formatting debates
- Pre-commit hooks ensure quality before commits
- Consider editor integration for real-time feedback
