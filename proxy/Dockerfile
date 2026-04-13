# Build stage
FROM golang:1.23-bookworm AS builder

RUN apt-get update && apt-get install -y \
    libvips-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/proxy \
    ./cmd/proxy

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libvips42 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/proxy /proxy

EXPOSE 8080

ENTRYPOINT ["/proxy"]
