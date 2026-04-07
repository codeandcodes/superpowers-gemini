---
name: autopilot
description: >
  Use when the user wants end-to-end autonomous execution from idea to working code.
  Chains brainstorming, planning, implementation, QA, validation, and cleanup into a
  single pipeline. Ideal for large features or greenfield projects.
---

# Autopilot

End-to-end autonomous pipeline from idea to working code. Chains all workflow skills into a single execution flow with quality gates between phases.

## When to Use

- User describes a feature, project, or system to build
- User says "build this", "implement this end to end", "take this from idea to done"
- The work is large enough to need planning (not a quick fix or one-file change)

## The Pipeline

```
Phase 0: Expand → Phase 1: Plan → Phase 2: Execute → Phase 3: QA → Phase 4: Validate → Phase 5: Cleanup
```

Each phase has a gate. If a gate fails, fix and retry — do not skip forward.

### Phase 0: Expand Idea into Spec

**Gate: Is the request specific enough to plan?**

Check for concrete signals: file paths, function names, test commands, numbered steps, technology choices. If the request has these, proceed. If it's vague ("build me something cool"), activate the **brainstorming** skill first.

Create a **context snapshot** before proceeding (see Context Intake below).

**Action:** Activate **brainstorming** skill.
- Explore project context
- Ask clarifying questions (one at a time)
- Propose approaches
- Write design spec
- Get user approval

**Gate check:** Spec exists, user approved it. Proceed to Phase 1.

### Phase 1: Plan

**Action:** Activate **writing-plans** skill.
- Create detailed implementation plan from spec
- Bite-sized tasks with TDD steps
- Self-review plan against spec

**Gate check:** Plan exists, self-review passed. Proceed to Phase 2.

### Phase 2: Execute

**Action:** Activate **using-git-worktrees** skill to create isolated workspace, then activate **subagent-driven-development** skill.
- Delegate to `implementer` agent per task
- `spec-reviewer` after each task
- `code-reviewer` after each task
- Fix issues before moving to next task

**Gate check:** All tasks complete, all reviews passed. Proceed to Phase 3.

### Phase 3: QA Cycling

**Action:** Activate **ultra-qa** skill.
- Run full test suite
- If failures: diagnose → fix → retest
- Max 5 cycles
- Early exit if same error appears 3 times

**Gate check:** All tests pass, build clean. Proceed to Phase 4.

### Phase 4: Multi-Perspective Validation

Run three parallel validation checks:

1. **Functional completeness** — delegate to `spec-reviewer` agent with the original spec. Does the implementation cover every requirement?
2. **Code quality** — delegate to `code-reviewer` agent for final review of entire implementation against the plan.
3. **Spec self-check** — re-read the original spec yourself and verify each requirement has been met. Create a checklist and check each item.

**Gate check:** All three validations pass. If any fails, return to Phase 2 for targeted fixes, then re-validate.

### Phase 5: Cleanup

**Action:** Activate **slop-cleaner** skill on all changed files.
- Lock behavior with existing tests
- Clean up AI-generated code smells
- Verify no regressions

Then activate **finishing-a-development-branch** skill.
- Verify tests pass on final state
- Present merge/PR/discard options

## Context Intake

**Before Phase 0 begins**, create a context snapshot and save it alongside the spec:

```markdown
## Context Snapshot

**Task:** [What the user asked for — their words]
**Desired outcome:** [What success looks like]
**Known facts:** [What we know about the codebase, constraints, etc.]
**Constraints:** [Time, technology, compatibility requirements]
**Unknowns:** [What we need to figure out]
**Codebase touchpoints:** [Key files/modules that will be affected]
```

This snapshot is referenced by all phases to stay grounded.

## Vagueness Detection

Before entering the pipeline, check whether the request is specific enough:

**Concrete signals (proceed):**
- File paths or directory references
- Function/class/component names
- Technology choices or framework references
- Numbered steps or ordered requirements
- Test commands or expected behaviors
- Issue numbers or PR references

**Vague signals (redirect to brainstorming):**
- No file paths, no function names
- Abstract descriptions ("make it better", "add a feature")
- No success criteria
- Scope is unclear

If vague: "This request needs more definition before I can plan it. Let me start with some clarifying questions." Then activate **brainstorming**.

## Red Flags

**Never:**
- Skip Phase 0 (even if user says "just build it")
- Skip Phase 3 QA (even if tests passed during Phase 2)
- Skip Phase 4 validation (even if QA passed — validation checks completeness, not just correctness)
- Proceed past a failed gate
- Do Phase 2 on main/master without user consent

**Always:**
- Create context snapshot before starting
- Get user approval after Phase 0 (spec) and Phase 1 (plan)
- Run the full QA cycle, not just "tests pass"
- Do multi-perspective validation, not just one check
- Clean up AI slop before finishing
