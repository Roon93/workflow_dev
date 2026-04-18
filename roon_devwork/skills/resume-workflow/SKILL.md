---
name: resume-workflow
description: |
  Resume an interrupted workflow from state/. Use when the user says "resume", "continue workflow", "pick up where we left off", or "resume the workflow".

  <example>
  user: "resume the workflow"
  assistant: "Let me read the workflow state to understand where we left off."
  </example>
---

# Resume Workflow

Use this skill to resume a workflow that was interrupted.

## When to Use

- A `state/workflow.json` already exists
- User says "resume", "continue workflow", or similar
- The workflow was paused or interrupted

## Procedure

### Step 1: Read workflow.json

Read `state/workflow.json` to determine:
- `currentPhase` — what phase we were in
- `status` — in_progress | paused | interrupted
- `phases[currentPhase].status` — the status of the current phase
- `scheduler` — task completion stats

### Step 2: Reconstruct Context

Based on current phase, reconstruct what was happening:

| Phase | What to reconstruct |
|-------|---------------------|
| REQUIREMENTS | Q&A history, confirmed requirements so far |
| ARCHITECT | Requirements read, architecture in progress |
| TASK_PLANNING | Requirements + architect output |
| ACCEPTANCE_CONFIRM | Task board, acceptance criteria in progress |
| DEVELOPMENT | Task board, active/retry tasks |
| REVIEW | All task results, review in progress |
| VERIFY | All code, acceptance criteria |

### Step 3: Present Resume Summary

Report to user:
- Current phase and status
- How many tasks done/in-progress/failed
- Last checkpoint timestamp
- What needs to happen next

### Step 4: Continue

Invoke `workflow-lead` agent with recovered state context to continue from the interruption point.

## Required Context

- `state/workflow.json` — must exist
- `state/` subdirectories — must exist

## Notes

- If `state/` is missing or corrupted, report error and suggest starting fresh
- If workflow is `completed`, report that it's already done
- If workflow is `paused` by user, ask what to do before resuming
