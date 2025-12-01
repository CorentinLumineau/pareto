package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"

	"github.com/clumineau/pareto/apps/api/internal/shared/cache"
	"github.com/clumineau/pareto/apps/api/internal/shared/database"
)

// NewRouter creates a new product router
func NewRouter(db *database.DB, redis *cache.Client) http.Handler {
	r := chi.NewRouter()

	h := &ProductHandler{db: db, cache: redis}

	r.Get("/", h.List)
	r.Post("/", h.Create)
	r.Get("/search", h.Search)
	r.Get("/{id}", h.GetByID)
	r.Put("/{id}", h.Update)
	r.Delete("/{id}", h.Delete)
	r.Get("/{id}/prices", h.GetPrices)
	r.Get("/{id}/prices/history", h.GetPriceHistory)

	return r
}

// ProductHandler handles product requests
type ProductHandler struct {
	db    *database.DB
	cache *cache.Client
}

// List returns a paginated list of products
func (h *ProductHandler) List(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement with repository
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"items":      []interface{}{},
		"page":       1,
		"perPage":    20,
		"total":      0,
		"totalPages": 0,
	})
}

// GetByID returns a product by ID
func (h *ProductHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	// TODO: Implement with repository
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"id":   id,
		"name": "Sample Product",
	})
}

// Search searches for products
func (h *ProductHandler) Search(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")

	// TODO: Implement with repository
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"query":      query,
		"items":      []interface{}{},
		"page":       1,
		"perPage":    20,
		"total":      0,
		"totalPages": 0,
	})
}

// Create creates a new product
func (h *ProductHandler) Create(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement with repository
	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"id":      "new-id",
		"message": "Product created",
	})
}

// Update updates an existing product
func (h *ProductHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	// TODO: Implement with repository
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"id":      id,
		"message": "Product updated",
	})
}

// Delete deletes a product
func (h *ProductHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	// TODO: Implement with repository
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"id":      id,
		"message": "Product deleted",
	})
}

// GetPrices returns prices for a product
func (h *ProductHandler) GetPrices(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	// TODO: Implement with repository
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"productId": id,
		"prices":    []interface{}{},
	})
}

// GetPriceHistory returns price history for a product
func (h *ProductHandler) GetPriceHistory(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	retailerID := r.URL.Query().Get("retailerId")

	// TODO: Implement with repository
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"productId":  id,
		"retailerId": retailerID,
		"history":    []interface{}{},
	})
}

// NewCategoryRouter creates a new category router
func NewCategoryRouter(db *database.DB) http.Handler {
	r := chi.NewRouter()

	h := &CategoryHandler{db: db}

	r.Get("/", h.List)
	r.Get("/tree", h.GetTree)
	r.Get("/{id}", h.GetByID)

	return r
}

// CategoryHandler handles category requests
type CategoryHandler struct {
	db *database.DB
}

// List returns a paginated list of categories
func (h *CategoryHandler) List(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"items":      []interface{}{},
		"page":       1,
		"perPage":    20,
		"total":      0,
		"totalPages": 0,
	})
}

// GetByID returns a category by ID
func (h *CategoryHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"id":   id,
		"name": "Sample Category",
	})
}

// GetTree returns the category tree
func (h *CategoryHandler) GetTree(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, []interface{}{})
}

// NewRetailerRouter creates a new retailer router
func NewRetailerRouter(db *database.DB) http.Handler {
	r := chi.NewRouter()

	h := &RetailerHandler{db: db}

	r.Get("/", h.List)
	r.Get("/{id}", h.GetByID)

	return r
}

// RetailerHandler handles retailer requests
type RetailerHandler struct {
	db *database.DB
}

// List returns a paginated list of retailers
func (h *RetailerHandler) List(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"items":      []interface{}{},
		"page":       1,
		"perPage":    20,
		"total":      0,
		"totalPages": 0,
	})
}

// GetByID returns a retailer by ID
func (h *RetailerHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"id":   id,
		"name": "Sample Retailer",
	})
}

// Helper functions

func respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data":    data,
	})
}

func respondError(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": false,
		"error": map[string]string{
			"message": message,
		},
	})
}

func getIntParam(r *http.Request, key string, defaultVal int) int {
	val := r.URL.Query().Get(key)
	if val == "" {
		return defaultVal
	}
	i, err := strconv.Atoi(val)
	if err != nil {
		return defaultVal
	}
	return i
}
