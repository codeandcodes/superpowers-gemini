---
name: visual-verdict
description: >
  Use when verifying frontend/UI implementation matches a design reference, mockup, or
  previous screenshot. Takes a screenshot, compares against reference, scores the match,
  and iterates until the score meets threshold.
---

# Visual Verdict

Structured visual QA for frontend work. Screenshot the current state, compare against a reference, score the match, and iterate until it meets the bar.

## When to Use

- After implementing a frontend component or page
- When the user provides a design mockup or reference screenshot
- When verifying that CSS/layout changes didn't break visual appearance
- During autopilot Phase 4 validation for frontend projects

## The Verdict Loop

```
1. Capture screenshot of current state
2. Compare against reference (mockup, design, previous screenshot)
3. Score the match (0-100)
4. If score >= 90 → PASS, done
5. If score < 90 → list specific differences, fix them, go to 1
6. Max 5 iterations — if still < 90, escalate to user
```

## Scoring Rubric

Score each dimension, then compute weighted average:

| Dimension | Weight | What to check |
|-----------|--------|---------------|
| **Layout** | 0.30 | Element positioning, spacing, alignment, responsiveness |
| **Typography** | 0.20 | Font family, size, weight, line-height, letter-spacing |
| **Color** | 0.20 | Background, text, border, shadow colors match reference |
| **Content** | 0.15 | Text content, images, icons present and correct |
| **Interaction** | 0.15 | Hover states, focus states, transitions visible in static capture |

**Score interpretation:**
- 90-100: Production ready — matches reference
- 70-89: Close but noticeable differences — list and fix
- 50-69: Significant deviations — multiple areas need work
- Below 50: Fundamental mismatch — revisit the approach

## Verdict Report Format

```markdown
## Visual Verdict

**Score:** 82/100
**Status:** NEEDS FIXES (below 90 threshold)

**Breakdown:**
- Layout: 90/100 — spacing between cards is 8px wider than reference
- Typography: 85/100 — heading font-weight should be 600 not 700
- Color: 75/100 — secondary button background is #3B82F6, reference shows #2563EB
- Content: 80/100 — missing "Learn more" link in footer
- Interaction: 80/100 — no visible hover state on nav items

**Fixes needed:**
1. Reduce card gap from 24px to 16px
2. Change h2 font-weight to 600
3. Update secondary button color to #2563EB
4. Add "Learn more" link to footer section
5. Add hover underline to nav links
```

## How to Capture

Depending on the project setup:

**Browser-based (preferred):**
```bash
# If Playwright/Puppeteer is available
npx playwright screenshot http://localhost:3000 screenshot.png

# Or open in browser and take manual screenshot
open http://localhost:3000
```

**Static HTML:**
```bash
# Open the HTML file directly
open index.html
# Screenshot via browser dev tools or OS screenshot tool
```

If automated screenshot capture isn't available, ask the user to provide a screenshot or describe the current state.

## Iteration Rules

- **Fix only what the verdict identified** — don't go beyond the listed differences
- **Re-screenshot after fixes** — don't assume the fix worked
- **Score independently each iteration** — don't carry forward assumptions from previous scores
- **Max 5 iterations** — if you can't reach 90 in 5 tries, the reference or approach may need revisiting

## Integration

**Called by:**
- **autopilot** (Phase 4) — for frontend projects, adds visual verdict to the validation checks
- **frontend-design** — can be used as a verification step after implementation
- Standalone after any frontend work

**Pairs with:**
- **frontend-design** — design skill creates it, visual verdict verifies it
- **verification-before-completion** — visual verdict IS verification for frontend work
