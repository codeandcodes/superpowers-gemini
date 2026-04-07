---
name: executing-plans
description: >
  Use when you have a written implementation plan to execute. Load plan, review critically,
  execute all tasks with verification, report when complete.
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

## Vagueness Gate

Before executing, verify the plan is concrete enough:

**Proceed if the plan contains:**
- Specific file paths for each task
- Code blocks showing what to implement
- Test commands with expected output
- Commit messages for each task

**Stop if the plan contains:**
- "TBD", "TODO", or placeholder sections
- Steps that describe what to do without code
- Vague instructions ("add appropriate error handling")
- References to undefined types or functions

If the plan is underspecified: "This plan has gaps that will block execution. Let me flag the issues." Then list the gaps and ask the user whether to fix the plan first or proceed with caveats.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. **Verify context snapshot exists** — if the plan has a context snapshot section, read it to understand the full picture. If not, create one from the plan header.
3. Review critically - identify any questions or concerns about the plan
4. If concerns: Raise them with the user before starting
5. If no concerns: Create task tracking and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Complete Development

After all tasks complete and verified:
- Activate the finishing-a-development-branch skill
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent
