# Use the official Playwright image — includes all browser binaries.
# We install Bun manually because the project uses bun.lock (not package-lock.json).
FROM mcr.microsoft.com/playwright:v1.58.2-jammy

# Install Bun (requires unzip, which is not in the base image)
RUN apt-get update && apt-get install -y --no-install-recommends unzip && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

WORKDIR /tests

# Copy dependency manifests first for layer caching
COPY package.json bun.lock ./

# Install deps with frozen lockfile (reproducible)
RUN bun install --frozen-lockfile

# Copy test files
COPY playwright.config.ts playwright-fixture.ts ./
COPY tests/ ./tests/

# BASE_URL is overridden at runtime by the k8s Job env var
ENV BASE_URL=http://login-page-replicator.app.svc.cluster.local
ENV CI=true

CMD ["bun", "x", "playwright", "test", "--reporter=line"]
