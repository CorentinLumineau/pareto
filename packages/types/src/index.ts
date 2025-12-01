// Product types
export type {
  Product,
  ProductAttributes,
  CreateProductRequest,
  UpdateProductRequest,
  ProductWithPrices,
} from './product.js';

// Price types
export type {
  Price,
  PriceHistory,
  CreatePriceRequest,
  PriceWithRetailer,
} from './price.js';

// Retailer types
export type {
  Retailer,
  AffiliateNetwork,
  RetailerConfig,
  ScraperType,
  CreateRetailerRequest,
} from './retailer.js';

// Category types
export type {
  Category,
  AttributeSchema,
  AttributeDefinition,
  AttributeType,
  CategoryTree,
  CreateCategoryRequest,
} from './category.js';

// Comparison types
export type {
  ComparisonRequest,
  ComparisonCriterion,
  ComparisonFilters,
  ComparisonResult,
  ParetoProduct,
  NormalizedScores,
  ParetoPoint,
  ParetoChartData,
} from './comparison.js';

// API types
export type {
  ApiResponse,
  ApiError,
  ApiMeta,
  PaginatedResponse,
  PaginationParams,
  SearchParams,
  HealthResponse,
} from './api.js';
