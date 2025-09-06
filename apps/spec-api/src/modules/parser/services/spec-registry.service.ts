export class SpecRegistryService {
  constructor(private eventBus?: any, private logger?: any) {}

  register(spec: any): void {
    throw new Error('Method not implemented');
  }

  upsert(spec: any): void {
    throw new Error('Method not implemented');
  }

  get(id: string): any {
    throw new Error('Method not implemented');
  }

  getById(id: string): any {
    throw new Error('Method not implemented');
  }

  getAll(): any[] {
    throw new Error('Method not implemented');
  }

  delete(id: string): void {
    throw new Error('Method not implemented');
  }

  clear(): void {
    throw new Error('Method not implemented');
  }

  buildHierarchy(): any {
    throw new Error('Method not implemented');
  }

  validateDependencies(): void {
    throw new Error('Method not implemented');
  }

  getChildren(id: string): any[] {
    throw new Error('Method not implemented');
  }

  getTree(): any {
    throw new Error('Method not implemented');
  }
}