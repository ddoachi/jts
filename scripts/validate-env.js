#!/usr/bin/env node
// Generated from spec: E01-F02-T04 (Environment Configuration and Secrets Management)
// Spec ID: 021bbc7e

const fs = require('fs');
const path = require('path');

const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function validateEnv() {
  const projectRoot = path.resolve(__dirname, '..');
  const envPath = path.join(projectRoot, '.env.local');
  const envExamplePath = path.join(projectRoot, '.env.example');
  
  log('\n🔍 JTS Environment Validation\n', 'cyan');
  log('━'.repeat(50), 'cyan');
  
  // Check if .env.local exists
  if (!fs.existsSync(envPath)) {
    log('❌ .env.local not found!', 'red');
    log('   Run: bash specs/E01/F02/deliverables/scripts/setup-env.sh', 'yellow');
    process.exit(1);
  }
  
  log('✅ .env.local found', 'green');
  
  // Read environment files
  const envContent = fs.readFileSync(envPath, 'utf8');
  const envLines = envContent.split('\n');
  
  // Parse environment variables
  const envVars = {};
  envLines.forEach(line => {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const [key, ...valueParts] = trimmed.split('=');
      if (key) {
        envVars[key.trim()] = valueParts.join('=').trim();
      }
    }
  });
  
  // Validation results
  const errors = [];
  const warnings = [];
  const info = [];
  
  // Check critical configurations
  log('\n📋 Configuration Status:', 'cyan');
  log('━'.repeat(50), 'cyan');
  
  // Database configuration
  log('\n🗄️  Databases:', 'blue');
  if (envVars.DATABASE_URL && !envVars.DATABASE_URL.includes('dev_password')) {
    log('   ✅ PostgreSQL configured', 'green');
  } else {
    warnings.push('PostgreSQL using default dev password');
    log('   ⚠️  PostgreSQL using default password', 'yellow');
  }
  
  if (envVars.REDIS_URL) {
    log('   ✅ Redis configured', 'green');
  } else {
    errors.push('Redis URL not configured');
    log('   ❌ Redis not configured', 'red');
  }
  
  // KIS Account validation
  log('\n💱 KIS Accounts:', 'blue');
  const totalAccounts = parseInt(envVars.KIS_TOTAL_ACCOUNTS || '0');
  let configuredAccounts = 0;
  
  for (let i = 1; i <= 5; i++) {
    const enabled = envVars[`KIS_ACCOUNT_${i}_ENABLED`] === 'true';
    const hasKey = envVars[`KIS_ACCOUNT_${i}_APPKEY`];
    const hasSecret = envVars[`KIS_ACCOUNT_${i}_APPSECRET`];
    const hasNumber = envVars[`KIS_ACCOUNT_${i}_NUMBER`];
    const name = envVars[`KIS_ACCOUNT_${i}_NAME`] || `Account ${i}`;
    
    if (enabled) {
      if (hasKey && !hasKey.includes('your_kis_appkey') && 
          hasSecret && !hasSecret.includes('your_kis_appsecret') &&
          hasNumber && !hasNumber.includes('your_account_number')) {
        configuredAccounts++;
        log(`   ✅ Account ${i} (${name}): Configured and enabled`, 'green');
      } else {
        warnings.push(`KIS Account ${i} enabled but not configured`);
        log(`   ⚠️  Account ${i} (${name}): Enabled but missing credentials`, 'yellow');
      }
    } else if (i <= 2) {
      info.push(`KIS Account ${i} is disabled`);
      log(`   ℹ️  Account ${i} (${name}): Disabled`, 'cyan');
    }
  }
  
  if (configuredAccounts >= 2) {
    log(`   📊 Total configured: ${configuredAccounts}/${totalAccounts} accounts`, 'green');
  } else {
    warnings.push(`Only ${configuredAccounts} KIS accounts configured (minimum 2 recommended)`);
    log(`   ⚠️  Total configured: ${configuredAccounts}/${totalAccounts} accounts`, 'yellow');
  }
  
  // Creon configuration
  log('\n🖥️  Creon (Windows):', 'blue');
  if (envVars.CREON_ENABLED === 'true') {
    if (envVars.CREON_SCRIPT_PATH && envVars.CREON_CREDENTIALS_PATH) {
      log('   ✅ Creon enabled and configured', 'green');
    } else {
      warnings.push('Creon enabled but paths not configured');
      log('   ⚠️  Creon enabled but missing configuration', 'yellow');
    }
  } else {
    log('   ℹ️  Creon disabled', 'cyan');
  }
  
  // Crypto APIs (Optional)
  log('\n🪙 Crypto APIs (Optional):', 'blue');
  if (envVars.BINANCE_ENABLED === 'true') {
    if (envVars.BINANCE_API_KEY && !envVars.BINANCE_API_KEY.includes('your_binance')) {
      log('   ✅ Binance configured', 'green');
    } else {
      info.push('Binance enabled but no API key');
      log('   ℹ️  Binance: No API key (reserved for future)', 'cyan');
    }
  } else {
    log('   ℹ️  Binance: Disabled', 'cyan');
  }
  
  if (envVars.UPBIT_ENABLED === 'true') {
    if (envVars.UPBIT_ACCESS_KEY && !envVars.UPBIT_ACCESS_KEY.includes('your_upbit')) {
      log('   ✅ Upbit configured', 'green');
    } else {
      info.push('Upbit enabled but no API key');
      log('   ℹ️  Upbit: No API key (reserved for future)', 'cyan');
    }
  } else {
    log('   ℹ️  Upbit: Disabled', 'cyan');
  }
  
  // Security configuration
  log('\n🔒 Security:', 'blue');
  if (envVars.JWT_SECRET === 'your-dev-jwt-secret-key-change-this') {
    errors.push('JWT_SECRET not changed from default');
    log('   ❌ JWT_SECRET using default value', 'red');
  } else {
    log('   ✅ JWT_SECRET configured', 'green');
  }
  
  if (envVars.SESSION_SECRET === 'your-session-secret-change-this') {
    warnings.push('SESSION_SECRET not changed from default');
    log('   ⚠️  SESSION_SECRET using default value', 'yellow');
  } else {
    log('   ✅ SESSION_SECRET configured', 'green');
  }
  
  // Development features
  log('\n🛠️  Development Features:', 'blue');
  if (envVars.ENABLE_SWAGGER === 'true') {
    log('   ✅ Swagger enabled', 'green');
  }
  if (envVars.ENABLE_DEBUG_ROUTES === 'true') {
    log('   ✅ Debug routes enabled', 'green');
  }
  if (envVars.ENABLE_MOCK_DATA === 'true') {
    log('   ✅ Mock data enabled', 'green');
  }
  
  // Summary
  log('\n━'.repeat(50), 'cyan');
  log('📊 Validation Summary:', 'cyan');
  log('━'.repeat(50), 'cyan');
  
  if (errors.length > 0) {
    log(`\n❌ Errors (${errors.length}):`, 'red');
    errors.forEach(err => log(`   • ${err}`, 'red'));
  }
  
  if (warnings.length > 0) {
    log(`\n⚠️  Warnings (${warnings.length}):`, 'yellow');
    warnings.forEach(warn => log(`   • ${warn}`, 'yellow'));
  }
  
  if (info.length > 0) {
    log(`\nℹ️  Info (${info.length}):`, 'cyan');
    info.forEach(inf => log(`   • ${inf}`, 'cyan'));
  }
  
  // Final status
  log('\n━'.repeat(50), 'cyan');
  if (errors.length === 0) {
    if (warnings.length === 0) {
      log('✅ Environment validation passed!', 'green');
      log('   Your environment is properly configured.', 'green');
    } else {
      log('⚠️  Environment validation passed with warnings', 'yellow');
      log('   Consider addressing the warnings above.', 'yellow');
    }
    process.exit(0);
  } else {
    log('❌ Environment validation failed!', 'red');
    log('   Please fix the errors above before proceeding.', 'red');
    process.exit(1);
  }
}

// Run validation
try {
  validateEnv();
} catch (error) {
  log(`\n❌ Validation error: ${error.message}`, 'red');
  process.exit(1);
}