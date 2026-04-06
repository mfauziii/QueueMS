# --- Stage 1: Use full Node image (includes build tools) ---
FROM node:20 AS build
WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm@latest

# Copy everything
COPY . .

# Install dependencies - we use --force to bypass strict peer dependency conflicts
RUN pnpm install --no-frozen-lockfile --force

# Run the build command
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

# --- Stage 3: Frontend Runtime (Nginx) ---
FROM nginx:alpine AS frontend
# Double check the build path: usually 'Frontend/dist' or 'Frontend/build'
COPY --from=build /app/Frontend/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
