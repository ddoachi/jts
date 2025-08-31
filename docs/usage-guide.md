# Node.js and Yarn Environment Setup - Usage Guide

Generated from spec: E01-F02-T01 (Node.js and Yarn Environment Setup)  
Spec ID: 0768281a

## Overview

This guide provides step-by-step instructions for setting up Node.js 20 LTS and Yarn 4 (Berry) for the JTS monorepo development environment.

## Prerequisites

### Linux/WSL2

- Ubuntu 20.04+ or compatible distribution
- sudo access for package installation
- curl installed (`sudo apt-get install curl`)

### Windows

- Windows 10/11
- PowerShell with Administrator privileges
- Internet connection for downloading packages

## Installation Instructions

### Option 1: Unified Installation Script (Recommended)

1. **Make the script executable:**

   ```bash
   chmod +x scripts/install-node-yarn.sh
   ```

2. **Run the unified installer:**

   ```bash
   ./scripts/install-node-yarn.sh
   ```

   This script will:
   - Detect your operating system
   - Run the appropriate platform-specific installer
   - Verify the installation

### Option 2: Platform-Specific Installation

#### Linux/WSL2

1. **Make the script executable:**

   ```bash
   chmod +x scripts/install-node-yarn-linux.sh
   ```

2. **Run the Linux installer:**
   ```bash
   ./scripts/install-node-yarn-linux.sh
   ```

#### Windows

1. **Open PowerShell as Administrator**

2. **Navigate to the project directory:**

   ```powershell
   cd path\to\jts-monorepo
   ```

3. **Run the Windows installer:**
   ```powershell
   .\specs\E01\F02\deliverables\scripts\install-node-yarn-windows.ps1
   ```

## Post-Installation Setup

### 1. Copy Configuration Files

After installation, copy the configuration templates to the root directory:

```bash
# Copy Yarn configuration
cp configs/.yarnrc.yml .yarnrc.yml

# Copy package.json template
cp configs/package.json.template package.json

# Update .gitignore with Yarn 4 patterns
cat configs/gitignore.template >> .gitignore
```

### 2. Initialize Yarn Workspace

```bash
# Install Yarn plugins
yarn plugin import workspace-tools

# Create workspace directories
mkdir -p apps libs

# Install dependencies
yarn install
```

### 3. Verify Installation

Run the following commands to verify everything is working:

```bash
# Check Node.js version (should be 20.x)
node --version

# Check Yarn version (should be 4.x)
yarn --version

# Check Corepack is enabled
corepack --version

# List workspaces (should show apps/* and libs/*)
yarn workspaces list
```

## Configuration Details

### Yarn Configuration (.yarnrc.yml)

The provided configuration includes:

- **nodeLinker**: Uses traditional node_modules for compatibility
- **Workspace settings**: Optimized for monorepo development
- **Plugins**: Workspace tools for managing multiple packages
- **Performance**: Compression and caching optimizations

### Package.json Structure

The template provides:

- **Workspaces**: Configured for apps/_ and libs/_ directories
- **Engine requirements**: Node.js >=20 and Yarn >=4
- **Common scripts**: dev, build, test, lint, type-check
- **Nx integration**: Ready for Nx workspace tooling

## Troubleshooting

### Common Issues and Solutions

#### 1. Permission Denied (Linux)

```bash
# If you get permission errors, ensure scripts are executable
chmod +x scripts/*.sh
```

#### 2. Corepack Not Found

```bash
# Install Corepack globally if missing
npm install -g corepack
corepack enable
```

#### 3. Wrong Node.js Version

```bash
# On Linux, reinstall with the correct version
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

#### 4. Yarn Command Not Found

```bash
# Enable Corepack and set Yarn version
corepack enable
corepack prepare yarn@stable --activate
```

#### 5. Windows Execution Policy

```powershell
# If PowerShell blocks script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Workspace Management

### Creating a New Service

```bash
# Create a new app
mkdir apps/my-service
cd apps/my-service
yarn init -p

# Create a new library
mkdir libs/common
cd libs/common
yarn init -p
```

### Installing Dependencies

```bash
# Install to root
yarn add -D typescript @types/node

# Install to specific workspace
yarn workspace @jts/my-service add nestjs

# Install to all workspaces
yarn workspaces foreach add eslint
```

### Running Scripts

```bash
# Run script in all workspaces
yarn workspaces foreach run test

# Run script in specific workspace
yarn workspace @jts/my-service run dev

# Run parallel builds
yarn workspaces foreach -p run build
```

## Best Practices

1. **Always use Yarn for package management** - Don't mix npm and yarn
2. **Keep dependencies updated** - Use `yarn deps:upgrade` regularly
3. **Use workspace protocol** - Reference internal packages with `workspace:*`
4. **Commit yarn.lock** - Always commit the lockfile for reproducible builds
5. **Clean install when switching branches** - Run `yarn clean && yarn install`

## Additional Resources

- [Yarn 4 Documentation](https://yarnpkg.com/)
- [Node.js 20 LTS Documentation](https://nodejs.org/docs/latest-v20.x/api/)
- [Yarn Workspaces Guide](https://yarnpkg.com/features/workspaces)
- [Corepack Documentation](https://nodejs.org/api/corepack.html)

## Support

If you encounter issues not covered in this guide:

1. Check the installation script output for specific error messages
2. Verify all prerequisites are met
3. Consult the project's issue tracker
4. Contact the development team

## Version Compatibility

| Component | Required Version | Verified Version |
| --------- | ---------------- | ---------------- |
| Node.js   | >=20.0.0         | 20.x LTS         |
| Yarn      | >=4.0.0          | 4.x (Berry)      |
| npm       | >=10.0.0         | Included w/ Node |
| Corepack  | >=0.20.0         | Included w/ Node |
