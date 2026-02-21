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

# Install wget for healthcheck
RUN apk add --no-cache wget

# Create non-root user
RUN addgroup -S nodegroup && adduser -S nodeuser -G nodegroup

COPY --from=builder /app ./

ENV NODE_ENV=production

USER nodeuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/db-check || exit 1

CMD ["npm", "start"]
