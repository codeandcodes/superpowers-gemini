---
name: slop-cleaner
description: >
  Use after implementation and review are complete to clean up AI-generated code smells.
  Structured cleanup workflow: lock behavior with tests, then clean smell-by-smell
  (dead code, duplicates, naming, test reinforcement). Verifies no regressions after each pass.
---

# Slop Cleaner

Structured cleanup of AI-generated code smells. Lock behavior first, then clean systematically.

**Core principle:** AI-generated code works but accumulates characteristic smells — over-abstraction, redundant comments, inconsistent naming, dead code, unnecessary error handling. Clean these up without changing behavior.

## When to Use

- After autopilot completes implementation (Phase 5)
- After any agent-driven implementation session
- When code works but "feels AI-generated"
- When reviewing code and noticing patterns like excessive comments, unnecessary abstractions, or inconsistent style

## The Cleanup Pipeline

```
Step 1: Lock behavior (tests)
Step 2: Create cleanup plan
Step 3: Execute smell-by-smell passes
Step 4: Final regression check
```

### Step 1: Lock Behavior

**Before changing ANYTHING**, verify the test suite captures current behavior:

```bash
# Run full test suite — note the exact pass count
npm test   # or equivalent

# Record baseline
# Example: "47 tests, 47 passing, 0 failing"
```

If test coverage is thin for the files you're about to clean:
- Write characterization tests that capture current behavior
- These tests don't need to be elegant — they just need to detect regressions
- Commit the characterization tests before starting cleanup

**Gate:** Test suite passes. Baseline recorded. Proceed.

### Step 2: Create Cleanup Plan

Scan all changed/new files for AI code smells. Create a prioritized list:

**Smell categories (in cleanup order):**

1. **Dead code** — unused imports, unreachable branches, commented-out code, unused variables/functions
2. **Over-abstraction** — unnecessary wrapper functions, premature abstractions used only once, interfaces with a single implementation
3. **Redundant comments** — comments that restate the code, JSDoc on obvious functions, "// end of function" markers
4. **Naming inconsistencies** — mixed conventions (camelCase vs snake_case in same file), vague names (data, result, item, handle), overly verbose names
5. **Unnecessary error handling** — try/catch around code that can't throw, redundant null checks on guaranteed values, defensive code against impossible states
6. **Duplication** — copy-pasted code blocks, near-identical functions that should be consolidated
7. **Test reinforcement** — tests that test mocks instead of behavior, overly broad assertions, missing edge case coverage

### Step 3: Execute Smell-by-Smell

**One smell category at a time.** Do not mix categories in a single pass.

For each category:
1. Make all fixes for that smell category across all files
2. Run the full test suite
3. If tests pass: commit with message like `cleanup: remove dead code` or `cleanup: fix naming inconsistencies`
4. If tests fail: revert the changes for that category, investigate why, and try a more targeted fix
5. Move to next category

**Why one-at-a-time:** If you mix dead code removal with naming changes and tests break, you don't know which change caused it. Isolation makes rollback trivial.

### Step 4: Final Regression Check

After all cleanup passes:
1. Run full test suite
2. Compare pass count against Step 1 baseline
3. Same or higher pass count = success
4. Lower pass count = something broke — investigate and fix

## What to Clean vs. What to Leave

**Clean:**
- Dead code, unused imports
- Comments that restate the code (`// increment counter` above `counter++`)
- Wrapper functions that add no value
- Inconsistent naming within a file
- Excessive defensive coding against impossible states
- Type annotations on obvious variables (where the language infers them)

**Leave alone:**
- Existing patterns in the codebase (even if you'd do it differently)
- Code you didn't write/touch in this session (unless it's dead code you introduced)
- Performance characteristics — don't "optimize" during cleanup
- External API interfaces or public contracts
- Comments that explain *why* (not *what*)

## Integration

**Called by:**
- **autopilot** (Phase 5) — after QA passes, before finishing
- Can be activated standalone on any recently-written code

**Uses:**
- **verification-before-completion** — the regression checks ARE the verification

## Red Flags

**Never:**
- Start cleaning without locking behavior (Step 1)
- Mix multiple smell categories in one pass
- Change behavior while cleaning ("while I'm here...")
- Clean code you didn't write (unless removing dead code you introduced)
- Skip the regression check after each pass

**Always:**
- Record test baseline before starting
- One smell category per commit
- Run tests after each pass
- Compare final pass count against baseline
- Revert and investigate if tests break
