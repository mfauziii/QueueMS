# --- Stage 1: Build Backend ---
FROM node:20 AS backend-build
WORKDIR /app
COPY Backend/package.json Backend/pnpm-lock.yaml* ./
RUN npm install -g pnpm && pnpm install
COPY Backend/ .
RUN pnpm run build

# --- Stage 2: Build Frontend ---
FROM node:20 AS frontend-build
WORKDIR /app
COPY Frontend/package.json Frontend/pnpm-lock.yaml* ./
RUN npm install -g pnpm && pnpm install
COPY Frontend/ .
RUN pnpm run build

# --- Stage 3: Backend Runtime ---
FROM node:20-slim AS backend
WORKDIR /app
COPY --from=backend-build /app ./
EXPOSE 5000
CMD ["node", "dist/index.js"]

# --- Stage 4: Frontend Runtime (Nginx) ---
FROM nginx:alpine AS frontend
# The build output is usually in 'dist' or 'build'
COPY --from=frontend-build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
