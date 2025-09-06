export class SpecDiscoveryService {
  constructor(private logger?: any) {}

  async discoverSpecs(directory: string): Promise<string[]> {
    throw new Error('Method not implemented');
  }

  async watchDirectory(directory: string): Promise<void> {
    throw new Error('Method not implemented');
  }
}