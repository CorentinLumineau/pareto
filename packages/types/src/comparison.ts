import type { Product, ProductAttributes } from './product.js';
import type { PriceWithRetailer } from './price.js';

/**
 * Request to compare products
 */
export interface ComparisonRequest {
  categoryId: string;
  criteria: ComparisonCriterion[];
  filters?: ComparisonFilters;
  limit?: number;
}

/**
 * Criterion for Pareto optimization
 */
export interface ComparisonCriterion {
  attribute: keyof ProductAttributes | 'price';
  weight: number;
  direction: 'minimize' | 'maximize';
}

/**
 * Filters for comparison
 */
export interface ComparisonFilters {
  minPrice?: number;
  maxPrice?: number;
  retailers?: string[];
  brands?: string[];
  inStockOnly?: boolean;
  attributes?: Record<string, string | number | boolean>;
}

/**
 * Result of Pareto comparison
 */
export interface ComparisonResult {
  criteria: ComparisonCriterion[];
  paretoFrontier: ParetoProduct[];
  dominated: ParetoProduct[];
  totalProducts: number;
  computedAt: Date;
}

/**
 * Product with Pareto ranking
 */
export interface ParetoProduct {
  product: Product;
  bestPrice: PriceWithRetailer | null;
  normalizedScores: NormalizedScores;
  paretoOptimal: boolean;
  dominatedBy: string[];
  rank: number;
}

/**
 * Normalized scores for comparison
 */
export interface NormalizedScores {
  [attribute: string]: number;
}

/**
 * Pareto frontier point for visualization
 */
export interface ParetoPoint {
  productId: string;
  productName: string;
  x: number;
  y: number;
  xLabel: string;
  yLabel: string;
  paretoOptimal: boolean;
}

/**
 * Chart data for Pareto visualization
 */
export interface ParetoChartData {
  points: ParetoPoint[];
  frontierLine: ParetoPoint[];
  xAxis: {
    label: string;
    min: number;
    max: number;
  };
  yAxis: {
    label: string;
    min: number;
    max: number;
  };
}
