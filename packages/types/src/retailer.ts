/**
 * Retailer entity representing a store/merchant
 */
export interface Retailer {
  id: string;
  name: string;
  slug: string;
  websiteUrl: string;
  logoUrl: string | null;
  affiliateNetwork: AffiliateNetwork | null;
  affiliateId: string | null;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Supported affiliate networks
 */
export type AffiliateNetwork =
  | 'amazon_associates'
  | 'awin'
  | 'effinity'
  | 'tradedoubler'
  | 'direct';

/**
 * Retailer configuration for scraping
 */
export interface RetailerConfig {
  scraperType: ScraperType;
  searchUrl: string;
  productUrlPattern: string;
  headers?: Record<string, string>;
  rateLimit: number;
  proxyRequired: boolean;
}

/**
 * Scraper type for retailer
 */
export type ScraperType =
  | 'amazon'
  | 'fnac'
  | 'cdiscount'
  | 'darty'
  | 'boulanger'
  | 'ldlc';

/**
 * Create retailer request
 */
export interface CreateRetailerRequest {
  name: string;
  websiteUrl: string;
  logoUrl?: string;
  affiliateNetwork?: AffiliateNetwork;
  affiliateId?: string;
}
