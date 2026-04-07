---
name: ultra-qa
description: >
  Use after implementation is complete to run an autonomous test-fix-retest cycle.
  Runs the full test suite, diagnoses failures, fixes them, and retests — up to 5 cycles.
  Stops early if the same error appears 3 times.
---

# Ultra QA

Autonomous quality assurance cycling. Run tests, diagnose failures, fix, retest — repeat until green or stuck.

**Core principle:** Don't just run tests once. Keep cycling until the suite is clean or you've proven you're stuck.

## When to Use

- After completing implementation of a feature (post Phase 2 in autopilot)
- After a large refactor
- When inheriting code with failing tests
- When "tests pass" needs to be verified systematically, not optimistically

## The QA Cycle

```
For each cycle (max 5):
  1. Run full test suite + build + lint
  2. If all pass → QA complete, exit
  3. If failures → diagnose root cause of EACH failure
  4. Group failures by root cause (many failures often share one cause)
  5. Fix the root causes (use systematic-debugging principles)
  6. Increment cycle counter
  7. Track: which errors have we seen before?
  8. If any error has appeared 3 times → flag as stuck, stop

After 5 cycles or stuck:
  - Report remaining failures with diagnosis
  - Escalate to user
```

## Cycle Rules

### Run Everything

Don't just run unit tests. Run the full verification suite:

```bash
# Example — adapt to the project
npm run build        # or cargo build, go build, etc.
npm run lint         # linter
npm test             # full test suite
```

If the project has type checking, run that too. Every verification command the project supports.

### Diagnose Before Fixing

**Do NOT guess at fixes.** For each failure:

1. Read the full error message and stack trace
2. Identify which test failed and what it expected
3. Trace to the root cause — is it a bug in the implementation, a bad test, a missing dependency?
4. Group related failures — 10 test failures might all stem from 1 broken function

### Fix Minimally

- Fix the root cause, not the symptoms
- One fix per root cause
- Don't refactor while fixing — just make it pass
- Commit each fix separately with a descriptive message

### Track Error Recurrence

Keep a running log of errors seen:

```
Cycle 1: TypeError in parseConfig (3 tests), missing export in utils (2 tests)
Cycle 2: missing export fixed, TypeError still present (3 tests)
Cycle 3: TypeError STILL present — same error 3 times → STUCK
```

**Three-strikes rule:** If the same error (same message, same location) appears in 3 consecutive cycles, stop. You're not making progress on it. Escalate.

### Early Success

If all tests pass on cycle 1, you're done. Don't manufacture work.

## Output Format

After QA completes (success or stuck), report:

```
## QA Report

**Cycles run:** 3
**Final status:** ALL PASS (or: 2 failures remaining)

**Cycle history:**
- Cycle 1: 5 failures (3 TypeError in parseConfig, 2 missing export)
- Cycle 2: 3 failures (fixed missing export; TypeError persists)
- Cycle 3: 0 failures (fixed parseConfig argument handling)

**Fixes applied:**
- Fixed missing export in src/utils.ts (cycle 2)
- Fixed parseConfig argument type mismatch in src/config.ts (cycle 3)

**Remaining issues:** None (or: list with diagnosis)
```

## Integration

**Called by:**
- **autopilot** (Phase 3) — after implementation, before validation
- Can be activated standalone after any implementation work

**Uses:**
- **systematic-debugging** principles for root cause analysis
- **test-driven-development** principles if new tests need to be written
- **verification-before-completion** — QA report IS the verification evidence

## Red Flags

**Never:**
- Skip the build/lint step (tests can pass while build is broken)
- Fix symptoms instead of root causes
- Continue past 5 cycles without escalating
- Ignore the three-strikes rule
- Claim "tests pass" without running them in THIS cycle

**Always:**
- Run ALL verification commands, not just tests
- Diagnose before fixing
- Track error recurrence across cycles
- Commit each fix separately
- Report cycle history, not just final state
