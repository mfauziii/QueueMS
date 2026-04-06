# --- Stage 1: Base image with pnpm ---
FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
WORKDIR /app
COPY . .

# --- Stage 2: Install dependencies and build ---
FROM base AS build
RUN pnpm install --frozen-lockfile
RUN pnpm run build

# --- Stage 3: Backend Runtime ---
FROM base AS backend
COPY --from=build /app/Backend /app/Backend
COPY --from=build /app/node_modules /app/node_modules
WORKDIR /app/Backend
EXPOSE 5000
CMD ["node", "dist/index.js"]

# --- Stage 4: Frontend Runtime (Nginx) ---
FROM nginx:alpine AS frontend
# Copy built static files from the build stage to Nginx
COPY --from=build /app/Frontend/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
