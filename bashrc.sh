
# ═══════════════════════════════════════════════════════════════════════════════
# Clara Gemmastone - Autonomous Agent Sandbox
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  Clara Gemmastone Agent Sandbox                               ║"
echo "║  VNC: http://localhost:6080                                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Load environment
if [[ -f /workspace/.env ]]; then
    set -a
    source /workspace/.env
    set +a
fi

# Add all script directories to PATH
export PATH="/workspace/scripts/core/google/bin:/workspace/scripts/core/todoist/bin:/workspace/scripts/agent:$PATH"

# Aliases for common operations
alias gmail='gmail-check'
alias cal='calendar-events'
alias todo='todoist'

# Agent script helper
agent-new-script() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: agent-new-script <script-name>"
        return 1
    fi
    local path="/workspace/scripts/agent/${name}.sh"
    cat > "$path" << 'TEMPLATE'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Script: {{NAME}}
# Purpose: [DESCRIBE WHAT THIS SCRIPT DOES]
# Created: {{DATE}}
# ═══════════════════════════════════════════════════════════════════════════════
# Usage: {{NAME}}.sh [args]
# API-first: Uses REST APIs directly, falls back to browser only when necessary
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Load shared libraries
source /workspace/scripts/core/google/lib/api.sh 2>/dev/null || true
source /workspace/scripts/core/todoist/lib/api.sh 2>/dev/null || true

main() {
    echo "TODO: Implement script logic"
}

main "$@"
TEMPLATE
    sed -i "s/{{NAME}}/$name/g" "$path"
    sed -i "s/{{DATE}}/$(date +%Y-%m-%d)/g" "$path"
    chmod +x "$path"
    echo "Created: $path"
}

echo "Available commands: gmail, cal, todo, agent-new-script"
echo ""

