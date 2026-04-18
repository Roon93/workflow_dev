---
name: approve-gate
description: |
  Approve the current phase gate and advance to the next phase. Use when the user says "approve", "confirm", "looks good", "advance", "next phase", "that looks right", or similar.

  <example>
  Context: Requirements phase complete, architect output ready
  user: "approve, looks good"
  assistant: "I'll advance the workflow to the architect phase."
  </example>
---

# Approve Gate

Use this skill to approve the current phase's output and advance the workflow.

## When to Use

- A phase has produced its output and is awaiting user confirmation
- User says "approve", "confirm", "looks good", "advance", "next phase"

## Procedure

### Step 1: Identify Current Phase

Read `state/workflow.json` to find `currentPhase` and check that the phase is actually ready to advance (its `status` should be `completed`).

### Step 2: Present Phase Summary

Summarize what the phase produced:

| Phase | Output to summarize |
|-------|---------------------|
| REQUIREMENTS | `state/requirements/confirmed.json` — features and AC-F |
| ARCHITECT | `state/architect/architecture.md` — module map, interfaces |
| TASK_PLANNING | `state/planner/task-board.json` — task count, DAG edges, priorities |
| ACCEPTANCE_CONFIRM | `state/acceptance-criteria/confirmed.json` — all AC-F and AC-T |
| DEVELOPMENT | Scheduler stats — tasks done/failed/in-progress |
| REVIEW | `state/review/review-report.json` — findings and rework tasks |
| VERIFY | `state/verify/verify-report.json` — pass/fail by AC-F |

### Step 3: Request Confirmation

Present the summary and ask: "Do you confirm this output and want to advance to the next phase?"

### Step 4: On Approval

1. Update `state/workflow.json`:
   - Set `phases[currentPhase].status = completed`
   - Set `phases[currentPhase].completedAt = <timestamp>`
   - Advance `currentPhase` to next phase
   - Set new phase `status = in_progress`

2. Call `workflow.advance_phase` via workflow-cli

3. Create checkpoint:
   ```bash
   git add -A
   git commit -m "docs({phase}): {phase name} completed"
   git tag "checkpoint/after-{phase-lowercase}"
   ```

4. If next phase is DEVELOPMENT or later, proceed automatically. If next phase is REQUIREMENTS through ACCEPTANCE_CONFIRM, invoke the appropriate specialist agent.

### Step 5: On Rejection

1. Record rejection reason in `state/workflow.json` or a rejection log
2. Set `phases[currentPhase].status = rejected`
3. Report what was rejected and what needs to change
4. Return to that phase's specialist agent for correction

## Required Context

- `state/workflow.json`
- The output file of the current phase

## Notes

- If the current phase is not completed, do not advance — report the status
- Phases 1-4 require user approval. Phases 5-7 are auto-driven but can still be paused for intervention
