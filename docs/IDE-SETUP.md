# Generated from: specs/E01/F02/spec.md (Development Environment Setup)
# Original location: specs/E01/F02/deliverables/docs/IDE-SETUP.md

# VS Code IDE Setup Guide

This guide covers the VS Code configuration for the JTS trading system development environment.

## Overview

The workspace includes optimized settings for TypeScript/NestJS development with Nx monorepo support, debugging configurations for microservices, and essential extensions for productivity.

## Configuration Files

### Workspace Settings (`.vscode/settings.json`)

Key configurations include:
- TypeScript relative imports and SDK configuration
- Format on save with Prettier
- ESLint integration with auto-fix
- File and search exclusions for performance
- Jest test runner integration
- Nx telemetry disabled for privacy

### Recommended Extensions (`.vscode/extensions.json`)

Essential extensions for development:
- **TypeScript**: `ms-vscode.vscode-typescript-next` - Enhanced TypeScript support
- **Prettier**: `esbenp.prettier-vscode` - Code formatting
- **ESLint**: `dbaeumer.vscode-eslint` - Linting and code quality
- **Jest**: `firsttris.vscode-jest-runner` - Test running and debugging
- **Nx Console**: `nrwl.angular-console` - Nx workspace management
- **Docker**: `ms-azuretools.vscode-docker` - Container support
- **YAML**: `redhat.vscode-yaml` - Configuration file support
- **Thunder Client**: `rangav.vscode-thunder-client` - API testing
- **MongoDB**: `mongodb.mongodb-vscode` - Database integration
- **Database Client**: `cweijan.vscode-database-client2` - Multi-database support

### Debug Configurations (`.vscode/launch.json`)

Pre-configured debug setups:
- **Debug API Gateway**: Launch API Gateway service in debug mode
- **Debug Strategy Engine**: Launch Strategy Engine service in debug mode
- **Debug Tests**: Run Jest tests with debugging enabled
- **Attach to NestJS**: Attach debugger to running NestJS process

### Task Automation (`.vscode/tasks.json`)

Quick access tasks:
- **Start All Services**: Launch all microservices
- **Run Tests**: Execute test suite
- **Docker Compose Up**: Start development environment

## Usage Instructions

### Setting Up the Environment

1. **Install Extensions**: VS Code will prompt to install recommended extensions
2. **Verify Settings**: Check that TypeScript and formatting work correctly
3. **Test Debugging**: Try debugging configurations with sample services
4. **Run Tasks**: Use Ctrl+Shift+P → "Tasks: Run Task" to access quick tasks

### Development Workflow

1. **Code with Auto-formatting**: Files automatically format on save
2. **Use IntelliSense**: TypeScript paths and imports work seamlessly
3. **Debug Services**: Use F5 to start debugging any microservice
4. **Run Tests**: Use the Jest extension or debug configuration
5. **Quick Commands**: Access common operations through tasks

### Debugging Guidelines

- Use breakpoints in TypeScript files directly
- Environment variables are set automatically for debug sessions
- Console output appears in VS Code integrated terminal
- Attach configuration works for already running services

### Performance Optimizations

- Node modules and build artifacts excluded from file watcher
- Search excludes unnecessary directories
- TypeScript SDK uses workspace version
- Nx telemetry disabled to reduce overhead

## Troubleshooting

### Common Issues

1. **Extensions Not Installing**: Check internet connection and VS Code marketplace access
2. **Formatting Not Working**: Verify Prettier extension is enabled and set as default formatter
3. **Debug Not Starting**: Check that yarn and nx commands work in terminal
4. **TypeScript Errors**: Ensure workspace TypeScript version is being used

### File Locations

- Workspace settings: `.vscode/settings.json`
- Extensions: `.vscode/extensions.json`
- Debug configs: `.vscode/launch.json`
- Tasks: `.vscode/tasks.json`

## Integration Notes

- Configuration preserves existing user settings while adding project-specific optimizations
- Debug configurations use Yarn (not npm) to match project setup
- Settings are optimized for Nx monorepo structure
- File exclusions improve performance with large codebases

## Next Steps

After setup completion:
1. Install recommended extensions when prompted
2. Test debug configurations with sample services
3. Verify formatting and linting work correctly
4. Customize additional settings as needed for your workflow