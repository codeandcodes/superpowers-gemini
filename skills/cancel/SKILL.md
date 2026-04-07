---
name: cancel
description: >
  Use when the user wants to stop current work, abandon a plan, reset state, or clean up
  after an interrupted workflow. Performs dependency-aware cleanup of worktrees, branches,
  temp files, and session state.
---

# Cancel and Cleanup

Intelligently stop current work and clean up state. Dependency-aware cleanup that doesn't destroy useful work.

## When to Use

- User says "stop", "cancel", "abort", "start over", "forget this"
- A workflow has gone off track and needs to be abandoned
- Picking up after a crash or interrupted session
- Need to clean up stale worktrees, branches, or temp files

## The Cancel Process

```
1. Assess — What's in progress? What state exists?
2. Confirm — Show user what will be cleaned up, get approval
3. Preserve — Save anything worth keeping
4. Cleanup — Remove state in dependency order
5. Report — Confirm what was cleaned up
```

### Step 1: Assess Current State

Check for active work:

```bash
# Active worktrees
git worktree list

# Uncommitted changes
git status

# Recent branches that might be from this session
git branch --sort=-committerdate | head -10

# Session notes
cat .gemini/session-notes.md 2>/dev/null

# Temp files from skills
ls docs/specs/ docs/plans/ 2>/dev/null
```

### Step 2: Confirm with User

Present what was found and what cleanup would do:

```
Found active work:
- Worktree: .worktrees/feature-auth (branch: feature/auth, 3 commits ahead of main)
- Uncommitted changes: 2 files modified in current directory
- Session notes: .gemini/session-notes.md (last updated 30 min ago)
- Spec file: docs/specs/2024-01-15-auth-design.md

Options:
1. Clean everything — remove worktree, delete branch, discard changes, clear notes
2. Preserve commits — keep the branch but remove worktree, clear other state
3. Preserve all files — only clear session state (notes, tracking), keep code
4. Cancel the cancel — keep everything as-is

Which option?
```

**Never auto-clean without user confirmation.**

### Step 3: Preserve What's Worth Keeping

Before deleting anything:

- **Uncommitted changes with value:** Offer to stash them (`git stash push -m "cancelled: [description]"`)
- **Useful spec or plan files:** Ask if they should be kept for future reference
- **Session notes with decisions:** Decisions log entries may be worth keeping even if the work is cancelled

### Step 4: Cleanup in Dependency Order

Clean up in reverse dependency order (things that depend on other things first):

```
1. Stop any running processes (dev servers, test runners)
2. Clear session state (notes, tracking files)
3. Remove worktrees (git worktree remove <path>)
4. Delete feature branches (git branch -D <branch>, only with user consent)
5. Discard uncommitted changes (git checkout -- . or git stash)
6. Remove generated files (specs, plans — only if user chose "clean everything")
```

**Why dependency order matters:** If you delete the branch before removing the worktree, the worktree cleanup can fail. If you remove the worktree while a dev server is running from it, you get orphaned processes.

### Step 5: Report

```
Cleanup complete:
- Removed worktree: .worktrees/feature-auth
- Deleted branch: feature/auth
- Stashed uncommitted changes (git stash list to recover)
- Cleared session notes
- Preserved: docs/specs/2024-01-15-auth-design.md (per your request)

Current state: clean, on branch main, all tests passing.
```

## Partial Cancel

Sometimes the user wants to cancel one part of the work but keep another:

- "Cancel the frontend work but keep the API changes" → remove frontend worktree/branch, keep API branch
- "Scrap this approach but keep the tests I wrote" → cherry-pick test commits, then clean up
- "Start over but keep the spec" → clean up implementation, preserve spec file

Ask clarifying questions to understand exactly what to keep and what to discard.

## Stale State Detection

When starting a new session, check for stale state from previous sessions:

```bash
# Worktrees that might be stale
git worktree list --porcelain | grep "worktree" | grep -v "$(pwd)"

# Branches with no remote tracking
git branch --no-merged main

# Old session notes
find .gemini -name "session-notes.md" -mtime +7 2>/dev/null
```

If stale state is found, ask: "Found state from a previous session. Want to clean it up?"

## Red Flags

**Never:**
- Delete branches or worktrees without user confirmation
- Discard uncommitted changes without offering to stash
- Force-delete branches that have unpushed commits (warn the user)
- Remove files outside the project directory
- Clean up state that might belong to another user's work

**Always:**
- Show what will be cleaned up before doing it
- Offer to preserve commits (stash or keep branch)
- Clean in dependency order
- Report what was done after cleanup
- Check for running processes before removing directories
