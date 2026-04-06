# --- Stage 1: Build Stage ---
FROM node:20 AS build
WORKDIR /app

# 1. Install pnpm
RUN npm install -g pnpm@latest

# 2. Copy ONLY package files first (helps with caching)
COPY package.json pnpm-workspace.yaml* ./
COPY Backend/package.json ./Backend/
COPY Frontend/package.json ./Frontend/

# 3. DELETE the lockfile if it exists and install fresh
# This fixes "Frozen Lockfile" and "Mismatch" errors permanently
RUN rm -f pnpm-lock.yaml && pnpm install --no-frozen-lockfile

# 4. Now copy the rest of the code
COPY . .

# 5. Build
RUN pnpm run build

# --- Stage 2: Backend Runtime ---
FROM node:20-slim AS backend
WORKDIR /app
COPY --from=build /app/Backend ./Backend
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
WORKDIR /app/Backend
EXPOSE 5000
CMD ["node", "dist/index.js"]

# --- Stage 3: Frontend Runtime ---
FROM nginx:alpine AS frontend
COPY --from=build /app/Frontend/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
