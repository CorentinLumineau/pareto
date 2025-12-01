package repository

import (
	"context"

	"github.com/clumineau/pareto/apps/api/internal/catalog/domain"
)

// ProductRepository defines the interface for product data access
type ProductRepository interface {
	// Products
	GetByID(ctx context.Context, id string) (*domain.ProductWithPrices, error)
	GetBySlug(ctx context.Context, slug string) (*domain.ProductWithPrices, error)
	List(ctx context.Context, params ListParams) (*PaginatedResult[domain.ProductWithPrices], error)
	Search(ctx context.Context, query string, params ListParams) (*PaginatedResult[domain.ProductWithPrices], error)
	Create(ctx context.Context, req *domain.CreateProductRequest) (*domain.Product, error)
	Update(ctx context.Context, id string, req *domain.UpdateProductRequest) (*domain.Product, error)
	Delete(ctx context.Context, id string) error
}

// PriceRepository defines the interface for price data access
type PriceRepository interface {
	GetByProductID(ctx context.Context, productID string) ([]domain.Price, error)
	GetHistory(ctx context.Context, productID string, retailerID *string) ([]PriceHistory, error)
	Upsert(ctx context.Context, price *domain.Price) error
}

// CategoryRepository defines the interface for category data access
type CategoryRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Category, error)
	GetBySlug(ctx context.Context, slug string) (*domain.Category, error)
	List(ctx context.Context, params ListParams) (*PaginatedResult[domain.Category], error)
	GetTree(ctx context.Context) ([]CategoryNode, error)
}

// RetailerRepository defines the interface for retailer data access
type RetailerRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Retailer, error)
	GetBySlug(ctx context.Context, slug string) (*domain.Retailer, error)
	List(ctx context.Context, params ListParams) (*PaginatedResult[domain.Retailer], error)
	GetActive(ctx context.Context) ([]domain.Retailer, error)
}

// ListParams defines common list parameters
type ListParams struct {
	Page      int
	PerPage   int
	SortBy    string
	SortOrder string
	Filters   map[string]interface{}
}

// PaginatedResult wraps paginated data
type PaginatedResult[T any] struct {
	Items      []T  `json:"items"`
	Page       int  `json:"page"`
	PerPage    int  `json:"perPage"`
	Total      int  `json:"total"`
	TotalPages int  `json:"totalPages"`
}

// PriceHistory represents price history data
type PriceHistory struct {
	Timestamp string   `json:"timestamp"`
	Price     float64  `json:"price"`
	Shipping  *float64 `json:"shipping,omitempty"`
	InStock   bool     `json:"inStock"`
}

// CategoryNode represents a category in a tree structure
type CategoryNode struct {
	domain.Category
	Children     []CategoryNode `json:"children"`
	ProductCount int            `json:"productCount"`
}
