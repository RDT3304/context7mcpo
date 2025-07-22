# Start with the specified Python base image for mcpo
FROM python:3.12-slim-bookworm

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Install uv (from official binary)
# Placing it in /usr/local/bin for standard practice
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Install git, curl, ca-certificates (needed for Node.js PPA)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js v22.x and npm via NodeSource
# This is required because context7-mcp is a Node.js package run via npx.
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory for mcpo and its virtual environment
WORKDIR /app

# Create a Python virtual environment explicitly for mcpo
ENV VIRTUAL_ENV=/app/.venv
RUN uv venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install mcpo (Python package from PyPI) into the virtual environment
RUN uv pip install mcpo && rm -rf ~/.cache

# Expose the port mcpo will listen on (default 8000)
EXPOSE 8000

# Set a default API key and port for mcpo.
# IMPORTANT: Change "your-secret-mcpo-api-key" to a strong, unique key in Coolify or an .env file.
ENV MCPO_API_KEY="your-secret-mcpo-api-key"
ENV MCPO_PORT=8000

# Command to run mcpo, passing the context7-mcp startup command as the target MCP server.
# Using the shell form of CMD to allow environment variable expansion.
CMD mcpo --port ${MCPO_PORT} --api-key ${MCPO_API_KEY} -- npx -y @upstash/context7-mcp --transport stdio
