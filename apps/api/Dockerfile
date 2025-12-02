# Build stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git ca-certificates

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/bin/api ./cmd/api

# Runtime stage
FROM alpine:3.22

WORKDIR /app

# Install CA certificates for HTTPS
RUN apk add --no-cache ca-certificates

# Copy binary
COPY --from=builder /app/bin/api /app/api

# Create non-root user
RUN adduser -D -H -h /app appuser
USER appuser

EXPOSE 8080

CMD ["/app/api"]
