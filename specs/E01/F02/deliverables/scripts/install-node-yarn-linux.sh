#!/bin/bash
# Generated from spec: E01-F02-T01 (Node.js and Yarn Environment Setup)
# Spec ID: 0768281a

set -e

echo "==================================="
echo "Linux Node.js & Yarn Installation"
echo "==================================="

check_sudo() {
    if ! command -v sudo &> /dev/null; then
        echo "Error: sudo is required for installation"
        exit 1
    fi
}

install_nodejs() {
    echo ""
    echo "Installing Node.js 20 LTS..."
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        echo "Node.js already installed: $NODE_VERSION"
        
        if [[ "$NODE_VERSION" =~ ^v20\. ]]; then
            echo "✓ Node.js 20.x already installed"
            return 0
        else
            echo "Different Node.js version found. Installing Node.js 20 LTS..."
        fi
    fi
    
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    echo "✓ Node.js installed successfully"
}

enable_corepack() {
    echo ""
    echo "Enabling Corepack..."
    
    if ! command -v corepack &> /dev/null; then
        echo "Corepack not found. Installing..."
        sudo npm install -g corepack
    fi
    
    corepack enable
    echo "✓ Corepack enabled"
}

install_yarn() {
    echo ""
    echo "Installing Yarn 4 (Berry)..."
    
    if command -v yarn &> /dev/null; then
        YARN_VERSION=$(yarn --version)
        echo "Current Yarn version: $YARN_VERSION"
    fi
    
    corepack prepare yarn@stable --activate
    
    yarn set version stable
    
    YARN_VERSION=$(yarn --version)
    echo "✓ Yarn $YARN_VERSION installed"
}

check_sudo
install_nodejs
enable_corepack
install_yarn

echo ""
echo "==================================="
echo "Linux installation complete!"
echo "==================================="
echo "Node.js version: $(node --version)"
echo "Yarn version: $(yarn --version)"
echo "npm version: $(npm --version)"