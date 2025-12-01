import { z } from 'zod';

/**
 * UUID v7 validation (used by PostgreSQL 18)
 */
export const uuidSchema = z.string().uuid();

/**
 * Slug validation
 */
export const slugSchema = z
  .string()
  .min(1)
  .max(255)
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'Invalid slug format');

/**
 * GTIN (EAN/UPC) validation
 */
export const gtinSchema = z
  .string()
  .regex(/^\d{8,14}$/, 'GTIN must be 8-14 digits');

/**
 * Product attributes schema
 */
export const productAttributesSchema = z.record(
  z.string(),
  z.union([z.string(), z.number(), z.boolean()])
);

/**
 * Create product request schema
 */
export const createProductSchema = z.object({
  name: z.string().min(1).max(500),
  gtin: gtinSchema.optional(),
  categoryId: uuidSchema,
  brandId: uuidSchema.optional(),
  attributes: productAttributesSchema.optional(),
});

/**
 * Update product request schema
 */
export const updateProductSchema = z.object({
  name: z.string().min(1).max(500).optional(),
  gtin: gtinSchema.optional(),
  categoryId: uuidSchema.optional(),
  brandId: uuidSchema.optional(),
  attributes: productAttributesSchema.optional(),
});

/**
 * Create price request schema
 */
export const createPriceSchema = z.object({
  productId: uuidSchema,
  retailerId: uuidSchema,
  price: z.number().positive(),
  shipping: z.number().nonnegative().optional(),
  inStock: z.boolean(),
  affiliateUrl: z.string().url(),
});

/**
 * Comparison criterion schema
 */
export const comparisonCriterionSchema = z.object({
  attribute: z.string(),
  weight: z.number().min(0).max(1),
  direction: z.enum(['minimize', 'maximize']),
});

/**
 * Comparison filters schema
 */
export const comparisonFiltersSchema = z.object({
  minPrice: z.number().nonnegative().optional(),
  maxPrice: z.number().positive().optional(),
  retailers: z.array(uuidSchema).optional(),
  brands: z.array(uuidSchema).optional(),
  inStockOnly: z.boolean().optional(),
  attributes: z.record(z.string(), z.union([z.string(), z.number(), z.boolean()])).optional(),
});

/**
 * Comparison request schema
 */
export const comparisonRequestSchema = z.object({
  categoryId: uuidSchema,
  criteria: z.array(comparisonCriterionSchema).min(1).max(10),
  filters: comparisonFiltersSchema.optional(),
  limit: z.number().int().min(1).max(100).optional(),
});

/**
 * Pagination params schema
 */
export const paginationParamsSchema = z.object({
  page: z.coerce.number().int().min(1).optional().default(1),
  perPage: z.coerce.number().int().min(1).max(100).optional().default(20),
  sortBy: z.string().optional(),
  sortOrder: z.enum(['asc', 'desc']).optional().default('asc'),
});

/**
 * Search params schema
 */
export const searchParamsSchema = paginationParamsSchema.extend({
  query: z.string().optional(),
  filters: z.record(z.string(), z.union([z.string(), z.number(), z.boolean(), z.array(z.string())])).optional(),
});

// Export types
export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
export type CreatePriceInput = z.infer<typeof createPriceSchema>;
export type ComparisonCriterionInput = z.infer<typeof comparisonCriterionSchema>;
export type ComparisonFiltersInput = z.infer<typeof comparisonFiltersSchema>;
export type ComparisonRequestInput = z.infer<typeof comparisonRequestSchema>;
export type PaginationParamsInput = z.infer<typeof paginationParamsSchema>;
export type SearchParamsInput = z.infer<typeof searchParamsSchema>;
