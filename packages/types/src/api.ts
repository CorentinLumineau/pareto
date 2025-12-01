/**
 * Standard API response wrapper
 */
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: ApiError;
  meta?: ApiMeta;
}

/**
 * API error structure
 */
export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, string[]>;
}

/**
 * API metadata for pagination
 */
export interface ApiMeta {
  page: number;
  perPage: number;
  total: number;
  totalPages: number;
}

/**
 * Paginated response
 */
export interface PaginatedResponse<T> {
  items: T[];
  meta: ApiMeta;
}

/**
 * Pagination request parameters
 */
export interface PaginationParams {
  page?: number;
  perPage?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

/**
 * Search request parameters
 */
export interface SearchParams extends PaginationParams {
  query?: string;
  filters?: Record<string, string | number | boolean | string[]>;
}

/**
 * Health check response
 */
export interface HealthResponse {
  status: 'ok' | 'degraded' | 'error';
  version: string;
  timestamp: Date;
  services?: {
    database: 'ok' | 'error';
    redis: 'ok' | 'error';
    workers: 'ok' | 'error';
  };
}
