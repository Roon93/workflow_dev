---
name: run-planner
description: |
  Invoke the task-planner agent in standalone mode. Use when the user wants to break down a feature or architecture into tasks without running the full workflow. Also useful for debugging the task-planner agent.

  <example>
  user: "run planner, break down the auth module into tasks"
  assistant: "I'll invoke the task planner to generate a task breakdown."
  </example>

  <example>
  user: "ask planner to create a task DAG for the payment feature"
  assistant: "Invoking the task planner in standalone mode."
  </example>
---

# Run Planner (Standalone)

Use this skill to invoke the `task-planner` agent independently, outside the full workflow.

## When to Use

- User wants to decompose a feature or architecture into atomic tasks
- User wants to debug or test the task-planner agent
- No active workflow, or user wants task planning without advancing the workflow

## Input

The user's task or question from the skill args or conversation. Examples:
- A feature or architecture to decompose
- Existing requirements + architecture to turn into a task DAG
- A specific planning question

## Procedure

### Step 1: Confirm Task

If the user's request is clear from the args, proceed. If ambiguous, ask one clarifying question.

### Step 2: Prepare Context

Check for existing state (in priority order):
1. `state/requirements/confirmed.json` + `state/architect/` — use as primary input if both exist
2. `state/standalone/analyst/requirements.json` + `state/standalone/architect/` — use as alternative
3. Otherwise: use the user's description as the input

### Step 3: Invoke Task Planner

Invoke the `task-planner` agent with:
- The requirements and architecture as input
- Instruction to operate in **standalone mode**: output to `state/standalone/planner/`, do not advance workflow phases

### Step 4: Present Output

When the planner completes, the output will be at:
- `state/standalone/planner/task-board.json` — task DAG with dependencies, file scopes, and AC-T

## Notes

- This does NOT affect `state/workflow.json` or any active workflow
- Output is isolated to `state/standalone/planner/`
- To use the planner output in a real workflow, copy it to `state/planner/task-board.json`
