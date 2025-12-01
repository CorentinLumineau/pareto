// Formatting utilities
export {
  formatPrice,
  formatPriceRange,
  formatDate,
  formatDateTime,
  formatRelativeTime,
  formatPercentage,
  formatNumber,
  slugify,
  truncate,
} from './format.js';

// Validation schemas
export {
  uuidSchema,
  slugSchema,
  gtinSchema,
  productAttributesSchema,
  createProductSchema,
  updateProductSchema,
  createPriceSchema,
  comparisonCriterionSchema,
  comparisonFiltersSchema,
  comparisonRequestSchema,
  paginationParamsSchema,
  searchParamsSchema,
  type CreateProductInput,
  type UpdateProductInput,
  type CreatePriceInput,
  type ComparisonCriterionInput,
  type ComparisonFiltersInput,
  type ComparisonRequestInput,
  type PaginationParamsInput,
  type SearchParamsInput,
} from './validation.js';

// Pareto utilities
export {
  isDominated,
  isParetoOptimal,
  findParetoFrontier,
  zScoreNormalize,
  minMaxNormalize,
  mean,
  stdDev,
  normalizeScores,
  calculateWeightedScore,
} from './pareto.js';
