# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code plugin** that implements a multi-agent collaborative software development workflow. It is NOT a traditional application with a runtime — it is a plugin definition that uses Claude Code's native sub-agents, agent teams, hooks, MCP tools, and CLI tools to orchestrate a full development lifecycle.

## Core Architecture

```
User
  │
  ▼
Claude Code
  ├── Plugin Skills (entry points)
  ├── workflow-lead (main coordinator Agent)
  ├── Specialist Agents (requirement analyst, architect, task planner, developer, reviewer, verifier)
  ├── Hooks (phase gate validation)
  └── MCP/CLI Tools (state, DAG, Git, checkpoint management)
```

**Key principle**: The plugin defines the structure and tools, but does NOT implement its own agent runtime. Multi-agent coordination uses Claude Code's native mechanism.

## Workflow Phases

| Phase | Role | Key Output |
|-------|------|------------|
| Phase 1: Requirements | requirement-analyst | `state/requirements/confirmed.json` |
| Phase 2: Architecture | architect | `state/architect/` (architecture.md, interfaces/, module-boundaries.md) |
| Phase 3: Task Planning | task-planner | `state/planner/task-board.json` |
| Phase 4: Acceptance Criteria | workflow-lead + user | `state/acceptance-criteria/confirmed.json` |
| Phase 5: Development | developer agents (TDD loop) | Code + tests + git commits |
| Phase 6: Review | reviewer | `state/review/review-report.json` |
| Phase 7: Verification | verifier | `state/verify/verify-report.json` |

**Every phase transition requires user confirmation** (handled via skills + hooks).

## State Directory Structure

```
state/
├── workflow.json              # Current phase, status, scheduler summary
├── requirements/              # requirements analyst output
├── architect/                # architect output
├── planner/task-board.json   # DAG of tasks
├── acceptance-criteria/      # locked acceptance criteria
├── dev/{task-id}/             # Per-task TDD logs
├── review/                    # review reports
├── verify/                    # verification reports
└── checkpoints/               # Phase snapshots for rollback
```

State is the **source of truth** for resuming interrupted workflows. The lead agent rebuilds context from `state/` on resume.

## Agent Roles

| Role | Single Responsibility | Input → Output |
|------|----------------------|----------------|
| workflow-lead | Phase transitions, task dispatch, state management | workflow.json → phase advance, task dispatch |
| requirement-analyst | Interactive requirements elicitation | raw user input → confirmed.json + qa-history |
| architect | Architecture design, interface contracts | requirements → architect/ |
| task-planner | Task decomposition into atomic DAG | requirements + architect → task-board.json |
| developer | TDD per task (one task per agent instance) | TaskHandoff → code + test + commit |
| reviewer | Code review + integration testing | completed tasks → review-report.json |
| verifier | Acceptance criteria validation | code + acceptance criteria → verify-report.json |

## Developer Agent TDD Loop

Each developer agent executes per task:

1. Read TaskHandoff (task, AC, architecture context, file scope)
2. Write failing tests based on task-level acceptance criteria
3. Implement to pass tests
4. Run tests; if failed → analyze → retry (max `tddMaxRounds`)
5. Update dev-log.json, git commit

**Context constraint**: TaskHandoff is精简 — only the specific files, interfaces, and dependencies that the task needs. Do NOT dump the entire repository context.

## File Conflict Prevention

Tasks declare `files.create`, `files.modify`, `files.read`. Within the same parallel batch:
- `create` and `modify` must not intersect between tasks
- If conflict detected at runtime → degrade to serial execution

## Key Skill Entry Points

| Skill | Purpose |
|-------|---------|
| `start-workflow` | Initialize a new workflow |
| `resume-workflow` | Resume from `state/` |
| `approve-gate` | User confirms phase output |
| `workflow-status` | Query current phase/status |
| `retry-failed-tasks` | Retry failed development tasks |

## Configuration

Plugin configuration lives in `workflow.config.json` (at workspace root when workflow is active):

```json
{
  "maxConcurrency": 3,
  "tddMaxRounds": 5,
  "workflowMaxRetries": 3,
  "failureThreshold": 2,
  "requireUserApproval": { "afterRequirements": true, "afterArchitect": true, ... },
  "models": { "workflowLead": { "tier": "high" }, "developer": { "defaultTier": "medium", "byComplexity": {...} } },
  "git": { "branchPrefix": "workflow", "autoCommit": true, "isolationMode": "branch" },
  "stateDir": "./state"
}
```

Model tiers (low/medium/high) are resolved via plugin configuration or environment — the spec does NOT bind to specific model snapshot names.

## Error Handling Levels

| Level | Condition | Scope | Rollback Target |
|-------|-----------|-------|-----------------|
| L1 | TDD test failure | single task | same task, next round |
| L2 | max TDD rounds exceeded | single task | mark failed, skip to dependent |
| L3 | review failure | failed task | Phase 5 (development) |
| L4 | verification minor issue | related task | Phase 5 |
| L5 | verification major deviation | workflow partial | Phase 3 (task planning) |
| L6 | environment / mass failure | entire workflow | pause + user intervention |

## Git Strategy

- Branch model: `workflow/{workflow-id}/base/feat/{task-id}`
- Each phase completion: commit with message like `docs(requirements): 需求确认完成`
- Task completion: commit like `feat({task-id}): 任务完成 - {title}`
- Phase checkpoints use git tags for rollback targets

## Implementation Status

This repository currently contains only `spec.md` — the full plugin implementation has not been created. All paths in this CLAUDE.md describe the **intended target architecture** from the spec.
