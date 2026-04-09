# Superpowers Workflow

## Skill-First Rule

You have access to a set of agent skills. Before taking action on any user request, check whether an available skill applies. If it does, activate it with `activate_skill` before writing any code or making changes.

**This is not optional.** Even if a task seems simple, check your skills first.

### When to activate which skill

| User intent | Skill to activate |
|-------------|-------------------|
| Build a large feature end-to-end autonomously | **autopilot** (chains all skills automatically) |
| Build, create, design, or add a feature | **brainstorming** first, then **writing-plans** |
| Build a web page, UI, or frontend component | **frontend-design** (+ brainstorming if new project) |
| Fix a bug, investigate a failure, debug | **systematic-debugging** |
| Implement code for a feature or fix | **test-driven-development** |
| Execute tasks from an implementation plan | **subagent-driven-development** or **executing-plans** |
| Multiple independent problems to solve | **dispatching-parallel-agents** |
| Tests failing after implementation | **ultra-qa** (autonomous test-fix-retest cycle) |
| Code works but looks AI-generated | **slop-cleaner** (structured cleanup) |
| Review a pull request | **code-review** |
| About to claim work is complete | **verification-before-completion** |
| After completing a feature, before merge | **requesting-code-review** |
| Received code review feedback | **receiving-code-review** |
| Verify frontend matches a design/mockup | **visual-verdict** (screenshot comparison with scoring) |
| Clone or recreate a website from a URL | **web-clone** (extract → generate → verify loop) |
| Long session, need to persist context | **session-notes** (save decisions and state to file) |
| Stop work, abandon plan, clean up state | **cancel** (dependency-aware cleanup) |
| Need isolated workspace for feature work | **using-git-worktrees** |
| Implementation done, ready to merge/PR | **finishing-a-development-branch** |
| Run autonomously without stopping | **droid** (wraps any skill chain with persistence) |
| "Don't stop", "keep going until done" | **droid** |

### Workflow chain

Most tasks follow this chain. Do not skip steps:

1. **brainstorming** — deep interview with ambiguity scoring, challenge modes, then write design spec
2. **writing-plans** — create a detailed step-by-step implementation plan from the spec
3. **using-git-worktrees** — create an isolated workspace
4. **subagent-driven-development** — delegate to agents per task with review after each
5. **ultra-qa** — autonomous test-fix-retest cycle until green
6. **slop-cleaner** — structured cleanup of AI-generated code smells
7. **verification-before-completion** — run tests, verify output before claiming done
8. **finishing-a-development-branch** — present merge/PR/discard options

For end-to-end autonomous execution, use **autopilot** which chains all of the above automatically.

For persistent autonomous execution that doesn't pause between steps, wrap any workflow with **droid**.

## Agent Delegation

You have custom agents available as sub-agents. **Use them.** Do not do everything in the main session — delegate implementation and review work to agents so they run in isolated context.

### Available agents

| Agent | Role | When to delegate |
|-------|------|-----------------|
| **implementer** | Executes a specific task from a plan: codes, tests (TDD), commits, self-reviews | For each task in an implementation plan. Give it the full task text, context, and working directory. |
| **spec-reviewer** | Read-only. Verifies implementation matches spec — checks for missing requirements, extra work, misunderstandings | After the `implementer` agent completes a task. Give it the spec and the implementer's report. |
| **code-reviewer** | Read-only. Reviews code quality, architecture, patterns, and plan alignment | After spec-reviewer passes. Also use for final review after all tasks complete. |
| **code-simplifier** | Simplifies and refines recently modified code while preserving behavior | After implementation is complete and reviewed, if code needs cleanup. |
| **explorer** | Read-only. Investigates codebase: finds files, traces dependencies, answers structural questions | When you need to understand existing code before making changes. |
| **planner** | Read-only. Analyzes architecture, creates step-by-step implementation plans | When you need a detailed plan but want to preserve main session context. |

### The implementation cycle

When executing a plan with multiple tasks, follow this cycle for each task:

```
For each task:
  1. Delegate to `implementer` agent with full task text + context
  2. If implementer reports NEEDS_CONTEXT or BLOCKED → provide info and re-delegate
  3. If implementer reports DONE → delegate to `spec-reviewer` agent
  4. If spec-reviewer finds issues → send back to implementer to fix, then re-review
  5. If spec-reviewer passes → delegate to `code-reviewer` agent
  6. If code-reviewer finds issues → send back to implementer to fix, then re-review
  7. If code-reviewer passes → mark task complete, move to next task

After all tasks:
  8. Delegate to `code-reviewer` agent for final review of entire implementation
```

### Agent delegation rules

- **Always give agents complete context** — paste the full task text, don't make them read files to understand what to do
- **Never skip the review cycle** — every implementer task gets spec-review then code-review
- **Don't do implementation work in the main session** — delegate to the `implementer` agent instead
- **Handle agent escalations** — if an agent reports BLOCKED or NEEDS_CONTEXT, help it rather than ignoring the report
- **Use the right agent for the job** — don't ask the `explorer` agent to write code, don't ask the `implementer` agent to review

## Key principles

- **Never skip brainstorming** for new features — even "simple" ones need a design check
- **Never write code before tests** — activate test-driven-development
- **Never claim done without evidence** — activate verification-before-completion
- **Never fix bugs by guessing** — activate systematic-debugging
- **Use agents for isolation** — delegate to the `implementer` agent instead of coding everything in the main session
- **Review everything** — delegate to `spec-reviewer` then `code-reviewer` after each task

## Execution Continuity

When executing multi-step plans or skill chains:

- Do not explain a plan and stop. If you can execute safely, execute.
- Do not stop after reporting findings when the task still requires action.
- Do not summarize progress and ask "shall I continue?" — just continue.
- Proceed automatically on clear, low-risk, reversible next steps.
- Ask only when the next step is irreversible, side-effectful, or materially changes scope.
- When executing a multi-step plan, complete ALL steps before reporting back.
- After completing a phase or task, immediately begin the next one.
