FROM mcr.microsoft.com/playwright:v1.57.0-noble

# Install display + remote access + dev tools
RUN apt-get update && apt-get install -y \
    xvfb x11vnc novnc supervisor \
    curl git jq openssh-client \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Cursor agent CLI
RUN curl -fsSL https://cursor.com/install | bash

# SpecStory CLI (captures cursor-agent sessions)
RUN curl -fsSL https://github.com/specstoryai/getspecstory/releases/latest/download/SpecStoryCLI_Linux_x86_64.tar.gz \
    | tar -xz -C /usr/local/bin \
    && chmod +x /usr/local/bin/specstory

ENV PATH="/root/.local/bin:$PATH"

WORKDIR /workspace

# Supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Shell customization
COPY bashrc.sh /tmp/bashrc.sh
RUN cat /tmp/bashrc.sh >> /root/.bashrc

EXPOSE 6080

ENV DISPLAY=:99

CMD ["/entrypoint.sh"]
