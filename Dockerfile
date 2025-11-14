# --------- 1. Builder stage ---------
FROM node:22-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++ git

WORKDIR /app

# Copy everything (including patches directory)
COPY . .

# Enable pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install dependencies (this will apply patches automatically)
RUN pnpm install --force

# Build the application
RUN pnpm build

# --------- 2. Runtime stage ---------
FROM node:22-alpine

# Install runtime dependencies
RUN apk add --no-cache su-exec git

# Create n8n user and directories
RUN addgroup -g 1000 n8n && \
    adduser -D -u 1000 -G n8n -h /home/n8n n8n && \
    mkdir -p /home/n8n/.n8n && \
    chown -R n8n:n8n /home/n8n

USER n8n
WORKDIR /home/n8n

# Copy entire built application from builder (including node_modules)
COPY --chown=n8n:n8n --from=builder /app ./app

WORKDIR /home/n8n/app

# Enable pnpm in runtime
RUN corepack enable && corepack prepare pnpm@latest --activate

# Set environment variables
ENV N8N_PORT=5678 \
    N8N_HOST=0.0.0.0 \
    NODE_ENV=production \
    N8N_USER_FOLDER=/home/n8n/.n8n \
    EXECUTIONS_PROCESS=main

EXPOSE 5678

# Start n8n
CMD ["pnpm", "start"]
