---
name: session-notes
description: >
  Use during long sessions to persist important context that might be lost to context window
  limits. Saves priority notes, working memory, and decisions to a session file that can be
  re-read when context gets compressed.
---

# Session Notes

Persistent notes for long-running sessions. Save important context to a file so it survives context window compression.

## When to Use

- Working on a multi-hour session with many steps
- About to hit context limits (conversation getting very long)
- Want to preserve key decisions, findings, or state across context boundaries
- Picking up work from a previous session
- User says "remember this", "note this down", "don't forget"

## Note Types

### Priority Notes (always reload)

Critical context that must be available at all times:
- Active task and current step
- Key architectural decisions made in this session
- Blockers or open questions
- User preferences expressed during the session

### Working Memory (auto-prune)

Temporary state useful for current work:
- Error messages being investigated
- Files recently modified
- Test results from recent runs
- Intermediate findings during debugging

### Decisions Log

Permanent record of choices made and why:
- "Chose approach A over B because..."
- "User decided to skip X for now because..."
- "Discovered that Y doesn't work because..."

## File Format

Save to `.gemini/session-notes.md` (or `docs/session-notes.md` if `.gemini` isn't appropriate):

```markdown
# Session Notes

**Updated:** [timestamp]
**Active task:** [what we're working on]

## Priority (always reload these first)

- [Critical context item 1]
- [Critical context item 2]

## Working Memory

- [Temporary state item 1]
- [Temporary state item 2]

## Decisions

- [YYYY-MM-DD] [Decision]: [reason]
- [YYYY-MM-DD] [Decision]: [reason]

## Completed

- [x] [Previously active item, now done]
```

## When to Save

**Proactively save after:**
- A key decision is made
- A significant finding during debugging
- The user expresses a preference or constraint
- Completing a major step in a plan
- Before a potentially long operation

**Reactively save when:**
- The user asks you to remember something
- You notice the conversation is getting very long
- You're about to switch to a different area of work

## When to Load

**At session start:**
- Check for existing session notes file
- If found, read it and acknowledge: "Found session notes from a previous session. Resuming context..."

**During session:**
- If you feel like you're missing context about a decision or the current state, re-read the notes
- If the user references something you can't recall, check the notes

## Pruning

Working memory items should be pruned when:
- The task they relate to is complete
- The information is no longer relevant (error was fixed, file was deleted)
- More than 24 hours have passed

Priority notes should only be pruned when:
- The user explicitly says to remove them
- The project/feature they relate to is complete

Decisions are never pruned — they're the permanent record.

## Integration

**Used by any long-running skill, especially:**
- **autopilot** — multi-phase pipeline can benefit from persistent notes
- **subagent-driven-development** — track which tasks are complete, what context agents need
- **systematic-debugging** — persist investigation findings across cycles

## Red Flags

**Never:**
- Store sensitive data (API keys, passwords, tokens) in session notes
- Let notes become a dump of everything — keep them concise and relevant
- Rely solely on notes — always verify against actual file state
- Overwrite notes without reading them first (they may have content from a previous session)

**Always:**
- Timestamp entries
- Distinguish between priority (permanent) and working memory (temporary)
- Prune working memory regularly
- Read notes at session start if they exist
