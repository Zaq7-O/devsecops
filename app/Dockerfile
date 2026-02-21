# Stage 1 - Install dependencies and build
FROM node:20.11.1-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2 - Production image
FROM node:20.11.1-alpine
WORKDIR /app

# Non-root user
RUN addgroup -S nodegroup && adduser -S nodeuser -G nodegroup

# Install curl (pin version to satisfy DL3018)
  # Install curl for HEALTHCHECK
  RUN apk add --no-cache curl

# Copy built app
COPY --from=builder /app ./

# Switch to non-root
USER nodeuser

# Expose port
EXPOSE 3000

# Docker HEALTHCHECK for Checkov CKV_DOCKER_2
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/api/db-check || exit 1

# Start app (JSON form for DL3025)
CMD ["npm", "start"]
