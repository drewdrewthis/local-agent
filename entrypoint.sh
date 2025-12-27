#!/bin/bash
set -e

# Load environment
if [[ -f /workspace/.env ]]; then
    set -a
    source /workspace/.env
    set +a
fi

# Ensure agent scripts directory exists
mkdir -p /workspace/scripts/agent

# Initialize registry if missing
if [[ ! -f /workspace/scripts/agent/registry.json ]]; then
    echo '{"scripts":[],"version":"1.0"}' > /workspace/scripts/agent/registry.json
fi

# Add scripts to PATH
export PATH="/workspace/scripts/core/google/bin:/workspace/scripts/core/todoist/bin:/workspace/scripts/agent:$PATH"

# Start supervisor (manages Xvfb, x11vnc, noVNC)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

