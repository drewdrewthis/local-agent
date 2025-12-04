FROM ubuntu:22.04

# Install curl, git and other basics
RUN apt-get update && apt-get install -y \
    curl \
    git \
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