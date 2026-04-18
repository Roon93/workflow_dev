---
name: retry-failed-tasks
description: |
  Retry failed development tasks. Use when the user says "retry", "retry failed tasks", "try again", "retry the failed ones".

  <example>
  Context: 2 tasks failed in development phase
  user: "retry the failed tasks"
  assistant: "I'll reset those 2 tasks and dispatch them again for retry."
  </example>
---

# Retry Failed Tasks

Use this skill to retry tasks that failed during the development phase.

## When to Use

- User says "retry", "retry failed tasks", "try again"
- Workflow is in DEVELOPMENT phase with failed tasks
- Some tasks have `status = failed` in `task-board.json`

## Procedure

### Step 1: Find Failed Tasks

Read `state/planner/task-board.json` and find all tasks where `status = failed`.

For each failed task, record:
- `id`
- `tddRounds` (how many rounds were attempted)
- `lastFailure` (failure context including `failureReason`, `reviewComments`, `failingTests`, `errorLogs`)
- `assignedBranch`

### Step 2: Present Retry Plan

Report to user:
```
Found {n} failed tasks:
  - task-001: "login API JWT validation" — 5 rounds, last failure: JWT expiry not handled
  - task-003: "user registration email uniqueness" — 3 rounds, last failure: DB constraint not enforced
```

Confirm: "Shall I reset and retry these tasks?"

### Step 3: On Confirmation

For each failed task:
1. Clear failure context: set `lastFailure = null`
2. Reset `tddRounds = 0`
3. Set `status = todo`
4. Keep `assignedBranch` (or create new branch if old one is dirty)

### Step 4: Dispatch via workflow-lead

Invoke `workflow-lead` to re-dispatch these tasks through the scheduler.

The workflow-lead will:
- Build new TaskHandoffs with `previousAttempt` carrying the original failure context
- Dispatch to developer agents

## Required Context

- `state/planner/task-board.json`
- `state/dev/{task-id}/dev-log.json` for each failed task

## Key Principles

- Failure context is preserved (it's in `dev-log.json`) — the retry TaskHandoff will carry it
- Each retry starts fresh with `tddRounds = 0`
- Maximum total retries across all rounds = `tddMaxRounds` per task
- If a task has already hit max retries, it should NOT be retried without user intervention
