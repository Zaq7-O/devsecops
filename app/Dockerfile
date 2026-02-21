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
RUN addgroup -S nodegroup && adduser -S nodeuser -G nodegroup
COPY --from=builder /app ./
USER nodeuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --spider http://localhost:3000/ || exit 1
CMD ["npm", "start"]