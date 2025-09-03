#!/usr/bin/env node

/**
 * Test Generators Script
 *
 * WHY: Verifies that custom generators are properly structured
 * HOW: Checks for required files and validates schemas
 * WHAT: Reports generator readiness status
 */

const fs = require('fs');
const path = require('path');

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Generator Validation ███
// ═══════════════════════════════════════════════════════════════════

const generators = [
  {
    name: 'NestJS Service Generator',
    path: 'tools/generators/nestjs-service',
    requiredFiles: [
      'index.ts',
      'schema.json',
      'files/src/main.ts__template__',
      'files/src/app/app.module.ts__template__',
      'files/src/domain/domain.module.ts__template__',
      'files/src/infra/infra.module.ts__template__',
      'files/src/shared/shared.module.ts__template__',
      'files/Dockerfile__template__',
      'files/.env.example__template__',
      'files/README.md__template__',
    ],
  },
  {
    name: 'JTS Library Generator',
    path: 'tools/generators/jts-library',
    requiredFiles: [
      'index.ts',
      'schema.json',
      'files/README.md__template__',
      'files/jest.config.ts__template__',
    ],
  },
];

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Validation Functions ███
// ═══════════════════════════════════════════════════════════════════

function validateGenerator(generator) {
  console.log(`\n📦 Testing ${generator.name}...`);
  console.log('─'.repeat(50));

  const basePath = path.join(process.cwd(), generator.path);
  
  // Check if generator directory exists
  if (!fs.existsSync(basePath)) {
    console.log(`❌ Generator directory not found: ${generator.path}`);
    return false;
  }

  console.log(`✅ Generator directory exists: ${generator.path}`);

  // Check required files
  let allFilesExist = true;
  for (const file of generator.requiredFiles) {
    const filePath = path.join(basePath, file);
    if (fs.existsSync(filePath)) {
      console.log(`  ✅ ${file}`);
    } else {
      console.log(`  ❌ Missing: ${file}`);
      allFilesExist = false;
    }
  }

  // Validate schema.json
  const schemaPath = path.join(basePath, 'schema.json');
  if (fs.existsSync(schemaPath)) {
    try {
      const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
      if (schema.$schema && schema.properties) {
        console.log(`  ✅ Valid schema.json`);
      } else {
        console.log(`  ⚠️  Schema.json missing required fields`);
      }
    } catch (error) {
      console.log(`  ❌ Invalid schema.json: ${error.message}`);
      allFilesExist = false;
    }
  }

  return allFilesExist;
}

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: NPM Scripts Check ███
// ═══════════════════════════════════════════════════════════════════

function checkNpmScripts() {
  console.log('\n🔧 Checking NPM Scripts...');
  console.log('─'.repeat(50));

  const packageJsonPath = path.join(process.cwd(), 'package.json');
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

  const requiredScripts = [
    'g:service',
    'g:lib',
    'generate:service',
    'generate:library',
  ];

  let allScriptsExist = true;
  for (const script of requiredScripts) {
    if (packageJson.scripts[script]) {
      console.log(`  ✅ ${script}: ${packageJson.scripts[script]}`);
    } else {
      console.log(`  ❌ Missing script: ${script}`);
      allScriptsExist = false;
    }
  }

  return allScriptsExist;
}

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Main Execution ███
// ═══════════════════════════════════════════════════════════════════

console.log('🚀 JTS Generator Test Suite');
console.log('═'.repeat(50));

let allTestsPassed = true;

// Test each generator
for (const generator of generators) {
  if (!validateGenerator(generator)) {
    allTestsPassed = false;
  }
}

// Check NPM scripts
if (!checkNpmScripts()) {
  allTestsPassed = false;
}

// Summary
console.log('\n' + '═'.repeat(50));
if (allTestsPassed) {
  console.log('✨ All generator tests passed!');
  console.log('\nYou can now use:');
  console.log('  yarn g:service     - Create a new NestJS service');
  console.log('  yarn g:lib         - Create a new library');
} else {
  console.log('⚠️  Some tests failed. Please check the errors above.');
  process.exit(1);
}

console.log('\n📚 Documentation: docs/generators-guide.md');
console.log('═'.repeat(50));