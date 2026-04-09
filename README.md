# superpowers-gemini

Opinionated development workflow skills and agents for [Gemini CLI](https://github.com/google-gemini/gemini-cli). Ported from the [Superpowers](https://github.com/anthropics/claude-plugins-official) plugin for Claude Code.

## What's included

### Skills (activated on-demand by the model)

| Skill | When it activates |
|-------|-------------------|
| **autopilot** | End-to-end autonomous pipeline: idea to working code with QA and validation |
| **brainstorming** | Before any creative work -- deep interview with ambiguity scoring and challenge modes |
| **writing-plans** | When you have a spec and need a step-by-step implementation plan |
| **executing-plans** | When executing a plan inline with verification checkpoints |
| **subagent-driven-development** | When executing plans via agent-per-task with 2-stage review |
| **test-driven-development** | Before writing any implementation code (red-green-refactor) |
| **systematic-debugging** | When encountering bugs -- enforces root cause before fixes |
| **ultra-qa** | After implementation -- autonomous test-fix-retest cycle (max 5 rounds) |
| **slop-cleaner** | After implementation -- structured cleanup of AI-generated code smells |
| **verification-before-completion** | Before claiming work is done -- evidence before assertions |
| **requesting-code-review** | After completing features, before merging |
| **receiving-code-review** | When handling review feedback with technical rigor |
| **dispatching-parallel-agents** | When facing 2+ independent problems |
| **finishing-a-development-branch** | When implementation is done and you need merge/PR/cleanup |
| **using-git-worktrees** | When starting feature work that needs isolation |
| **visual-verdict** | After frontend work -- screenshot comparison with structured scoring loop |
| **web-clone** | When cloning/recreating a website from a URL with visual verification |
| **session-notes** | During long sessions -- persist decisions and context to survive compression |
| **cancel** | When stopping work -- dependency-aware cleanup of branches, worktrees, state |
| **droid** | Persistent autonomous execution -- wraps any skill chain to keep going without pausing |
| **frontend-design** | When building web components/pages with distinctive design |
| **code-review** | When reviewing a pull request |

### Agents (delegated as sub-agents by the model)

| Agent | Model tier | Purpose |
|-------|------------|---------|
| **implementer** | medium | Executes specific plan tasks with TDD, self-review, and commit |
| **spec-reviewer** | fast | Verifies implementation matches spec exactly (read-only) |
| **code-reviewer** | strong | Reviews code quality against plans and standards (read-only) |
| **code-simplifier** | strong | Simplifies code for clarity while preserving behavior |
| **explorer** | fast | Read-only codebase exploration and investigation |
| **planner** | strong | Architecture analysis and implementation planning (read-only) |

Model tiers are configured in `config.json` (defaults: strong=`gemini-2.5-pro`, medium=`gemini-2.5-flash`, fast=`gemini-2.5-flash`).

## Requirements

- [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and authenticated
- A Gemini API key or Google Cloud auth configured

## Install

### Option A: Install script (recommended)

```bash
# Clone the repo
git clone https://github.com/codeandcodes/superpowers-gemini.git
cd superpowers-gemini

# (Optional) Edit config.json to set your preferred models
# Then install -- agent files are templated with your model choices

# Install globally (available in all projects)
./install.sh user

# Or install into a specific project
./install.sh project /path/to/your/project

# Verify installation
./install.sh doctor

# Check current model config
./install.sh config

# Uninstall
./install.sh uninstall
```

### Option B: Gemini CLI native extension

```bash
gemini extensions install https://github.com/codeandcodes/superpowers-gemini.git
```

Note: native install copies files as-is without resolving model templates. You'll need to run `./install.sh` afterward to resolve `{{MODEL}}` placeholders in agent files, and to install `GEMINI.md`.

## Configuration

### Model names

Agent models are configured in `config.json`. Define model tiers, then assign each agent to a tier (or override with a direct model ID):

```json
{
  "models": {
    "tiers": {
      "strong": "gemini-2.5-pro",
      "medium": "gemini-2.5-flash",
      "fast":   "gemini-2.5-flash"
    },
    "agents": {
      "code-reviewer":   "strong",
      "code-simplifier": "strong",
      "planner":         "strong",
      "implementer":     "medium",
      "spec-reviewer":   "fast",
      "explorer":        "fast"
    }
  }
}
```

**Tier defaults:**

| Tier | Default model | Agents |
|------|---------------|--------|
| **strong** | `gemini-2.5-pro` | code-reviewer, code-simplifier, planner |
| **medium** | `gemini-2.5-flash` | implementer |
| **fast** | `gemini-2.5-flash` | spec-reviewer, explorer |

**Per-agent overrides:** An agent's value can be a tier name (`"strong"`, `"medium"`, `"fast"`) or a direct model ID (e.g., `"gemini-2.0-flash-thinking-exp"`). Direct IDs bypass tier lookup entirely.

```json
"agents": {
  "explorer": "gemini-2.0-flash-thinking-exp",
  "implementer": "strong"
}
```

Edit `config.json` before running `./install.sh`. The install script reads the config and templates the resolved model into each agent file during installation. Run `./install.sh config` to preview what will be installed.

### Verifying installation

Run the doctor to check everything is healthy:

```bash
./install.sh doctor              # Check all locations (cwd + ~/.gemini)
./install.sh doctor ~/myapp      # Check a specific project
```

Doctor checks:
- Gemini CLI is installed
- python3 or node available (for config resolution)
- config.json is valid and complete
- All skills have valid frontmatter (name + description)
- All agents have resolved models (no `{{MODEL}}` placeholders)
- GEMINI.md is present with skill-first workflow instructions
- Gemini CLI can discover the installed skills
- Droid hook installed and executable (if opted in)
- Droid policy and command files present

### Skill activation

Skills activate automatically -- the model reads each skill's `description` field and decides when to use it. No manual configuration needed.

The included `GEMINI.md` reinforces this by telling the model to always check skills before acting. Without it, the model may skip skills entirely.

To disable a specific skill:
```bash
/skills disable brainstorming           # Interactive
gemini skills disable brainstorming     # CLI
```

### Agent delegation

Agents are delegated by the model as sub-agents when a task matches their description. The `GEMINI.md` file includes explicit delegation rules and the implementation cycle:

```
implementer → spec-reviewer → code-reviewer (repeat per task)
```

The model can also be directed to use an agent explicitly in conversation.

### Customization

**Change default spec/plan locations:** Edit the skills that reference `docs/specs/` or `docs/plans/` paths (brainstorming, writing-plans).

**Adjust agent tool access:** Edit the `tools:` list in any agent's frontmatter to grant or restrict capabilities.

**Adjust agent limits:** Edit `max_turns:` and `timeout_mins:` in agent frontmatter.

## Project structure

```
superpowers-gemini/
├── gemini-extension.json    # Extension manifest for native install
├── config.json              # Model configuration (edit before install)
├── install.sh               # Shell installer (reads config.json, templates agents)
├── GEMINI.md                # Skill-first workflow + agent delegation instructions
├── README.md
├── skills/
│   ├── brainstorming/SKILL.md
│   ├── writing-plans/SKILL.md
│   ├── executing-plans/SKILL.md
│   ├── subagent-driven-development/SKILL.md
│   ├── test-driven-development/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   ├── verification-before-completion/SKILL.md
│   ├── requesting-code-review/SKILL.md
│   ├── receiving-code-review/SKILL.md
│   ├── dispatching-parallel-agents/SKILL.md
│   ├── finishing-a-development-branch/SKILL.md
│   ├── using-git-worktrees/SKILL.md
│   ├── frontend-design/SKILL.md
│   ├── code-review/SKILL.md
│   ├── autopilot/SKILL.md
│   ├── ultra-qa/SKILL.md
│   ├── slop-cleaner/SKILL.md
│   ├── visual-verdict/SKILL.md
│   ├── web-clone/SKILL.md
│   ├── session-notes/SKILL.md
│   ├── cancel/SKILL.md
│   └── droid/SKILL.md
├── agents/
│   ├── code-reviewer.md
│   ├── code-simplifier.md
│   ├── implementer.md
│   ├── spec-reviewer.md
│   ├── explorer.md
│   └── planner.md
├── hooks/
│   └── after-agent.sh       # Droid auto-continuation hook (optional)
├── commands/
│   └── droid.toml            # /droid custom command
├── policies/
│   └── droid-auto-approve.toml  # Tool auto-approval rules
└── scripts/
    └── droid-run.sh          # Wrapper for multi-hour sessions
```

## How it works

Three layers work together:

**Skills** are markdown files with a `name` and `description` in YAML frontmatter. At session start, Gemini CLI loads all skill descriptions into context. When the model recognizes a task matching a skill's description, it calls `activate_skill` to load the full instructions into the conversation. Skills tell the model *what workflow to follow* (brainstorm before coding, use TDD, verify before claiming done).

**Agents** are markdown files that define isolated sub-agents with their own model, tool access, and system prompt. The model delegates tasks to agents, which run in isolated context windows and report results back. Agents do the *actual work* -- implementing code, reviewing specs, checking quality.

**GEMINI.md** is the critical glue. Gemini CLI injects skill descriptions and agent definitions into the system prompt, but the model won't reliably use them without explicit instructions. The included `GEMINI.md` provides:
- **Skill-first rule** -- always check available skills before taking action
- **Skill routing table** -- maps user intents to specific skills
- **Agent delegation rules** -- when and how to delegate to each agent
- **Implementation cycle** -- the `implementer` → `spec-reviewer` → `code-reviewer` loop

Without `GEMINI.md`, the model will likely ignore skills and agents, and just start coding directly. This is equivalent to Claude Code's `using-superpowers` meta-skill.

## Droid: Persistent Autonomous Execution

Droid is a layered persistence system that keeps Gemini running through multi-step plans without pausing to ask "shall I continue?" at every phase or task boundary.

### The Problem

When running multi-step workflows (autopilot, executing-plans, etc.), Gemini's model tends to pause at phase and task boundaries to ask for confirmation. This breaks long-running autonomous sessions and requires the user to repeatedly type "continue". Droid solves this with four independent layers of persistence:

### Architecture

```
Layer 1: Droid Skill (prompt-level)          — handles ~80% of pauses
Layer 2: AfterAgent Hook (script-level)      — catches ~15% the skill misses
Layer 3: Policy Rules (config-level)         — removes tool approval friction
Layer 4: Wrapper Script (process-level)      — recovers from context exhaustion
```

Each layer is independently useful. Use any subset.

### Quick Start

**Simplest -- just use the skill:**
```
> /droid build the authentication system end to end
```

**With auto-approval (no --yolo needed):**
```bash
# During install, the policy is installed automatically
./install.sh project
```

**For multi-hour sessions:**
```bash
./scripts/droid-run.sh "build the authentication system end to end"
```

### Layer 1: Droid Skill

The skill wraps any workflow (autopilot, executing-plans, etc.) with aggressive continuation behavior:

- **Execution policy:** "KEEP GOING UNTIL THE TASK IS FULLY RESOLVED"
- **State tracking:** `.gemini/state/droid.json` persists iteration count, phase, and task
- **Adaptive mode:** Detects whether the hook is installed and adjusts verbosity
  - Hook present: runs lean (hook catches pauses)
  - Hook absent: runs heavy (adds self-reminder prompts at transitions)
- **Max iterations:** Default 50, prevents infinite loops

**Activation keywords:** "droid", "don't stop", "keep going until done", "run autonomously"

### Layer 2: AfterAgent Hook

A shell script that runs after every model turn. When droid is active, it detects stopping signals in the model's output and injects a continuation message.

**Detected patterns:**
- "Shall I continue?", "Would you like me to...", "Ready to proceed?"
- "Let me know if...", "Want me to...", "Should I proceed?"
- Output ending with a question and no tool calls

**Installation is optional.** Enable during install:
```bash
./install.sh --with-droid-hook project   # enable
./install.sh --no-droid-hook project     # skip (default: asks interactively)
```

When the hook is not installed, the droid skill compensates with heavier self-reminder prompts.

### Layer 3: Policy Rules

TOML-based tool auto-approval rules that replace `--yolo` with granular control:

**Always approved (read-only):**
- `read_file`, `glob`, `grep_search`, `list_directory`, `web_search`, `web_fetch`

**Approved for autonomous execution (write):**
- `write_file`, `replace`, `run_shell_command`

**Always denied (safety):**
- `rm -rf /` (recursive root deletion)
- `git push --force` (force push)
- `DROP TABLE` / `DROP DATABASE` (destructive SQL)

Installed automatically with `./install.sh`. To disable, remove `.gemini/policies/droid-auto-approve.toml`.

### Layer 4: Wrapper Script

For multi-hour sessions that exceed the context window. The script launches Gemini, detects when the session ends with work still incomplete, and auto-resumes:

```bash
./scripts/droid-run.sh "build the authentication system"
./scripts/droid-run.sh --max-retries 10 "build the auth system"
./scripts/droid-run.sh --no-yolo "task description"
```

**How it works:**
1. Launches Gemini with the droid skill
2. On session end, checks `.gemini/state/droid.json`
3. If `active: true`, auto-resumes with `gemini --resume`
4. Repeats up to `--max-retries` times (default 5)
5. Logs to `.gemini/state/droid-sessions.log`

### Droid Configuration

| Setting | Default | How to change |
|---------|---------|---------------|
| Max iterations (skill) | 50 | Edit `skills/droid/SKILL.md` |
| Max retries (wrapper) | 5 | `--max-retries N` flag |
| Hook enabled | interactive | `--with-droid-hook` / `--no-droid-hook` |
| Policy enabled | yes | Remove `.gemini/policies/droid-auto-approve.toml` to disable |
| Yolo in wrapper | yes | `--no-yolo` flag |

### Droid State Files

| File | Purpose | Created by |
|------|---------|------------|
| `.gemini/state/droid.json` | Active session state | Droid skill |
| `.gemini/state/droid-sessions.log` | Session history | Wrapper script |
| `.gemini/hooks/after-agent.sh` | Auto-continuation hook | install.sh |
| `.gemini/policies/droid-auto-approve.toml` | Tool approval rules | install.sh |
| `.gemini/commands/droid.toml` | /droid command | install.sh |

## Ported from

These skills and agents are adapted from:
- [Superpowers](https://github.com/anthropics/claude-plugins-official) plugin for Claude Code
- [Frontend Design](https://github.com/anthropics/claude-plugins-official) plugin for Claude Code
- [Code Review](https://github.com/anthropics/claude-plugins-official) plugin for Claude Code

Adapted for Gemini CLI's skill/agent format, tool names, and model identifiers.

## License

MIT
