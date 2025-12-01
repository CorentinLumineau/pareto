import type { ApiResponse, ApiError } from '@pareto/types';

/**
 * API client configuration
 */
export interface ApiClientConfig {
  baseUrl: string;
  headers?: Record<string, string>;
  timeout?: number;
}

/**
 * API client error
 */
export class ApiClientError extends Error {
  constructor(
    message: string,
    public status: number,
    public error?: ApiError
  ) {
    super(message);
    this.name = 'ApiClientError';
  }
}

/**
 * Create a typed API client
 */
export function createApiClient(config: ApiClientConfig) {
  const { baseUrl, headers: defaultHeaders = {}, timeout = 30000 } = config;

  async function request<T>(
    method: string,
    path: string,
    options: {
      body?: unknown;
      params?: Record<string, string | number | boolean | undefined>;
      headers?: Record<string, string>;
    } = {}
  ): Promise<T> {
    const { body, params, headers = {} } = options;

    // Build URL with query params
    const url = new URL(path, baseUrl);
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined) {
          url.searchParams.set(key, String(value));
        }
      });
    }

    // Setup abort controller for timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(url.toString(), {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...defaultHeaders,
          ...headers,
        },
        body: body ? JSON.stringify(body) : undefined,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      const data = (await response.json()) as ApiResponse<T>;

      if (!response.ok || !data.success) {
        throw new ApiClientError(
          data.error?.message ?? 'Request failed',
          response.status,
          data.error
        );
      }

      return data.data;
    } catch (error) {
      clearTimeout(timeoutId);

      if (error instanceof ApiClientError) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new ApiClientError('Request timeout', 408);
      }

      throw new ApiClientError(
        error instanceof Error ? error.message : 'Unknown error',
        500
      );
    }
  }

  return {
    get<T>(
      path: string,
      params?: Record<string, string | number | boolean | undefined>
    ): Promise<T> {
      return request<T>('GET', path, { params });
    },

    post<T>(path: string, body?: unknown): Promise<T> {
      return request<T>('POST', path, { body });
    },

    put<T>(path: string, body?: unknown): Promise<T> {
      return request<T>('PUT', path, { body });
    },

    patch<T>(path: string, body?: unknown): Promise<T> {
      return request<T>('PATCH', path, { body });
    },

    delete<T>(path: string): Promise<T> {
      return request<T>('DELETE', path);
    },
  };
}

/**
 * Default API client instance
 */
let defaultClient: ReturnType<typeof createApiClient> | null = null;

/**
 * Initialize the default API client
 */
export function initApiClient(config: ApiClientConfig): void {
  defaultClient = createApiClient(config);
}

/**
 * Get the default API client
 */
export function getApiClient(): ReturnType<typeof createApiClient> {
  if (!defaultClient) {
    throw new Error(
      'API client not initialized. Call initApiClient() first.'
    );
  }
  return defaultClient;
}
