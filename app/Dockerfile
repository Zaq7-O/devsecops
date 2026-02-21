# Stage 1 - Install dependencies and build
FROM node:20.11.1-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2 - Production image, run as non-root
FROM node:20.11.1-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -S nodegroup && adduser -S nodeuser -G nodegroup

# Install curl for healthcheck (pin version to satisfy Hadolint)
RUN apk add --no-cache curl=8.2.1-r0

# Copy app from builder stage
COPY --from=builder /app ./

# Run as non-root
USER nodeuser

# Expose port
EXPOSE 3000

# Add a proper HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/api/db-check || exit 1

# Start the app
CMD ["npm", "start"]
