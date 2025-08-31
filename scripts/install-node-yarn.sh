#!/bin/bash
# Generated from: specs/E01/F02/spec.md (Development Environment Setup)
# Original location: specs/E01/F02/deliverables/scripts/install-node-yarn.sh

set -e

echo "==================================="
echo "JTS Node.js & Yarn Setup"
echo "==================================="

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    elif grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo "Detected OS: $OS"

case "$OS" in
    linux|wsl)
        echo "Running Linux installation..."
        bash "$(dirname "$0")/install-node-yarn-linux.sh"
        ;;
    windows)
        echo "Please run install-node-yarn-windows.ps1 in PowerShell"
        exit 1
        ;;
    macos)
        echo "macOS installation not yet implemented"
        exit 1
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

echo ""
echo "==================================="
echo "Verifying installations..."
echo "==================================="

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js installed: $NODE_VERSION"
    
    if [[ ! "$NODE_VERSION" =~ ^v20\. ]]; then
        echo "⚠ Warning: Node.js 20.x LTS recommended, found $NODE_VERSION"
    fi
else
    echo "✗ Node.js not found"
    exit 1
fi

if command -v yarn &> /dev/null; then
    YARN_VERSION=$(yarn --version)
    echo "✓ Yarn installed: $YARN_VERSION"
    
    if [[ ! "$YARN_VERSION" =~ ^4\. ]]; then
        echo "⚠ Warning: Yarn 4.x recommended, found $YARN_VERSION"
    fi
else
    echo "✗ Yarn not found"
    exit 1
fi

if command -v corepack &> /dev/null; then
    echo "✓ Corepack available"
else
    echo "⚠ Corepack not found - Yarn version management may not work correctly"
fi

echo ""
echo "==================================="
echo "Setup complete!"
echo "==================================="
echo "Next steps:"
echo "1. Run 'yarn install' to install dependencies"
echo "2. Run 'yarn workspace' to see available workspaces"
echo "3. Start developing your microservices!"