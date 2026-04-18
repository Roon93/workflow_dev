# Task Template

*[This template is used by task-planner when generating task-board.json entries. Each task should follow this structure.]*

## Task: {task-id}

**Title:** *[Short imperative title — what gets built]*

**Description:** *[2-3 sentences: what exactly gets built, based on which interface, to satisfy which AC-T]*

### Dependencies

| Task ID | Reason |
|---------|--------|
| task-000 | *Creates the interface contract this task implements* |

### File Scope

```
Files CREATE:
  - src/api/auth.ts

Files MODIFY:
  - src/shared/types.ts

Files READ:
  - state/architect/interfaces/auth-api.md
  - src/shared/types.ts
```

### Acceptance Criteria (AC-T)

| ID | Description | Verify Method |
|----|-------------|---------------|
| AC-T001 | login API accepts `{email, password}`, returns `{token, expiresAt}` | unit-test |
| AC-T002 | invalid credentials return `401` with `INVALID_CREDENTIALS` error code | unit-test |

### Metadata

| Field | Value |
|-------|-------|
| Task ID | task-001 |
| Interface Ref | AuthAPI.login |
| Priority | high |
| Complexity | medium |
| Model Tier | medium |
| Parallel Group | auth-core |

### Notes

*[Any additional context for the developer — gotchas, non-obvious requirements, etc.]*
