---
name: start-workflow
description: |
  Start a new multi-agent development workflow. Use when the user says "start workflow", "new workflow", "begin development", "initiate project", or "start a new project".

  <example>
  user: "start a workflow for a user login system"
  assistant: "I'll initialize the workflow. What should we call this project?"
  </example>
---

# Start Workflow

Use this skill to initialize a new multi-agent development workflow.

## When to Use

- User wants to start a new development project
- User says "start workflow", "new workflow", or similar
- No `state/` directory exists in the project

## Procedure

### Step 1: Confirm Project Name

Ask the user to confirm the project name and provide a brief description (1-2 sentences).

### Step 2: Initialize State Directory

Create `state/` with subdirectories:
```
state/
├── requirements/
├── architect/
│   └── interfaces/
├── planner/
├── acceptance-criteria/
├── dev/
├── review/
├── verify/
└── checkpoints/
```

### Step 3: Initialize workflow.json

Call `workflow.init` via the workflow-cli MCP tool:
```
workflow.init { "name": "<project-name>", "id": "<workflow-uuid>" }
```

This creates `state/workflow.json` with:
- `id`: workflow-uuid
- `name`: project name
- `currentPhase`: REQUIREMENTS
- `status`: in_progress
- `phases.REQUIREMENTS.status`: in_progress
- All other phases: pending

### Step 4: Git Initialize

If not already a git repository:
```bash
git init
git commit -m "docs: workflow initialized"
```

### Step 5: Invoke Requirement Analyst

With `workflow-lead` or directly, invoke the `requirement-analyst` agent to begin Phase 1 (requirements elicitation).

## Required Context

- `spec.md` — the workflow plugin specification
- `workflow.config.json` — workflow configuration (create if not exists)

## Notes

- Do NOT start if `state/workflow.json` already exists — use `resume-workflow` instead
- If `workflow.config.json` does not exist, create it with defaults from the spec
