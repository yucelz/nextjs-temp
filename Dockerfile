# -------- Base Stage --------
# Using official Node.js image as the base
FROM node:18-alpine AS base

# Set the working directory inside the container
WORKDIR /app

# Install dependencies for the base image
COPY package*.json ./

# Install dependencies (for both dev and prod)
RUN npm install

# Copy the rest of the app's source code
COPY . .

# Expose the port used by the Next.js server
EXPOSE 3000

# -------- Development Stage --------
# For development, we use the base image and add dev-specific dependencies
FROM base AS development

# Install additional dev dependencies
RUN npm install --only=dev

# Start Next.js in development mode
CMD ["npm", "run", "dev"]

# -------- Production Stage --------
# Build the production app
FROM base AS build

# Set environment variable to production
ENV NODE_ENV=production

# Run the build script to create optimized production build
RUN npm run build

# -------- Production Final Stage --------
# Create a minimal production image
FROM node:18-alpine AS production

# Set the working directory in the new image
WORKDIR /app

# Install only production dependencies
COPY package*.json ./
RUN npm install --only=production

# Copy the built app from the build stage
COPY --from=build /app/.next ./.next
#COPY --from=build /app/public ./public
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json

# Expose port for Next.js app
EXPOSE 3000

# Start Next.js in production mode
CMD ["npm", "start"]
