package handler

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/clumineau/pareto/apps/api/internal/shared/cache"
	"github.com/clumineau/pareto/apps/api/internal/shared/database"
)

// NewRouter creates a new comparison router
func NewRouter(db *database.DB, redis *cache.Client) http.Handler {
	r := chi.NewRouter()

	h := &CompareHandler{db: db, cache: redis}

	r.Post("/", h.Compare)

	return r
}

// CompareHandler handles comparison requests
type CompareHandler struct {
	db    *database.DB
	cache *cache.Client
}

// ComparisonRequest represents a comparison request
type ComparisonRequest struct {
	CategoryID string              `json:"categoryId"`
	Criteria   []ComparisonCriterion `json:"criteria"`
	Filters    *ComparisonFilters  `json:"filters,omitempty"`
	Limit      int                 `json:"limit,omitempty"`
}

// ComparisonCriterion represents a comparison criterion
type ComparisonCriterion struct {
	Attribute string  `json:"attribute"`
	Weight    float64 `json:"weight"`
	Direction string  `json:"direction"`
}

// ComparisonFilters represents comparison filters
type ComparisonFilters struct {
	MinPrice    *float64 `json:"minPrice,omitempty"`
	MaxPrice    *float64 `json:"maxPrice,omitempty"`
	Retailers   []string `json:"retailers,omitempty"`
	Brands      []string `json:"brands,omitempty"`
	InStockOnly bool     `json:"inStockOnly,omitempty"`
}

// Compare performs Pareto comparison
func (h *CompareHandler) Compare(w http.ResponseWriter, r *http.Request) {
	var req ComparisonRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate request
	if req.CategoryID == "" {
		respondError(w, http.StatusBadRequest, "categoryId is required")
		return
	}
	if len(req.Criteria) == 0 {
		respondError(w, http.StatusBadRequest, "At least one criterion is required")
		return
	}

	// TODO: Implement Pareto comparison with Python workers via Redis queue
	// For now, return a placeholder response
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"criteria":       req.Criteria,
		"paretoFrontier": []interface{}{},
		"dominated":      []interface{}{},
		"totalProducts":  0,
		"computedAt":     "2025-12-01T00:00:00Z",
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
