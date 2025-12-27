#!/bin/bash
set -e

# Load environment
if [[ -f /workspace/.env ]]; then
    set -a
    source /workspace/.env
    set +a
fi

# Configure git
git config --global user.name "${GIT_AUTHOR_NAME:-Clara Gemmastone}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-clara.gemmastone@gmail.com}"
git config --global --add safe.directory /workspace

# Add scripts to PATH
export PATH="/workspace/scripts/google/bin:/workspace/scripts/todoist/bin:/workspace/scripts/custom:$PATH"

# Start supervisor (manages Xvfb, x11vnc, noVNC)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
