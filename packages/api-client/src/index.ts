// Client
export {
  createApiClient,
  initApiClient,
  getApiClient,
  ApiClientError,
  type ApiClientConfig,
} from './client.js';

// Hooks
export {
  queryKeys,
  useHealth,
  useProducts,
  useProduct,
  useProductSearch,
  useCreateProduct,
  useUpdateProduct,
  usePrices,
  usePriceHistory,
  useCategories,
  useCategoryTree,
  useCategory,
  useRetailers,
  useRetailer,
  useComparison,
  useComparisonMutation,
} from './hooks.js';

// Re-export types for convenience
export type {
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
  ParetoProduct,
  ParetoChartData,
  ApiResponse,
  ApiError,
  PaginatedResponse,
  PaginationParams,
  SearchParams,
  HealthResponse,
} from '@pareto/types';
