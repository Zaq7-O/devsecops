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

# Install required package (wget) pinned to version
RUN apk add --no-cache wget=1.21.4-r0

# Copy build artifacts
COPY --from=builder /app ./

# Run as non-root
USER nodeuser

# Expose app port
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/db-check || exit 1

# Start app
CMD ["npm", "start"]
 