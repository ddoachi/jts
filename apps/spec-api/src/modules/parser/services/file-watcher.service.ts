export class FileWatcherService {
  constructor(private eventBus?: any, private logger?: any) {}

  async watchFile(path: string): Promise<void> {
    throw new Error('Method not implemented');
  }

  async startWatching(paths?: string[]): Promise<void> {
    throw new Error('Method not implemented');
  }

  stop(): void {
    throw new Error('Method not implemented');
  }
}