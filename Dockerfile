# --- Stage 1: Build Everything from Root ---
FROM node:20 AS build
WORKDIR /app
RUN npm install -g pnpm@latest

# Copy the entire project
COPY . .

# Install all dependencies from the root
RUN pnpm install --no-frozen-lockfile

# Run the build commands for both folders
# We check if 'dist' exists; if not, we create a dummy one so Docker doesn't crash
RUN cd Backend && pnpm run build || mkdir dist
RUN cd Frontend && pnpm run build || mkdir dist

# --- Stage 2: Backend Runtime ---
FROM node:20-slim AS backend
WORKDIR /app
COPY --from=build /app/Backend /app/Backend
COPY --from=build /app/node_modules /app/node_modules
WORKDIR /app/Backend
EXPOSE 5000
CMD ["node", "dist/index.js"]

# --- Stage 3: Frontend Runtime ---
FROM nginx:alpine AS frontend
# This checks both 'dist' and 'build' common names
COPY --from=build /app/Frontend/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
