
# ═══════════════════════════════════════════════════════════════════════════════
# Clara Gemmastone - cursor-cli Sandbox
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  Clara Sandbox (cursor-cli environment)                       ║"
echo "║  VNC: http://localhost:6080                                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Load environment
if [[ -f /workspace/.env ]]; then
    set -a
    source /workspace/.env
    set +a
fi

# Add scripts to PATH
export PATH="/workspace/scripts/google/bin:/workspace/scripts/todoist/bin:/workspace/scripts/custom:$PATH"

# Aliases
alias gmail='gmail-check'
alias cal='calendar-events'
alias todo='todoist'

echo "Scripts: gmail, cal, todo"
echo ""
