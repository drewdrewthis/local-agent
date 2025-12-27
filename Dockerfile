FROM mcr.microsoft.com/playwright:v1.57.0-noble

# Install display + remote access tools + CLI utilities
RUN apt-get update && apt-get install -y \
    xvfb x11vnc novnc supervisor curl git jq \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Cursor agent CLI
RUN curl -fsSL https://cursor.com/install | bash

ENV PATH="/root/.local/bin:$PATH"

# Install pnpm globally
RUN npm install -g pnpm

WORKDIR /workspace

# Copy project files
COPY . .

# Supervisor manages all processes
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Add welcome banner to bashrc
COPY bashrc.sh /tmp/bashrc.sh
RUN cat /tmp/bashrc.sh >> /root/.bashrc

# Set up agent scripts directory
RUN mkdir -p /workspace/scripts/agent && chmod 755 /workspace/scripts/agent

# 6080 = noVNC
EXPOSE 6080

ENV DISPLAY=:99

CMD ["/entrypoint.sh"]
