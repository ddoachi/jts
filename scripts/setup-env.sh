#!/bin/bash
# Generated from spec: E01-F02-T04 (Environment Configuration and Secrets Management)
# Spec ID: 021bbc7e

set -e

echo "🔧 Setting up JTS environment configuration..."

# Check if we're in the project root
if [ ! -f "package.json" ]; then
    echo "❌ Error: Must run this script from the project root directory"
    exit 1
fi

# Check if .env.local exists
if [ -f .env.local ]; then
    echo "⚠️  .env.local already exists."
    read -p "Do you want to backup and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_file=".env.local.backup.$(date +%Y%m%d_%H%M%S)"
        echo "📦 Backing up existing .env.local to $backup_file"
        cp .env.local "$backup_file"
        echo "📝 Creating new .env.local from template..."
        cp .env.example .env.local
    else
        echo "📋 Keeping existing .env.local"
    fi
else
    echo "📝 Creating .env.local from template..."
    cp .env.example .env.local
    echo "✅ .env.local created. Please update with your actual credentials."
fi

# Create secure directories for Creon (Windows/WSL only)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "linux-gnu" ]]; then
    if [[ -d "/mnt/c" || -d "/c" ]]; then
        echo "🔒 Setting up secure Creon directories..."
        
        # Create directories
        sudo mkdir -p /secure/creon/{credentials,scripts,logs}
        
        # Set restricted permissions (owner only)
        sudo chmod 700 /secure/creon
        sudo chmod 700 /secure/creon/credentials
        sudo chmod 755 /secure/creon/scripts
        sudo chmod 755 /secure/creon/logs
        
        # Change ownership to current user
        sudo chown -R $(whoami):$(whoami) /secure/creon
        
        # Create README files
        cat > /secure/creon/credentials/README.md << 'EOF'
# Creon Credentials Directory

This directory stores sensitive Creon credentials.

## Security Requirements
- Never commit files from this directory
- Keep permissions at 700 (owner only)
- Store encrypted credentials only

## File Structure
```
credentials/
├── creon_login.enc     # Encrypted login credentials
└── README.md          # This file
```

## Usage
1. Place your encrypted credentials here
2. The auto-login script will decrypt and use them
3. Never store plain text credentials
EOF
        
        echo "📋 Creon directories created at /secure/creon/"
        echo "   Add your credentials to /secure/creon/credentials/"
    fi
fi

# Validate KIS accounts configuration
echo ""
echo "🔍 Checking KIS account configuration..."
kis_configured=0

# Get total accounts from .env.local or default to 2
if [ -f .env.local ]; then
    kis_total_accounts=$(grep "^KIS_TOTAL_ACCOUNTS=" .env.local | cut -d'=' -f2 | tr -d ' ')
fi
kis_total_accounts=${kis_total_accounts:-2}

# Iterate over KIS accounts based on KIS_TOTAL_ACCOUNTS
for i in $(seq 1 $kis_total_accounts); do
    if grep -q "your_kis_appkey_${i}_here" .env.local 2>/dev/null; then
        echo "   ⚠️  KIS Account ${i}: Not configured (update KIS_ACCOUNT_${i}_* variables)"
    else
        echo "   ✅ KIS Account ${i}: Configured"
        kis_configured=$((kis_configured + 1))
    fi
done

echo "   📊 Total KIS accounts configured: $kis_configured/$kis_total_accounts"

# Check Node.js installation
echo ""
echo "🔍 Checking Node.js environment..."
if command -v node &> /dev/null; then
    node_version=$(node -v)
    echo "   ✅ Node.js installed: $node_version"
    
    # Run validation script if Node.js is available
    if [ -f "scripts/validate-env.js" ]; then
        echo ""
        echo "🔍 Running environment validation..."
        node scripts/validate-env.js
    fi
else
    echo "   ⚠️  Node.js not installed. Please install Node.js to run validation."
fi

# Create logs directory
echo ""
echo "📁 Creating logs directory..."
mkdir -p logs
echo "   ✅ Logs directory created at ./logs/"

# Final instructions
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Environment setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next steps:"
echo "   1. Edit .env.local with your actual credentials"
echo "   2. Configure KIS account credentials (KIS_ACCOUNT_*)"
echo "   3. Update JWT_SECRET and other security keys"
echo "   4. If using Creon, add credentials to /secure/creon/credentials/"
echo "   5. Run 'node scripts/validate-env.js' to verify"
echo ""
echo "🔒 Security reminders:"
echo "   • Never commit .env.local to git"
echo "   • Keep all credentials secure"
echo "   • Use strong, unique passwords for JWT_SECRET"
echo "   • Regularly rotate API keys"