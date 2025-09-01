// Generated from spec: E01-F03-T02 (Configure Shared Libraries Infrastructure)
// Spec ID: 995e1fda

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: ApiError;
  metadata?: ResponseMetadata;
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, any>;
  timestamp: Date;
  path?: string;
  method?: string;
}

export interface ResponseMetadata {
  timestamp: Date;
  requestId: string;
  duration: number;
  version?: string;
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: PaginationInfo;
}

export interface PaginationInfo {
  page: number;
  pageSize: number;
  totalPages: number;
  totalItems: number;
  hasNext: boolean;
  hasPrevious: boolean;
}

export interface PaginationParams {
  page?: number;
  pageSize?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface FilterParams {
  [key: string]: any;
  startDate?: Date | string;
  endDate?: Date | string;
  status?: string | string[];
  search?: string;
}

export interface QueryParams extends PaginationParams, FilterParams {}

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';

export interface RequestConfig {
  url: string;
  method: HttpMethod;
  headers?: Record<string, string>;
  params?: Record<string, any>;
  data?: any;
  timeout?: number;
  retries?: number;
  retryDelay?: number;
}

export interface WebSocketMessage<T = any> {
  type: string;
  payload: T;
  timestamp: Date;
  id?: string;
  correlationId?: string;
}

export interface StreamData<T> {
  data: T;
  timestamp: Date;
  sequence: number;
  isSnapshot: boolean;
}