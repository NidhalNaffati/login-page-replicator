# ⚠️  SECURITY DEMO — INTENTIONALLY VULNERABLE (for Trivy scan showcase) ⚠️

# Stage 1: Build
FROM oven/bun:1 AS builder
WORKDIR /app

# Copy dependency files first for better layer caching
COPY package.json bun.lock ./

# Install dependencies (uses bun.lockb lockfile)
RUN bun install

# Copy the rest of the source code
COPY . .

# Build the app for production
RUN bun run build

# Stage 2: Serve with Nginx
# VULN: Using an outdated nginx base image with known CVEs (instead of nginx:alpine)
FROM nginx:1.21 AS runner

# VULN: Hardcoded secrets baked into the image layer (Trivy secret scan)
ENV APP_SECRET=supersecretpassword123
ENV DB_PASSWORD=admin123
ENV JWT_SECRET=mysupersecretjwtkey2024

# VULN: Copying .env file with secrets into the image (Trivy secret scan)
COPY .env /app/.env

# Copy built assets from the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Use our custom nginx config (supports React Router client-side routing)
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# VULN: No USER directive — container runs as root (Trivy misconfig DS002)
# VULN: No HEALTHCHECK defined (Trivy misconfig DS026)

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]


