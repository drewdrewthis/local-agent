# Use Alpine with working cursor-agent setup
FROM alpine:latest

RUN apk add --no-cache \
    curl \
    git \
    bash \
    nodejs \
    npm \
    python3 \
    py3-pip \
    build-base \
    ca-certificates

RUN curl -fsSL https://cursor.com/install | bash

# Install Playwright (headless mode)
RUN npm install -g @playwright/test && \
    npx playwright install chromium

ENV PATH="/root/.local/bin:$PATH"

WORKDIR /workspace
COPY . .

CMD ["/bin/bash"]