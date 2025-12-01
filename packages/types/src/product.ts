/**
 * Product entity representing a smartphone or other product
 */
export interface Product {
  id: string;
  slug: string;
  name: string;
  gtin: string | null;
  categoryId: string;
  brandId: string | null;
  attributes: ProductAttributes;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Product attributes for smartphones
 */
export interface ProductAttributes {
  brand?: string;
  model?: string;
  storage?: string;
  ram?: string;
  screenSize?: string;
  batteryCapacity?: string;
  camera?: string;
  color?: string;
  [key: string]: string | number | boolean | undefined;
}

/**
 * Create product request
 */
export interface CreateProductRequest {
  name: string;
  gtin?: string;
  categoryId: string;
  brandId?: string;
  attributes?: ProductAttributes;
}

/**
 * Update product request
 */
export interface UpdateProductRequest {
  name?: string;
  gtin?: string;
  categoryId?: string;
  brandId?: string;
  attributes?: ProductAttributes;
}

/**
 * Product with prices aggregated
 */
export interface ProductWithPrices extends Product {
  prices: Price[];
  bestPrice: number | null;
  priceCount: number;
}

// Forward declaration for circular reference
import type { Price } from './price.js';
