#!/usr/bin/env bash
# on-stop-checkpoint.sh
# Stop hook for roon_devwork.
# Creates an idempotent checkpoint before the workflow agent stops.
set -e

WORKFLOW_JSON="${CLAUDE_WORKSPACE:-.}/state/workflow.json"
PHASE_LOWER=$(python3 -c "import json; w=json.load(open('$WORKFLOW_JSON')); print(w.get('currentPhase', 'REQUIREMENTS').lower())" 2>/dev/null || echo "requirements")
WORKFLOW_ID=$(python3 -c "import json; w=json.load(open('$WORKFLOW_JSON')); print(w.get('id', 'unknown'))" 2>/dev/null || echo "unknown")

# Create checkpoint tag if we're not already in a clean state
if [ -d ".git" ]; then
    TAG="checkpoint/stop-${PHASE_LOWER}-${WORKFLOW_ID}"
    if git tag "$TAG" 2>/dev/null; then
        echo "Checkpoint created: $TAG"
    else
        echo "Checkpoint already exists or not a git repo: $TAG"
    fi
fi

exit 0
