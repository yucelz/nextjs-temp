# Use the specified Python slim image as the base
FROM python:3.11.10-slim-bookworm AS base

# Set environment variables to ensure pip installs to the virtual environment
ENV PATH="/root/.local/bin:${PATH}"

# Install required packages for pipx and virtual environment
RUN apt-get update && \
    apt-get install -y \
    curl \
    gcc \
    build-essential \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pipx using pip
#RUN pip install --no-cache-dir pipx

# Ensure pipx's binary directory is in the PATH
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app
# Install virtualenv using pipx
RUN python -m pip install aider-chat


# Create a virtual environment as an example
#RUN python -m venv /env


#RUN pipx install aider-chat

# Set the working directory


############ NODE INSTALLATION ############
# Install curl and other required packages
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify installation
#RUN node -v && npm -v
############ NODE PROJECT CONFIG ############
# -------- Base Stage --------
# Using official Node.js image as the base

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
#FROM node:18-alpine AS production
FROM base AS production

# Set the working directory in the new image
WORKDIR /app

# Install only production dependencies
COPY package*.json ./
RUN npm install --only=production

# Copy the built app from the build stage
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json

ENV HOSTNAME="0.0.0.0"
# Expose port for Next.js app
EXPOSE 3000

# Start Next.js in production mode
CMD ["npm", "start"]
