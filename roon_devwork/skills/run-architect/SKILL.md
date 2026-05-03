---
name: run-architect
description: |
  Invoke the architect agent in standalone mode. Use when the user wants to design architecture for a feature or system without running the full workflow. Also useful for debugging the architect agent.

  <example>
  user: "run architect, design the module structure for a file upload service"
  assistant: "I'll invoke the architect to design this for you."
  </example>

  <example>
  user: "ask architect to review and redesign the auth module"
  assistant: "Invoking the architect in standalone mode."
  </example>
---

# Run Architect (Standalone)

Use this skill to invoke the `architect` agent independently, outside the full workflow.

## When to Use

- User wants to design or review architecture for a feature or system
- User wants to debug or test the architect agent
- No active workflow, or user wants architecture work without advancing the workflow

## Input

The user's task or question from the skill args or conversation. Examples:
- A feature or system to design
- Existing requirements to turn into an architecture
- A specific architectural question or decision

## Procedure

### Step 1: Confirm Task

If the user's request is clear from the args, proceed. If ambiguous, ask one clarifying question.

### Step 2: Prepare Context

Check for existing state:
- If `state/requirements/confirmed.json` exists: read it as the primary requirements input
- If `state/standalone/analyst/requirements.json` exists: read it as an alternative
- Otherwise: use the user's description as the requirements

### Step 3: Invoke Architect

Invoke the `architect` agent with:
- The requirements (from state or user input) as the primary input
- Instruction to operate in **standalone mode**: output to `state/standalone/architect/`, do not advance workflow phases

### Step 4: Present Output

When the architect completes, the output will be at:
- `state/standalone/architect/architecture.md` — main architecture document
- `state/standalone/architect/interfaces/` — interface contract files
- `state/standalone/architect/module-boundaries.md` — dependency rules

## Notes

- This does NOT affect `state/workflow.json` or any active workflow
- Output is isolated to `state/standalone/architect/`
- To use the architect output in a real workflow, copy it to `state/architect/`
