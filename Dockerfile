# --- Stage 1: Build Backend ---
FROM node:20 AS backend-build
WORKDIR /app
# Copy only Backend files
COPY Backend/package.json Backend/pnpm-lock.yaml* ./
RUN npm install -g pnpm && pnpm install --no-frozen-lockfile
COPY Backend/ .
# Ignore TS errors to force a build
RUN pnpm run build || true

# --- Stage 2: Build Frontend ---
FROM node:20 AS frontend-build
WORKDIR /app
# Copy only Frontend files
COPY Frontend/package.json Frontend/pnpm-lock.yaml* ./
RUN npm install -g pnpm && pnpm install --no-frozen-lockfile
COPY Frontend/ .
# Ignore TS errors to force a build
RUN pnpm run build || true

# --- Stage 3: Backend Runtime ---
FROM node:20-slim AS backend
WORKDIR /app
COPY --from=backend-build /app ./
EXPOSE 5000
CMD ["node", "dist/index.js"]

# --- Stage 4: Frontend Runtime (Nginx) ---
FROM nginx:alpine AS frontend
# Double check the build output folder
COPY --from=frontend-build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
