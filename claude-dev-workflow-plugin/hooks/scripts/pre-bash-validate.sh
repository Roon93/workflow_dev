#!/usr/bin/env bash
# pre-bash-validate.sh
# PreToolUse hook for claude-dev-workflow.
# Validates that git operations (commit, branch, push) meet phase requirements
# before allowing them to execute.
set -e

# Read the workflow state to determine current phase and task context
WORKFLOW_JSON="${CLAUDE_WORKSPACE:-.}/state/workflow.json"
TASK_BOARD="${CLAUDE_WORKSPACE:-.}/state/planner/task-board.json"

# Get the current phase
CURRENT_PHASE=$(python3 -c "import json; w=json.load(open('$WORKFLOW_JSON')); print(w.get('currentPhase', 'UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")

# Parse the bash command being run
CMD="$1"
PHASE_LOWER=$(echo "$CURRENT_PHASE" | tr '[:upper:]' '[:lower:]')

# For now, allow all commands in early phases (requirements, architect, planner)
# In later phases (DEVELOPMENT+), git operations need task context
if [ "$CURRENT_PHASE" = "DEVELOPMENT" ] || [ "$CURRENT_PHASE" = "REVIEW" ] || [ "$CURRENT_PHASE" = "VERIFY" ]; then
    # In development+, check if this is a git operation
    if echo "$CMD" | grep -qE "git (commit|branch|tag|push)"; then
        # Check if a task is currently in progress
        IN_PROGRESS=$(python3 -c "import json; t=json.load(open('$TASK_BOARD')); print(sum(1 for task in t.get('tasks', []) if task.get('status') == 'in_progress'))" 2>/dev/null || echo "0")
        if [ "$IN_PROGRESS" -gt 0 ]; then
            echo "WARN: Git operation attempted while tasks are in progress. Consider committing task work first." >&2
        fi
    fi
fi

# Always allow — this is a warning-only gate
# The actual enforcement comes from workflow-lead agent discipline
exit 0
