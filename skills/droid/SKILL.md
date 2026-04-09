---
name: droid
description: >
  Use when the user wants persistent autonomous execution that does not stop between steps.
  Wraps any skill chain (autopilot, executing-plans, etc.) with aggressive continuation behavior,
  iteration tracking, and state persistence. Activated by "droid", "don't stop", "keep going until done".
---

# Droid: Persistent Autonomous Execution

Persistence wrapper that ensures the model keeps executing through multi-step plans without pausing to ask the user for confirmation at phase or task boundaries.

Droid does NOT define its own workflow. It wraps whatever skill chain the user wants (autopilot, executing-plans, subagent-driven-development, etc.) and injects continuation behavior.

## When to Use

- User says "droid", "don't stop", "keep going until done", "run autonomously"
- User invokes `/droid <task>`
- User wants a multi-step plan executed without interruption
- Any task where the model might pause between phases or tasks to ask "shall I continue?"

## Execution Policy

**KEEP GOING UNTIL THE TASK IS FULLY RESOLVED.**

These rules override default politeness. Follow them exactly:

- Do not explain a plan and stop — if you can execute safely, execute.
- Do not stop after reporting findings when the task still requires action.
- Do not summarize progress and ask "shall I continue?" — just continue.
- Do not ask for confirmation between phases or tasks unless the next step is irreversible, side-effectful, or materially changes scope.
- After completing a phase or task, immediately begin the next one without pausing.
- Proceed automatically on clear, low-risk, reversible next steps.
- If correctness depends on additional inspection, retrieval, execution, or verification, keep using tools until grounded.
- Treat newer user instructions as local overrides for the active task while preserving earlier non-conflicting constraints.

**The only reasons to stop and ask the user:**
1. The next step is irreversible or destructive (e.g., force push, delete production data)
2. Requirements are fundamentally ambiguous and no reasonable default exists
3. You are blocked by missing credentials, external service outage, or similar
4. The same error has recurred 3+ times (escalate, don't loop)
5. Max iterations reached

## State Management

On activation, create or update `.gemini/state/droid.json`:

```json
{
  "active": true,
  "iteration": 1,
  "max_iterations": 50,
  "current_phase": "starting",
  "started_at": "<ISO timestamp>",
  "updated_at": "<ISO timestamp>",
  "wrapped_skill": "<skill being wrapped, e.g. autopilot>",
  "task": "<user's task description>",
  "hook_installed": false
}
```

**Update the state file** at each major checkpoint:
- Phase transitions (increment iteration, update current_phase)
- Task completions within a phase
- On completion: set `active: false`, `current_phase: "complete"`

**Check for hook:** At activation, check if `.gemini/hooks/after-agent.sh` exists.
- If yes: set `hook_installed: true`, run in **lean mode** (the hook is the safety net)
- If no: set `hook_installed: false`, run in **heavy mode** (add self-reminders)

## Lean Mode (hook installed)

When the hook is present, it catches any accidental pauses. The skill only needs to:
1. Set up state file
2. Include execution policy in initial prompt
3. Activate the wrapped skill chain
4. Update state at checkpoints
5. Set `active: false` on completion

## Heavy Mode (no hook)

When there is no hook safety net, add explicit self-reminders:
1. Everything in lean mode, PLUS:
2. After each phase/task completion, include this reminder:
   > "Droid mode active (iteration {N}/{MAX}). Proceeding to next step immediately. Do not pause."
3. Before long operations, proactively save session notes (activate session-notes skill)
4. At every transition point, re-read `.gemini/state/droid.json` to confirm droid is still active

## Activation Flow

```
1. User triggers droid (keyword, /droid command, or skill activation)
2. Create .gemini/state/droid.json
3. Detect hook presence → choose lean or heavy mode
4. Determine wrapped skill:
   - If user specifies a skill chain → use it
   - If user describes a feature to build → wrap autopilot
   - If user points to an existing plan → wrap executing-plans or subagent-driven-development
5. Activate the wrapped skill with execution policy injected
6. Monitor state at each checkpoint
7. On completion: set active: false, report final status
```

## Completion

When the wrapped skill chain finishes:
1. Run verification-before-completion (fresh evidence required)
2. Set `active: false` in state file
3. Report final status with verification evidence
4. Clean up state file (or leave for wrapper script to detect)

## Stop Conditions

- Task fully complete with verification evidence
- User says "stop", "cancel", "abort" → activate cancel skill, set active: false
- Max iterations reached → report status, set active: false
- Same error recurring 3+ times → escalate to user
- Fundamental blocker (missing credentials, unclear requirements)

## Integration

**Called by:** User directly, /droid command
**Wraps:** autopilot, executing-plans, subagent-driven-development, or any skill chain
**Uses:** session-notes (in heavy mode), verification-before-completion (on completion), cancel (on abort)
