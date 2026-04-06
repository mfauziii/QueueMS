# --- Stage 1: Base image using the official pnpm image ---
FROM node:20-slim AS base
RUN npm install -g pnpm@latest
WORKDIR /app
COPY . .

# --- Stage 2: Install dependencies and build ---
FROM base AS build
# We use --no-frozen-lockfile to ignore minor version mismatches
RUN pnpm install --no-frozen-lockfile
RUN pnpm run build

# --- Stage 3: Backend Runtime ---
FROM node:20-slim AS backend
WORKDIR /app
COPY --from=build /app/Backend ./Backend
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
WORKDIR /app/Backend
EXPOSE 5000
CMD ["node", "dist/index.js"]

# --- Stage 4: Frontend Runtime (Nginx) ---
FROM nginx:alpine AS frontend
# The 'dist' folder is usually inside Frontend/dist after pnpm run build
COPY --from=build /app/Frontend/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
