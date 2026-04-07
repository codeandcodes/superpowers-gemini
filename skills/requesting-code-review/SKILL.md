---
name: requesting-code-review
description: >
  Use when completing tasks, implementing major features, or before merging to verify work
  meets requirements. Dispatches code-reviewer agent for independent review.
---

# Requesting Code Review

Dispatch the code-reviewer agent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation -- never your session's history.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After completing a major feature
- Before merge to main
- After each task in agent-driven development

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code-reviewer agent** using @code-reviewer with:
- What was implemented
- Plan or requirements reference
- Base and head SHA
- Brief description

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Integration with Workflows

**Agent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing Plans:**
- Review after each batch (3 tasks)
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
