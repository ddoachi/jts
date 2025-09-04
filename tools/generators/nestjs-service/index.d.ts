/**
 * NestJS Service Generator
 *
 * WHY: Ensures consistent service creation across the JTS monorepo
 * HOW: Uses Nx devkit to generate standardized NestJS microservice structure
 * WHAT: Creates a new NestJS service with proper structure and configuration
 *
 * FLOW:
 * 1. Normalize options (names, paths, ports)
 * 2. Generate base NestJS application
 * 3. Apply custom templates for JTS patterns
 * 4. Update project configuration
 * 5. Format files and install packages
 *
 * GOTCHAS:
 * - Port assignment uses 3000+ range to avoid conflicts
 * - Tags are critical for Nx dependency graph
 * - Directory structure follows JTS conventions
 *
 * RELATED: tools/generators/jts-library/index.ts
 *
 * @example
 * nx g @tools/generators/nestjs-service --name=trading-service --port=3010
 * // Creates: apps/trading-service with standard JTS structure
 */
import { Tree } from '@nx/devkit';
export interface ServiceGeneratorSchema {
    name: string;
    directory?: string;
    tags?: string;
    port?: number;
    includeKafka?: boolean;
    includeGrpc?: boolean;
    includeWebsocket?: boolean;
}
/**
 * Main generator entry point
 *
 * WHY: Orchestrates the entire service generation process
 * HOW: Calls each generation step in sequence
 * WHAT: Returns a function that installs packages after generation
 */
export default function serviceGenerator(tree: Tree, options: ServiceGeneratorSchema): Promise<() => void>;
