# ---- Build Stage ----
FROM node:20-alpine AS builder

# Install build dependencies for sharp (uses prebuilt libvips on alpine)
RUN apk add --no-cache python3 make g++

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY tsconfig.json ./
COPY src/ ./src/

RUN npm run build

# ---- Runtime Stage ----
FROM node:20-alpine AS runtime

# Sharp requires libvips at runtime; the npm package bundles prebuilt binaries
# for linux-x64/arm64 musl, but we need the shared libs for font/image support
RUN apk add --no-cache \
    vips \
    vips-heif \
    fontconfig \
    freetype

WORKDIR /app

# Copy only production dependencies
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

# Copy compiled JS from build stage
COPY --from=builder /app/dist ./dist

# Cloud Run Jobs use PORT env but we don't serve HTTP; this is the job entrypoint
ENV NODE_ENV=production

# Run as non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

CMD ["node", "dist/index.js"]
