import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import type {
  Product,
  ProductWithPrices,
  CreateProductRequest,
  UpdateProductRequest,
  Price,
  PriceHistory,
  Category,
  CategoryTree,
  Retailer,
  ComparisonRequest,
  ComparisonResult,
  PaginatedResponse,
  PaginationParams,
  SearchParams,
  HealthResponse,
} from '@pareto/types';
import { getApiClient } from './client.js';

// ============================================================================
// Query Keys
// ============================================================================

export const queryKeys = {
  health: ['health'] as const,
  products: {
    all: ['products'] as const,
    list: (params?: SearchParams) => ['products', 'list', params] as const,
    detail: (id: string) => ['products', 'detail', id] as const,
    search: (query: string) => ['products', 'search', query] as const,
  },
  prices: {
    all: ['prices'] as const,
    byProduct: (productId: string) =>
      ['prices', 'byProduct', productId] as const,
    history: (productId: string, retailerId?: string) =>
      ['prices', 'history', productId, retailerId] as const,
  },
  categories: {
    all: ['categories'] as const,
    tree: ['categories', 'tree'] as const,
    detail: (id: string) => ['categories', 'detail', id] as const,
  },
  retailers: {
    all: ['retailers'] as const,
    detail: (id: string) => ['retailers', 'detail', id] as const,
  },
  comparison: {
    result: (request: ComparisonRequest) =>
      ['comparison', 'result', request] as const,
  },
} as const;

// ============================================================================
// Health
// ============================================================================

export function useHealth() {
  return useQuery({
    queryKey: queryKeys.health,
    queryFn: () => getApiClient().get<HealthResponse>('/api/v1/health'),
    staleTime: 30_000,
    refetchInterval: 60_000,
  });
}

// ============================================================================
// Products
// ============================================================================

export function useProducts(params?: SearchParams) {
  return useQuery({
    queryKey: queryKeys.products.list(params),
    queryFn: () =>
      getApiClient().get<PaginatedResponse<ProductWithPrices>>(
        '/api/v1/products',
        params as Record<string, string | number | boolean | undefined>
      ),
  });
}

export function useProduct(id: string) {
  return useQuery({
    queryKey: queryKeys.products.detail(id),
    queryFn: () =>
      getApiClient().get<ProductWithPrices>(`/api/v1/products/${id}`),
    enabled: !!id,
  });
}

export function useProductSearch(query: string, enabled = true) {
  return useQuery({
    queryKey: queryKeys.products.search(query),
    queryFn: () =>
      getApiClient().get<PaginatedResponse<ProductWithPrices>>(
        '/api/v1/products/search',
        { q: query }
      ),
    enabled: enabled && query.length >= 2,
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateProductRequest) =>
      getApiClient().post<Product>('/api/v1/products', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.products.all });
    },
  });
}

export function useUpdateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateProductRequest }) =>
      getApiClient().put<Product>(`/api/v1/products/${id}`, data),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.products.detail(variables.id),
      });
      queryClient.invalidateQueries({ queryKey: queryKeys.products.all });
    },
  });
}

// ============================================================================
// Prices
// ============================================================================

export function usePrices(productId: string) {
  return useQuery({
    queryKey: queryKeys.prices.byProduct(productId),
    queryFn: () =>
      getApiClient().get<Price[]>(`/api/v1/products/${productId}/prices`),
    enabled: !!productId,
  });
}

export function usePriceHistory(productId: string, retailerId?: string) {
  return useQuery({
    queryKey: queryKeys.prices.history(productId, retailerId),
    queryFn: () =>
      getApiClient().get<PriceHistory[]>(
        `/api/v1/products/${productId}/prices/history`,
        { retailerId }
      ),
    enabled: !!productId,
  });
}

// ============================================================================
// Categories
// ============================================================================

export function useCategories(params?: PaginationParams) {
  return useQuery({
    queryKey: queryKeys.categories.all,
    queryFn: () =>
      getApiClient().get<PaginatedResponse<Category>>(
        '/api/v1/categories',
        params as Record<string, string | number | boolean | undefined>
      ),
  });
}

export function useCategoryTree() {
  return useQuery({
    queryKey: queryKeys.categories.tree,
    queryFn: () =>
      getApiClient().get<CategoryTree[]>('/api/v1/categories/tree'),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useCategory(id: string) {
  return useQuery({
    queryKey: queryKeys.categories.detail(id),
    queryFn: () => getApiClient().get<Category>(`/api/v1/categories/${id}`),
    enabled: !!id,
  });
}

// ============================================================================
// Retailers
// ============================================================================

export function useRetailers() {
  return useQuery({
    queryKey: queryKeys.retailers.all,
    queryFn: () =>
      getApiClient().get<PaginatedResponse<Retailer>>('/api/v1/retailers'),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useRetailer(id: string) {
  return useQuery({
    queryKey: queryKeys.retailers.detail(id),
    queryFn: () => getApiClient().get<Retailer>(`/api/v1/retailers/${id}`),
    enabled: !!id,
  });
}

// ============================================================================
// Comparison (Pareto)
// ============================================================================

export function useComparison(request: ComparisonRequest, enabled = true) {
  return useQuery({
    queryKey: queryKeys.comparison.result(request),
    queryFn: () =>
      getApiClient().post<ComparisonResult>('/api/v1/compare', request),
    enabled,
    staleTime: 60_000, // 1 minute
  });
}

export function useComparisonMutation() {
  return useMutation({
    mutationFn: (request: ComparisonRequest) =>
      getApiClient().post<ComparisonResult>('/api/v1/compare', request),
  });
}
