FROM ubuntu:22.04

# Install curl, git, nodejs, npm and other basics
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install cursor-agent
RUN curl -fsSL https://cursor.com/install | bash

# Add to PATH (cursor-agent installs to /root/.local/bin)
ENV PATH="/root/.local/bin:$PATH"

# Set working directory
WORKDIR /workspace

# Copy current directory
COPY . .

# Default command: drop into shell
CMD ["/bin/bash"]