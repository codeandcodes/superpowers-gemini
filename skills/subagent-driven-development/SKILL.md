---
name: subagent-driven-development
description: >
  Use when executing implementation plans with independent tasks. Dispatches a fresh agent
  per task with two-stage review (spec compliance then code quality) after each.
---

# Subagent-Driven Development

Execute plan by dispatching fresh agent per task, with two-stage review after each: spec compliance review first, then code quality review.

**Why agents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. This also preserves your own context for coordination work.

**Core principle:** Fresh agent per task + two-stage review (spec then quality) = high quality, fast iteration

## When to Use

- Have an implementation plan with mostly independent tasks
- Want to stay in the current session
- Want automatic review checkpoints

## The Process

1. **Read plan** -- extract all tasks with full text, note context, create task tracking
2. **For each task:**
   a. Dispatch @implementer agent with full task text + context
   b. If implementer asks questions -- answer them, provide context
   c. Implementer implements, tests, commits, self-reviews
   d. Dispatch @spec-reviewer to verify code matches spec
   e. If spec issues found -- implementer fixes, re-review
   f. Dispatch @code-reviewer for code quality review
   g. If quality issues found -- implementer fixes, re-review
   h. Mark task complete
3. **After all tasks** -- dispatch final @code-reviewer for entire implementation
4. **Activate finishing-a-development-branch skill**

## Handling Implementer Status

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** Read the concerns. If about correctness/scope, address before review. If observations, note and proceed.

**NEEDS_CONTEXT:** Provide missing context and re-dispatch.

**BLOCKED:** Assess the blocker:
1. Context problem -- provide more context
2. Needs more reasoning -- re-dispatch with more capable model
3. Task too large -- break into smaller pieces
4. Plan is wrong -- escalate to the user

**Never** ignore an escalation or force retry without changes.

## Model Selection

- **Mechanical tasks** (isolated functions, clear specs, 1-2 files): use a fast model
- **Integration tasks** (multi-file coordination, debugging): use standard model
- **Architecture/review tasks**: use most capable model

## Red Flags

**Never:**
- Start implementation on main/master without user consent
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed issues
- Dispatch multiple implementation agents in parallel (conflicts)
- Make agent read plan file (provide full text instead)
- Start code quality review before spec compliance passes
- Move to next task while either review has open issues

**If agent asks questions:**
- Answer clearly and completely
- Don't rush them into implementation

**If reviewer finds issues:**
- Implementer fixes them
- Reviewer reviews again
- Repeat until approved
