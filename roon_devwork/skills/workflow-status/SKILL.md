---
name: workflow-status
description: |
  Query the current workflow status including phase, task progress, and any failures. Use when the user says "status", "how's it going", "workflow state", "what's the progress", "how many tasks are done".

  <example>
  user: "what's the status of the workflow?"
  assistant: "The workflow is in Phase 5 (Development). 5 of 8 tasks complete, 2 in progress, 1 failed."
  </example>
---

# Workflow Status

Use this skill to query and report the current workflow state.

## When to Use

- User asks about workflow status, progress, or state
- User says "status", "how's it going", "what's the progress"

## Procedure

### Step 1: Read workflow.json

Read `state/workflow.json`:
- `id`, `name`
- `currentPhase`
- `status`
- All phase statuses and timestamps

### Step 2: Read task-board.json (if exists)

If `state/planner/task-board.json` exists, read:
- Total tasks
- Done / in_progress / todo / failed / blocked counts
- Failed task IDs and their failure reasons
- Blocked task IDs and what they're blocked by

### Step 3: Report Status

Present a concise status report:

```
Workflow: {name} ({id})
Phase: {currentPhase} — {status}
Progress: {phases completed count} / 7 phases

Phase History:
  REQUIREMENTS   ✅ completed {timestamp}
  ARCHITECT      ✅ completed {timestamp}
  TASK_PLANNING  ✅ completed {timestamp}
  ACCEPTANCE    ✅ completed {timestamp}
  DEVELOPMENT    🔄 in_progress (started {timestamp})
  REVIEW         ⏳ pending
  VERIFY         ⏳ pending

Task Board (if in DEVELOPMENT+):
  Total: {n} | Done: {n} | In Progress: {n} | Failed: {n} | Blocked: {n}

Recent Activity:
  - {task-001} completed 2 hours ago
  - {task-002} failed after 5 TDD rounds (see dev/task-002/dev-log.json)
```

### Step 4: On Failures

If there are failed tasks, report:
- Which tasks failed
- How many TDD rounds were attempted
- What the last failure reason was
- Whether retry is available (user can use `retry-failed-tasks`)

## Required Context

- `state/workflow.json`
- `state/planner/task-board.json` (if exists)

## Notes

- If `state/workflow.json` doesn't exist, report "No active workflow"
- If workflow is `completed`, celebrate and report final stats
