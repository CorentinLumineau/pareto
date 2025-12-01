/**
 * Category entity for product categorization
 */
export interface Category {
  id: string;
  name: string;
  slug: string;
  parentId: string | null;
  attributeSchema: AttributeSchema;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Schema defining category-specific attributes
 */
export interface AttributeSchema {
  attributes: AttributeDefinition[];
}

/**
 * Definition of a single attribute
 */
export interface AttributeDefinition {
  key: string;
  name: string;
  type: AttributeType;
  required: boolean;
  options?: string[];
  unit?: string;
  paretoOptimizable: boolean;
  optimizationDirection?: 'maximize' | 'minimize';
}

/**
 * Attribute value types
 */
export type AttributeType = 'string' | 'number' | 'boolean' | 'enum';

/**
 * Category tree node for navigation
 */
export interface CategoryTree extends Category {
  children: CategoryTree[];
  productCount: number;
}

/**
 * Create category request
 */
export interface CreateCategoryRequest {
  name: string;
  parentId?: string;
  attributeSchema?: AttributeSchema;
}
