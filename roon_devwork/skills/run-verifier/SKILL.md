---
name: run-verifier
description: |
  Invoke the verifier agent in standalone mode to validate code against acceptance criteria. Use when the user wants to verify an implementation without running the full workflow. Also useful for debugging the verifier agent.

  <example>
  user: "run verifier, check if the auth module meets the acceptance criteria"
  assistant: "I'll invoke the verifier to check the implementation."
  </example>

  <example>
  user: "ask verifier to validate the payment feature"
  assistant: "Invoking the verifier in standalone mode."
  </example>
---

# Run Verifier (Standalone)

Use this skill to invoke the `verifier` agent independently, outside the full workflow.

## When to Use

- User wants to verify that an implementation meets specific acceptance criteria
- User wants to debug or test the verifier agent
- No active workflow, or user wants verification without advancing the workflow

## Input

The user's verification target from the skill args or conversation. Examples:
- A feature or module to verify
- Specific acceptance criteria to check against
- "verify everything" (check all confirmed ACs)

## Procedure

### Step 1: Confirm Scope

If the user's request is clear from the args, proceed. If ambiguous, ask:
- What code should be verified?
- What acceptance criteria should be used?

### Step 2: Prepare Context

Gather acceptance criteria (in priority order):
1. `state/acceptance-criteria/confirmed.json` — use if it exists
2. `state/standalone/analyst/requirements.json` — use AC-F items as criteria
3. User-provided criteria from the conversation

### Step 3: Invoke Verifier

Invoke the `verifier` agent with:
- The acceptance criteria as the primary input
- The code to verify (files or working tree)
- Instruction to operate in **standalone mode**: output to `state/standalone/verifier/verify-report.json`, do not advance workflow phases

### Step 4: Present Output

When the verifier completes, the output will be at:
- `state/standalone/verifier/verify-report.json` — pass/fail per AC-F, severity of failures, `canShip` flag

## Notes

- This does NOT affect `state/workflow.json` or any active workflow
- Output is isolated to `state/standalone/verifier/`
- If no acceptance criteria exist anywhere, ask the user to provide them before invoking the verifier
