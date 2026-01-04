# Stage 1: Base dependencies
FROM node:20-alpine AS base
RUN corepack enable && corepack prepare pnpm@8.15.1 --activate
WORKDIR /app

# Stage 2: Install dependencies
FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/client/package.json ./apps/client/
COPY packages/shared/package.json ./packages/shared/
RUN pnpm install --frozen-lockfile --ignore-scripts

# Stage 3: Build
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/client/node_modules ./apps/client/node_modules
COPY --from=deps /app/packages/shared/node_modules ./packages/shared/node_modules
COPY . .
RUN pnpm --filter @repo/client build

# Stage 4: Production runtime with Nginx
FROM nginx:1.25-alpine AS runtime

# Copy built assets
COPY --from=build /app/apps/client/dist /usr/share/nginx/html

# Copy custom Nginx config
COPY apps/client/deployment/production/nginx.conf /etc/nginx/conf.d/default.conf

# Setup permissions for nginx user (already exists in base image)
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
