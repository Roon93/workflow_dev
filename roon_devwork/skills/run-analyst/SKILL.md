---
name: run-analyst
description: |
  Invoke the requirement-analyst agent in standalone mode. Use when the user wants to analyze, clarify, or structure requirements without starting a full workflow. Also useful for debugging the analyst agent.

  <example>
  user: "run analyst, help me figure out the requirements for a notification system"
  assistant: "I'll invoke the requirement analyst to work through this with you."
  </example>

  <example>
  user: "ask analyst to clarify what we need for the payment feature"
  assistant: "Invoking the requirement analyst in standalone mode."
  </example>
---

# Run Analyst (Standalone)

Use this skill to invoke the `requirement-analyst` agent independently, outside the full workflow.

## When to Use

- User wants to analyze or clarify requirements for a feature or project
- User wants to debug or test the requirement-analyst agent
- No active workflow, or user wants to work on requirements without advancing the workflow

## Input

The user's task or question from the skill args or conversation. Examples:
- A feature description to analyze
- A set of vague requirements to clarify
- A question about what requirements are needed

## Procedure

### Step 1: Confirm Task

If the user's request is clear from the args, proceed. If ambiguous, ask one clarifying question.

### Step 2: Prepare Context

Check if `state/requirements/` exists:
- If yes: read existing requirements as background context
- If no: start fresh with no prior context

### Step 3: Invoke Requirement Analyst

Invoke the `requirement-analyst` agent with:
- The user's task/question as the primary input
- Any existing requirements as background context
- Instruction to operate in **standalone mode**: output to `state/standalone/analyst/`, do not advance workflow phases

### Step 4: Present Output

When the analyst completes, the output will be at:
- `state/standalone/analyst/requirements.json` — structured requirements
- `state/standalone/analyst/qa-history.json` — Q&A history

## Notes

- This does NOT affect `state/workflow.json` or any active workflow
- Output is isolated to `state/standalone/analyst/`
- To use the analyst output in a real workflow, copy it to `state/requirements/confirmed.json`
