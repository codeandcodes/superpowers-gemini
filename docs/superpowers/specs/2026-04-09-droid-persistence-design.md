# Droid: Persistent Autonomous Execution for Gemini CLI

## Context Snapshot

- **Task:** Build a persistence system ("droid") that keeps Gemini CLI running through multi-step plans without the model stopping to ask the user to continue
- **Desired outcome:** Gemini can execute multi-hour autonomous sessions (autopilot, plan execution, etc.) without pausing for user confirmation at phase/task boundaries
- **Known facts:**
  - The model (not the approval system) is what pauses — it asks "shall I continue?" at phase and task boundaries
  - User typically runs in yolo mode but wants a cleaner replacement
  - Gemini CLI supports hooks (11 types), custom commands, policy engine, session resume
  - The existing autopilot skill defines good phases/gates but lacks persistence loop behavior
  - oh-my-codex's "ralph" skill solves this with aggressive prompt engineering, state persistence, hooks, and a wrapper script
  - This extension currently has no hooks, commands, or policies
- **Constraints:**
  - Must work as a Gemini CLI extension (skills, agents, hooks, commands, policies)
  - Hook installation must be toggleable — user may not want shell scripts running
  - Must not duplicate autopilot's workflow logic — droid wraps, doesn't replace
  - Must handle context window exhaustion for multi-hour sessions
- **Unknowns:**
  - Exact capabilities of Gemini CLI's AfterAgent hook (can it inject messages or only observe?)
  - Whether the policy engine supports environment variable conditions
  - How reliably prompt-level "don't stop" instructions survive context compression
- **Codebase touchpoints:**
  - New: `skills/droid/SKILL.md`, `hooks/after-agent.sh`, `policies/droid-auto-approve.toml`, `commands/droid.toml`, `scripts/droid-run.sh`
  - Modified: `GEMINI.md`, `gemini-extension.json`, `install.sh`, `README.md`

---

## Architecture

Droid is a **layered persistence system** with four independent layers, each catching what the previous one misses:

```
Layer 1: Droid Skill (prompt-level)          — handles ~80% of pauses
Layer 2: AfterAgent Hook (script-level)      — catches ~15% the skill misses
Layer 3: Policy Rules (config-level)         — removes tool approval friction
Layer 4: Wrapper Script (process-level)      — recovers from context exhaustion
```

Each layer is independently useful. Users can adopt any subset.

---

## Component 1: Droid Skill (`skills/droid/SKILL.md`)

### Purpose
Persistence wrapper that goes around any skill chain (autopilot, executing-plans, etc.) and injects "never stop" behavior.

### Activation
- User says "droid", "don't stop", "keep going until done", "run autonomously"
- User invokes `/droid <task>` custom command
- Skill routing table in GEMINI.md maps these intents to droid

### State File (`.gemini/state/droid.json`)
```json
{
  "active": true,
  "iteration": 1,
  "max_iterations": 50,
  "current_phase": "executing",
  "started_at": "2026-04-09T10:00:00Z",
  "updated_at": "2026-04-09T10:05:00Z",
  "wrapped_skill": "autopilot",
  "task": "build the authentication system",
  "hook_installed": true
}
```

### Behavior Modes
- **Hook installed:** Skill runs lean. Core instructions plus state tracking. The hook catches any pauses.
- **Hook not installed:** Skill runs heavy. Adds self-reminder checkpoints:
  - After each phase/task completion, reads state file and confirms droid is active
  - Proactively saves session notes before long operations
  - Includes explicit "do not pause" reminders at every transition point

### Execution Policy (embedded in skill prompt)
```
- KEEP GOING UNTIL THE TASK IS FULLY RESOLVED.
- Do not explain a plan and stop — if you can execute safely, execute.
- Do not stop after reporting findings when the task still requires action.
- Do not summarize progress and ask "shall I continue?" — just continue.
- Proceed automatically on clear, low-risk, reversible next steps.
- Ask only when the next step is irreversible, side-effectful, or materially changes scope.
- After completing a phase or task, immediately begin the next one without pausing.
- Continue through clear, low-risk, reversible next steps automatically.
- If correctness depends on additional inspection, retrieval, execution, or verification, keep using tools until grounded.
```

### Iteration Tracking
- Counter increments at each major checkpoint (phase completion, task completion)
- Default max: 50 iterations
- At max: allow natural completion, report to user
- State persisted to `.gemini/state/droid.json` at each increment

### Completion
- When wrapped skill chain finishes (all phases complete, verification passed)
- Set `active: false` in state file
- Report final status with verification evidence

### Stop Conditions
- Task fully complete with verification evidence
- User says "stop", "cancel", "abort"
- Max iterations reached
- Fundamental blocker requiring user input (missing credentials, unclear requirements)
- Same error recurring 3+ times (escalate rather than loop)

---

## Component 2: AfterAgent Hook (`hooks/after-agent.sh`)

### Purpose
External safety net that detects when the model pauses despite droid instructions, and nudges it to continue.

### Installation
- **Toggleable** during `install.sh` execution
- Flag: `./install.sh --with-droid-hook` (or `--no-droid-hook` to skip)
- Interactive prompt if no flag: "Enable droid auto-continuation hook? (y/n)"
- Copies to target project's `.gemini/hooks/after-agent.sh`

### Behavior
1. Read `.gemini/state/droid.json`
2. If `active` is not `true`, exit 0 (no-op)
3. Parse model's last output from stdin JSON
4. Check for stopping signals:
   - Phrases: "shall I continue", "would you like me to", "ready to proceed", "let me know if", "want me to", "should I proceed"
   - Output ending with a question mark and no pending tool calls
   - Summary-only output with no next action
5. If stopping signal detected:
   - Output JSON response injecting continuation message
   - Increment iteration counter in state file
6. If no stopping signal: exit 0 (no-op)
7. If max iterations reached: exit 0 (let model stop)

### Stopping Signal Patterns (regex)
```
shall I (continue|proceed|go ahead|move on)
would you like (me to|to)
ready to (proceed|continue|move on)
let me know (if|when|whether)
want me to (continue|proceed|start|begin)
should I (proceed|continue|go ahead|move on)
do you want (me to|to)
```

### Output Format (when continuation needed)
```json
{
  "message": "Droid mode is active (iteration {N}/{MAX}). Continue executing the current task. Do not pause for confirmation. Proceed to the next step immediately."
}
```

### Fallback Behavior
- If state file doesn't exist or is malformed: exit 0 (no-op, safe default)
- If hook can't inject messages (API limitation): log to `.gemini/state/droid-hook.log` for debugging

---

## Component 3: Policy Rules (`policies/droid-auto-approve.toml`)

### Purpose
Auto-approve tools during droid execution, replacing the need for `--yolo`.

### Structure
Two tiers of rules:

**Tier 1: Always-safe tools (auto-approve always)**
```toml
[[rules]]
description = "Auto-approve read-only operations"
tool = ["read_file", "glob", "grep", "list_directory", "web_search"]
decision = "allow"
```

**Tier 2: Write tools (auto-approve for droid)**
The ideal approach conditions on an environment variable (`GEMINI_DROID=1`). If the policy engine doesn't support environment conditions, the fallback is:
- This policy file is installed separately from other policies
- Users symlink it in when they want droid-level auto-approve
- Install script offers to install it; uninstall by removing the symlink

**Safety deny rules (highest priority)**
```toml
[[rules]]
description = "Block destructive operations even in droid mode"
tool = "shell"
commandRegex = "(rm -rf /|git push --force|drop table|DROP TABLE)"
decision = "deny"
priority = 999
```

---

## Component 4: Custom Command (`commands/droid.toml`)

### Purpose
Quick entry point: `/droid build the auth system`

### Content
```toml
prompt = "Activate the droid skill. KEEP GOING UNTIL THE TASK IS FULLY RESOLVED. Do not pause between steps. Task: {{args}}"
description = "Persistent autonomous execution — keep going until fully resolved"
```

---

## Component 5: Wrapper Script (`scripts/droid-run.sh`)

### Purpose
Outermost safety net for multi-hour sessions. Handles context window exhaustion by auto-resuming.

### Behavior
1. Accept task description as argument
2. Launch: `gemini -p "Activate droid skill. Task: $TASK"` (add `--yolo` if policy not installed)
3. Capture exit code
4. If exit 53 (turn limit) or exit 0 but `.gemini/state/droid.json` shows `active: true`:
   - Log session to `.gemini/state/droid-sessions.log`
   - Auto-resume: `gemini --resume`
   - Repeat until `active: false` or max retries (default 5)
5. On final completion: print summary

### Usage
```bash
./scripts/droid-run.sh "build the authentication system end to end"
# or with options:
./scripts/droid-run.sh --max-retries 10 "build the auth system"
```

---

## Component 6: GEMINI.md Additions

### New Section: Execution Continuity
```markdown
## Execution Continuity

- Do not explain a plan and stop. If you can execute safely, execute.
- Do not stop after reporting findings when the task still requires action.
- Do not summarize progress and ask "shall I continue?" — just continue.
- Proceed automatically on clear, low-risk, reversible next steps.
- Ask only when the next step is irreversible, side-effectful, or materially changes scope.
- When executing a multi-step plan, complete ALL steps before reporting back.
- After completing a phase or task, immediately begin the next one.
```

### New Routing Table Entries
```markdown
| Run autonomously without stopping | **droid** (wraps any skill chain with persistence) |
| "Don't stop", "keep going until done" | **droid** |
```

---

## Component 7: Extension Manifest Updates

### `gemini-extension.json`
Add hooks and commands to the manifest:
```json
{
  "name": "superpowers-gemini",
  "version": "1.1.0",
  "description": "Opinionated development workflow skills and agents for Gemini CLI",
  "skills": "./skills",
  "agents": "./agents",
  "hooks": "./hooks",
  "commands": "./commands"
}
```

---

## Component 8: Install Script Updates

### New Flags
- `--with-droid-hook` / `--no-droid-hook`: Toggle hook installation
- Interactive prompt if neither flag given

### New Steps
1. Copy `commands/droid.toml` to target `.gemini/commands/`
2. Copy `policies/droid-auto-approve.toml` to target `.gemini/policies/`
3. If droid hook opted in: copy `hooks/after-agent.sh` to target `.gemini/hooks/`, chmod +x
4. Make `scripts/droid-run.sh` executable

---

## Non-Goals

- Droid does NOT replace autopilot's workflow phases — it wraps them
- Droid does NOT define its own QA, validation, or review steps — it uses whatever the wrapped skill provides
- Droid does NOT handle task decomposition or planning — that's brainstorming + writing-plans
- Droid does NOT provide cross-session memory — session-notes handles that
- No web UI or dashboard — CLI-only

---

## Testing Plan

1. **Skill activation:** Verify droid skill activates on keywords ("droid", "don't stop", "keep going")
2. **State management:** Verify state file created, updated, and cleaned up correctly
3. **Hook behavior:** Test with sample outputs containing stopping signals — verify injection
4. **Hook no-op:** Test with normal outputs — verify hook doesn't interfere
5. **Policy rules:** Verify tools auto-approved without `--yolo` when policy installed
6. **Wrapper script:** Test resume behavior with simulated exit code 53
7. **Integration:** Run a full autopilot pipeline wrapped in droid — verify no pauses at phase boundaries
8. **Fallback mode:** Run without hook installed — verify skill adapts with heavier self-reminders
