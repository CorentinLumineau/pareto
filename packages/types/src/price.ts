/**
 * Price entity representing a product price from a retailer
 */
export interface Price {
  id: string;
  productId: string;
  retailerId: string;
  price: number;
  shipping: number | null;
  totalPrice: number;
  inStock: boolean;
  affiliateUrl: string;
  scrapedAt: Date;
  createdAt: Date;
}

/**
 * Price history entry for time-series data
 */
export interface PriceHistory {
  timestamp: Date;
  price: number;
  shipping: number | null;
  inStock: boolean;
}

/**
 * Create price request
 */
export interface CreatePriceRequest {
  productId: string;
  retailerId: string;
  price: number;
  shipping?: number;
  inStock: boolean;
  affiliateUrl: string;
}

/**
 * Price with retailer details
 */
export interface PriceWithRetailer extends Price {
  retailer: Retailer;
}

// Forward declaration
import type { Retailer } from './retailer.js';
