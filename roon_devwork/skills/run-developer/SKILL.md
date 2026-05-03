---
name: run-developer
description: |
  Invoke the developer agent in standalone mode to implement a specific task using TDD. Use when the user wants to implement something without running the full workflow. Also useful for debugging the developer agent.

  <example>
  user: "run developer, implement a JWT token validation middleware"
  assistant: "I'll invoke the developer agent to implement this with TDD."
  </example>

  <example>
  user: "ask developer to add rate limiting to the login endpoint"
  assistant: "Invoking the developer in standalone mode."
  </example>
---

# Run Developer (Standalone)

Use this skill to invoke the `developer` agent independently, outside the full workflow.

## When to Use

- User wants to implement a specific feature or task using TDD
- User wants to debug or test the developer agent
- No active workflow, or user wants to implement something without advancing the workflow

## Input

The user's task description from the skill args or conversation. Examples:
- A feature or function to implement
- A bug to fix
- A specific implementation task with clear acceptance criteria

## Procedure

### Step 1: Confirm Task

If the user's request is clear from the args, proceed. If ambiguous, ask:
- What should be implemented?
- Where should the code go (file paths)?
- What are the acceptance criteria (what should the tests verify)?

### Step 2: Prepare Context

Gather relevant context:
- Files the user points to (read them)
- Any interface specs or architecture docs the user references
- Existing tests in the target area (to understand conventions)

### Step 3: Invoke Developer

Invoke the `developer` agent with:
- The task description as the primary input
- Any relevant file context
- Instruction to operate in **standalone mode**: use natural language task spec (no formal TaskHandoff required), write dev log to `state/standalone/developer/{task-slug}/dev-log.json`, do not update workflow state

### Step 4: Present Output

When the developer completes:
- Code and tests are written to the locations specified in the task
- Dev log is at `state/standalone/developer/{task-slug}/dev-log.json`

## Notes

- This does NOT affect `state/workflow.json` or any active workflow
- The developer still follows TDD: write failing tests first, then implement
- File scope is determined by the user's request, not a TaskHandoff
- Git commits are made normally (the developer commits on success)
