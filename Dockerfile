# Start with a Python base image suitable for mcpo
FROM python:3.11-slim-bookworm

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Install Node.js and npm (needed for context7)
# This uses the NodeSource PPA for a recent LTS version of Node.js
RUN apt-get update && \
    apt-get install -y curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install mcpo (Python package)
RUN pip install mcpo

# Set the working directory
WORKDIR /app

# Expose the port mcpo will listen on (default 8000)
EXPOSE 8000

# Set a default API key (IMPORTANT: Change this to a strong, unique key in Coolify or an .env file)
ENV MCPO_API_KEY="your-secret-mcpo-api-key"
ENV MCPO_PORT=8000

# Command to run mcpo, passing the context7 command as the target MCP server
# mcpo will run context7 as a child process and proxy its stdio to HTTP/OpenAPI
# We use `npx -y @upstash/context7-mcp` to run context7.
# We also pass --transport stdio to context7 to ensure it communicates via stdio,
# which is what mcpo expects by default.
CMD ["mcpo", "--port", "8000", "--api-key", "${MCPO_API_KEY}", "--", "npx", "-y", "@upstash/context7-mcp", "--transport", "stdio"]
