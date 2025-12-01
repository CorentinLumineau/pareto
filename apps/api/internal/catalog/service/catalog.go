package service

import (
	"context"

	"github.com/clumineau/pareto/apps/api/internal/catalog/domain"
	"github.com/clumineau/pareto/apps/api/internal/catalog/repository"
)

// CatalogService provides catalog business logic
type CatalogService struct {
	productRepo  repository.ProductRepository
	offerRepo    repository.OfferRepository
	categoryRepo repository.CategoryRepository
	retailerRepo repository.RetailerRepository
}

// NewCatalogService creates a new catalog service
func NewCatalogService(
	productRepo repository.ProductRepository,
	offerRepo repository.OfferRepository,
	categoryRepo repository.CategoryRepository,
	retailerRepo repository.RetailerRepository,
) *CatalogService {
	return &CatalogService{
		productRepo:  productRepo,
		offerRepo:    offerRepo,
		categoryRepo: categoryRepo,
		retailerRepo: retailerRepo,
	}
}

// GetProduct retrieves a product by ID with offers
func (s *CatalogService) GetProduct(ctx context.Context, id string) (*domain.ProductWithOffers, error) {
	return s.productRepo.GetByID(ctx, id)
}

// GetProductBySlug retrieves a product by slug with offers
func (s *CatalogService) GetProductBySlug(ctx context.Context, slug string) (*domain.ProductWithOffers, error) {
	return s.productRepo.GetBySlug(ctx, slug)
}

// ListProducts retrieves a paginated list of products
func (s *CatalogService) ListProducts(ctx context.Context, params repository.ListParams) (*repository.PaginatedResult[domain.ProductWithOffers], error) {
	return s.productRepo.List(ctx, params)
}

// SearchProducts searches for products by query
func (s *CatalogService) SearchProducts(ctx context.Context, query string, params repository.ListParams) (*repository.PaginatedResult[domain.ProductWithOffers], error) {
	return s.productRepo.Search(ctx, query, params)
}

// CreateProduct creates a new product
func (s *CatalogService) CreateProduct(ctx context.Context, req *domain.CreateProductRequest) (*domain.Product, error) {
	return s.productRepo.Create(ctx, req)
}

// UpdateProduct updates an existing product
func (s *CatalogService) UpdateProduct(ctx context.Context, id string, req *domain.UpdateProductRequest) (*domain.Product, error) {
	return s.productRepo.Update(ctx, id, req)
}

// DeleteProduct deletes a product
func (s *CatalogService) DeleteProduct(ctx context.Context, id string) error {
	return s.productRepo.Delete(ctx, id)
}

// GetOffers retrieves all offers for a product
func (s *CatalogService) GetOffers(ctx context.Context, productID string) ([]domain.Offer, error) {
	return s.offerRepo.GetByProductID(ctx, productID)
}

// GetPriceHistory retrieves price history for a product
func (s *CatalogService) GetPriceHistory(ctx context.Context, productID string, retailerID *string) ([]domain.PriceHistory, error) {
	return s.offerRepo.GetHistory(ctx, productID, retailerID)
}

// GetCategory retrieves a category by ID
func (s *CatalogService) GetCategory(ctx context.Context, id string) (*domain.Category, error) {
	return s.categoryRepo.GetByID(ctx, id)
}

// ListCategories retrieves a paginated list of categories
func (s *CatalogService) ListCategories(ctx context.Context, params repository.ListParams) (*repository.PaginatedResult[domain.Category], error) {
	return s.categoryRepo.List(ctx, params)
}

// GetCategoryTree retrieves the category tree
func (s *CatalogService) GetCategoryTree(ctx context.Context) ([]repository.CategoryNode, error) {
	return s.categoryRepo.GetTree(ctx)
}

// GetRetailer retrieves a retailer by ID
func (s *CatalogService) GetRetailer(ctx context.Context, id string) (*domain.Retailer, error) {
	return s.retailerRepo.GetByID(ctx, id)
}

// ListRetailers retrieves a paginated list of retailers
func (s *CatalogService) ListRetailers(ctx context.Context, params repository.ListParams) (*repository.PaginatedResult[domain.Retailer], error) {
	return s.retailerRepo.List(ctx, params)
}

// GetActiveRetailers retrieves all active retailers
func (s *CatalogService) GetActiveRetailers(ctx context.Context) ([]domain.Retailer, error) {
	return s.retailerRepo.GetActive(ctx)
}
