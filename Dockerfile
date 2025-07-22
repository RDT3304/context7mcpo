# Start with the specified Python base image, as mcpo is Python-based
FROM python:3.12-slim-bookworm

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Install uv (from official binary)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Install build essentials, git, curl, ca-certificates (needed for Node.js PPA and compiling some modules)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js v22.x and npm via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm globally
RUN npm install -g pnpm

# --- Python Virtual Environment for mcpo ---
# Set /app as the working directory for mcpo related setup
WORKDIR /app
# Define the virtual environment location
ENV VIRTUAL_ENV=/app/.venv
# Create the virtual environment using uv
RUN uv venv "$VIRTUAL_ENV"
# Add the virtual environment's bin directory to the PATH
# This ensures that subsequent `uv` commands and `mcpo` itself run within this venv.
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install mcpo into the newly created virtual environment
RUN uv pip install mcpo

# --- Start of Metamcp specific setup ---

# Change working directory temporarily to clone metamcp source
WORKDIR /
RUN git clone https://github.com/metatool-ai/metamcp.git /metamcp_src

# Set working directory to metamcp source for building
WORKDIR /metamcp_src

# Install metamcp dependencies and build it
# `--frozen-lockfile` is good practice for production builds
RUN pnpm install --frozen-lockfile
RUN pnpm build

# --- End of Metamcp specific setup ---

# Set the primary working directory back to /app for mcpo execution
# The PATH already includes /app/.venv/bin from earlier.
WORKDIR /app

# Expose the port mcpo will listen on (default 8000)
EXPOSE 8000

# Set a default API key (IMPORTANT: Change this to a strong, unique key in Coolify or an .env file)
ENV MCPO_API_KEY="your-secret-mcpo-api-key"
ENV MCPO_PORT=8000

# Command to run mcpo, passing the metamcp start command as the target MCP server.
# mcpo will run metamcp as a child process and proxy its stdio to HTTP/OpenAPI.
CMD ["mcpo", "--port", "8000", "--api-key", "${MCPO_API_KEY}", "--", "bash", "-c", "cd /metamcp_src && pnpm start"]
