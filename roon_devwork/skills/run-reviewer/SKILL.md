---
name: run-reviewer
description: |
  Invoke the reviewer agent in standalone mode to review code, run tests, and produce a review report. Use when the user wants a code review without running the full workflow. Also useful for debugging the reviewer agent.

  <example>
  user: "run reviewer on src/auth/"
  assistant: "I'll invoke the reviewer to review the auth module."
  </example>

  <example>
  user: "ask reviewer to check the latest changes"
  assistant: "Invoking the reviewer in standalone mode."
  </example>
---

# Run Reviewer (Standalone)

Use this skill to invoke the `reviewer` agent independently, outside the full workflow.

## When to Use

- User wants a code review on specific files, a directory, or recent changes
- User wants to debug or test the reviewer agent
- No active workflow, or user wants a review without advancing the workflow

## Input

The user's review target from the skill args or conversation. Examples:
- A file path or directory to review
- A git diff or commit range
- "latest changes" (review uncommitted or recent changes)

## Procedure

### Step 1: Confirm Scope

If the user's review target is clear from the args, proceed. If ambiguous, ask:
- Which files or directories to review?
- Should tests be run as part of the review?
- Are there specific concerns to focus on?

### Step 2: Prepare Context

Determine what to review:
- If the user specifies files/directories: use those
- If the user says "latest changes": use `git diff HEAD` or `git diff --staged`
- If no scope given: review the entire working tree

### Step 3: Invoke Reviewer

Invoke the `reviewer` agent with:
- The review scope (files, diff, or working tree)
- Any specific concerns the user mentioned
- Instruction to operate in **standalone mode**: skip workflow task aggregation, output to `state/standalone/reviewer/review-report.json`, do not advance workflow phases

### Step 4: Present Output

When the reviewer completes, the output will be at:
- `state/standalone/reviewer/review-report.json` — findings, severity, and recommendations

## Notes

- This does NOT affect `state/workflow.json` or any active workflow
- Output is isolated to `state/standalone/reviewer/`
- The reviewer will run tests if a test runner is available
