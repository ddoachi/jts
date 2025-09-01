# Tools Directory

This directory contains custom Nx generators, executors, and utility scripts for the JTS monorepo.

## Structure

- `/generators` - Custom Nx generators for scaffolding new services and libraries
- `/executors` - Custom Nx executors for specialized build and deployment tasks
- `/scripts` - Utility scripts for development and operations

## Usage

### Custom Generators
```bash
nx g @jts/tools:service <service-name>
nx g @jts/tools:library <library-name>
```

### Custom Executors
Custom executors are configured in `workspace.json` or `project.json` files.

### Utility Scripts
Scripts in the `/scripts` directory can be run directly or through npm scripts defined in the root `package.json`.