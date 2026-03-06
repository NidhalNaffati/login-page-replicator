# Stage 1: Build
FROM oven/bun:1 AS builder
WORKDIR /app

# Copy dependency files first for better layer caching
COPY package.json bun.lockb ./

# Install dependencies (uses bun.lockb lockfile)
RUN bun install --frozen-lockfile

# Copy the rest of the source code
COPY . .

# Build the app for production
RUN bun run build

# Stage 2: Serve with Nginx
FROM nginx:alpine AS runner

# Copy built assets from the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Use our custom nginx config (supports React Router client-side routing)
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]


