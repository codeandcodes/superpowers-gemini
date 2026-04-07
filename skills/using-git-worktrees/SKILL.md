---
name: using-git-worktrees
description: >
  Use when starting feature work that needs isolation from current workspace or before
  executing implementation plans. Creates isolated git worktrees with safety verification.
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

## Directory Selection Process

### 1. Check Existing Directories

```bash
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```

If found, use that directory. If both exist, `.worktrees` wins.

### 2. Check Project Config

Check GEMINI.md or CLAUDE.md for worktree directory preferences.

### 3. Ask User

If no directory exists and no config preference:

```
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (project-local, hidden)
2. ~/worktrees/<project-name>/ (global location)

Which would you prefer?
```

## Safety Verification

For project-local directories, verify the directory is in .gitignore:

```bash
git check-ignore -q .worktrees 2>/dev/null
```

If NOT ignored: add to .gitignore and commit before creating worktree.

## Creation Steps

1. **Detect Project Name:** `basename "$(git rev-parse --show-toplevel)"`

2. **Create Worktree:**
```bash
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

3. **Run Project Setup:** Auto-detect from project files (package.json, Cargo.toml, requirements.txt, go.mod)

4. **Verify Clean Baseline:** Run tests. If tests fail, report and ask whether to proceed.

5. **Report Location:**
```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Red Flags

**Never:**
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking
- Assume directory location when ambiguous

**Always:**
- Follow directory priority: existing > config > ask
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean test baseline
