# Start with the specified Python base image, as mcpo is Python-based
FROM python:3.12-slim-bookworm

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Install uv (from official binary) - consistent with your mcpo Dockerfile context
# Placing it in /usr/local/bin for standard practice
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Install build essentials, git, curl, ca-certificates (needed for Node.js PPA and compiling some modules)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js v22.x and npm via NodeSource - consistent with your mcpo Dockerfile context
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm globally - recommended for metamcp as per its README
RUN npm install -g pnpm

# Install mcpo (Python package from PyPI)
# We are installing it as a package here, assuming your repo does not contain mcpo source.
# If your setup is to build mcpo from local source, you'd adjust this.
RUN uv pip install mcpo

# --- Start of Metamcp specific setup ---

# Clone metamcp repository into a designated source directory
# We avoid /app for now as /app will be the working directory for mcpo later.
WORKDIR /
RUN git clone https://github.com/metatool-ai/metamcp.git /metamcp_src

# Set working directory to metamcp source for building
WORKDIR /metamcp_src

# Install metamcp dependencies and build it
# `--frozen-lockfile` is good practice for production builds
# We assume `pnpm build` prepares the server for execution.
RUN pnpm install --frozen-lockfile
RUN pnpm build

# --- End of Metamcp specific setup ---

# Set the primary working directory back to /app for mcpo execution
WORKDIR /app

# Expose the port mcpo will listen on (default 8000)
EXPOSE 8000

# Set a default API key (IMPORTANT: Change this to a strong, unique key in Coolify or an .env file)
ENV MCPO_API_KEY="your-secret-mcpo-api-key"
ENV MCPO_PORT=8000

# Command to run mcpo, passing the metamcp start command as the target MCP server.
# mcpo will run metamcp as a child process and proxy its stdio to HTTP/OpenAPI.
# We use `bash -c` to change directory into /metamcp_src and then execute `pnpm start`.
CMD ["mcpo", "--port", "8000", "--api-key", "${MCPO_API_KEY}", "--", "bash", "-c", "cd /metamcp_src && pnpm start"]
