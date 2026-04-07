# superpowers-gemini

Opinionated development workflow skills and agents for [Gemini CLI](https://github.com/google-gemini/gemini-cli). Ported from the [Superpowers](https://github.com/anthropics/claude-plugins-official) plugin for Claude Code.

## What's included

### Skills (activated on-demand by the model)

| Skill | When it activates |
|-------|-------------------|
| **brainstorming** | Before any creative work -- explores intent and design before code |
| **writing-plans** | When you have a spec and need a step-by-step implementation plan |
| **executing-plans** | When executing a plan inline with verification checkpoints |
| **subagent-driven-development** | When executing plans via agent-per-task with 2-stage review |
| **test-driven-development** | Before writing any implementation code (red-green-refactor) |
| **systematic-debugging** | When encountering bugs -- enforces root cause before fixes |
| **verification-before-completion** | Before claiming work is done -- evidence before assertions |
| **requesting-code-review** | After completing features, before merging |
| **receiving-code-review** | When handling review feedback with technical rigor |
| **dispatching-parallel-agents** | When facing 2+ independent problems |
| **finishing-a-development-branch** | When implementation is done and you need merge/PR/cleanup |
| **using-git-worktrees** | When starting feature work that needs isolation |
| **frontend-design** | When building web components/pages with distinctive design |
| **code-review** | When reviewing a pull request |

### Agents (dispatched as subagents by the model or via `@agent-name`)

| Agent | Model tier | Purpose |
|-------|------------|---------|
| **@code-reviewer** | strong | Reviews completed work against plans and standards |
| **@code-simplifier** | strong | Simplifies code for clarity while preserving behavior |
| **@implementer** | fast | Executes specific plan tasks with TDD and self-review |
| **@spec-reviewer** | fast | Verifies implementation matches spec exactly |
| **@explorer** | fast | Read-only codebase exploration and investigation |
| **@planner** | strong | Architecture analysis and implementation planning |

Model tiers are configured in `config.json` (defaults: strong=`gemini-2.5-pro`, fast=`gemini-2.5-flash`).

## Requirements

- [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and authenticated
- A Gemini API key or Google Cloud auth configured

## Install

### Option A: Gemini CLI native (recommended)

```bash
gemini extensions install https://github.com/codeandcodes/superpowers-gemini.git
```

### Option B: Install script (recommended for custom models)

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

# Check current model config
./install.sh config

# Uninstall
./install.sh uninstall
```

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

If you used `gemini extensions install` (Option A), agent files keep the `{{MODEL}}` placeholder -- run the install script afterward to resolve them.

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
- All 14 skills have valid frontmatter (name + description)
- All 6 agents have resolved models (no `{{MODEL}}` placeholders)
- Gemini CLI can discover the installed skills

### Skill activation

Skills activate automatically -- the model reads each skill's `description` field and decides when to use it. No manual configuration needed.

To disable a specific skill:
```bash
# Interactive
/skills disable brainstorming

# CLI
gemini skills disable brainstorming
```

### Agent invocation

Agents can be invoked two ways:
- **Automatic:** The model delegates when a task matches an agent's description
- **Explicit:** Type `@agent-name <task>` in the prompt (e.g., `@code-reviewer review the latest commit`)

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
│   └── code-review/SKILL.md
└── agents/
    ├── code-reviewer.md
    ├── code-simplifier.md
    ├── implementer.md
    ├── spec-reviewer.md
    ├── explorer.md
    └── planner.md
```

## How it works

**Skills** are markdown files with a `name` and `description` in YAML frontmatter. At session start, Gemini CLI loads all skill descriptions into context. When the model recognizes a task matching a skill's description, it calls `activate_skill` to load the full instructions into the conversation.

**Agents** are markdown files that define isolated subagents with their own model, tool access, and system prompt. The model delegates tasks to agents automatically or users invoke them with `@agent-name`. Agents run in isolated context windows and report results back.

## Ported from

These skills and agents are adapted from:
- [Superpowers](https://github.com/anthropics/claude-plugins-official) plugin for Claude Code
- [Frontend Design](https://github.com/anthropics/claude-plugins-official) plugin for Claude Code
- [Code Review](https://github.com/anthropics/claude-plugins-official) plugin for Claude Code

Adapted for Gemini CLI's skill/agent format, tool names, and model identifiers.

## License

MIT
