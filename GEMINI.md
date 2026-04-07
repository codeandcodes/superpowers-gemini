# Superpowers Workflow

## Skill-First Rule

You have access to a set of agent skills. Before taking action on any user request, check whether an available skill applies. If it does, activate it with `activate_skill` before writing any code or making changes.

**This is not optional.** Even if a task seems simple, check your skills first.

### When to activate which skill

| User intent | Skill to activate |
|-------------|-------------------|
| Build, create, design, or add a feature | **brainstorming** first, then **writing-plans** |
| Build a web page, UI, or frontend component | **frontend-design** (+ brainstorming if new project) |
| Fix a bug, investigate a failure, debug | **systematic-debugging** |
| Implement code for a feature or fix | **test-driven-development** |
| Execute tasks from an implementation plan | **subagent-driven-development** or **executing-plans** |
| Multiple independent problems to solve | **dispatching-parallel-agents** |
| Review a pull request | **code-review** |
| About to claim work is complete | **verification-before-completion** |
| After completing a feature, before merge | **requesting-code-review** |
| Received code review feedback | **receiving-code-review** |
| Need isolated workspace for feature work | **using-git-worktrees** |
| Implementation done, ready to merge/PR | **finishing-a-development-branch** |

### Workflow chain

Most tasks follow this chain. Do not skip steps:

1. **brainstorming** — explore the idea, ask clarifying questions, propose approaches, write a design spec
2. **writing-plans** — create a detailed step-by-step implementation plan from the spec
3. **using-git-worktrees** — create an isolated workspace
4. **subagent-driven-development** — dispatch @implementer per task, with @spec-reviewer and @code-reviewer after each
5. **verification-before-completion** — run tests, verify output before claiming done
6. **finishing-a-development-branch** — present merge/PR/discard options

### Agents available

You have these custom agents for delegation:

- **@implementer** — executes a specific task from a plan (TDD, self-review, commit)
- **@spec-reviewer** — verifies implementation matches spec (read-only)
- **@code-reviewer** — reviews code quality against plan and standards (read-only)
- **@code-simplifier** — simplifies recently modified code
- **@explorer** — read-only codebase investigation
- **@planner** — architecture analysis and plan creation (read-only)

### Key principles

- **Never skip brainstorming** for new features — even "simple" ones need a design check
- **Never write code before tests** — activate test-driven-development
- **Never claim done without evidence** — activate verification-before-completion
- **Never fix bugs by guessing** — activate systematic-debugging
- **Use agents for isolation** — dispatch @implementer instead of coding everything in the main session
