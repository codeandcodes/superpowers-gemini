---
name: web-clone
description: >
  Use when the user provides a URL and wants to recreate or clone that website's appearance
  and functionality. Extracts structure, generates code, and iteratively verifies against
  the original using visual comparison.
---

# Web Clone

Clone a website from a URL. Extract the structure, generate code, and iterate until the clone matches the original.

## When to Use

- User provides a URL and says "clone this", "recreate this", "make something like this"
- User wants to use an existing site as a design reference
- User wants to reverse-engineer a page's layout/styling

## The 5-Pass Pipeline

```
Pass 1: Extract — Analyze the source site
Pass 2: Plan — Define the structure and approach
Pass 3: Generate — Write the code
Pass 4: Verify — Compare clone against original
Pass 5: Iterate — Fix differences until visual verdict passes
```

### Pass 1: Extract

Analyze the target URL:

1. **Fetch the page** and examine its HTML structure
2. **Identify key sections:** header, nav, hero, content blocks, sidebar, footer
3. **Catalog visual elements:** colors, fonts, spacing, layout patterns
4. **Note interactive elements:** dropdowns, modals, carousels, forms
5. **Capture reference screenshot** (or ask user to provide one)

Create an extraction summary:

```markdown
## Site Analysis: [URL]

**Layout type:** [grid/flex/float, responsive breakpoints]
**Color palette:** [primary, secondary, accent, background, text colors]
**Typography:** [heading font, body font, sizes]
**Key sections:** [list of major page sections]
**Interactive elements:** [list of JS-dependent features]
**External dependencies:** [fonts, icon libraries, JS frameworks detected]
```

### Pass 2: Plan

Decide the technical approach:

- **Vanilla HTML/CSS/JS** for simple static sites
- **Framework-based** if the user specified one (React, Vue, etc.)
- **Identify what to clone vs. simplify** — complex animations or third-party widgets may need approximation
- **List the files to create** with responsibilities

Get user confirmation on the approach before generating.

### Pass 3: Generate

Write the code following the plan:

- Start with structure (HTML)
- Add styling (CSS) — match the original's visual system
- Add interactivity (JS) — focus on key behaviors, not pixel-perfect animation cloning
- Use the **frontend-design** skill principles for quality

### Pass 4: Verify

Use the **visual-verdict** skill to compare:

1. Serve the clone locally
2. Screenshot the clone
3. Compare against the reference (original site screenshot)
4. Score using visual verdict rubric

### Pass 5: Iterate

If visual verdict score < 90:
1. Review the specific differences listed in the verdict
2. Fix each difference
3. Re-verify
4. Repeat until score >= 90 or max 5 iterations

## Scope Boundaries

**Clone:**
- Layout and visual structure
- Color palette and typography
- Key interactive behaviors (nav, modals, tabs)
- Responsive breakpoints

**Don't clone:**
- Backend functionality or databases
- Authentication flows
- Third-party API integrations
- Exact JavaScript framework internals
- Content (use placeholder text unless user wants exact content)

## Red Flags

**Never:**
- Clone copyrighted content without user acknowledging it
- Include tracking scripts, analytics, or third-party cookies from the original
- Fetch and embed images from the original site (use placeholders)
- Ignore responsive design — clone at least desktop and mobile breakpoints

**Always:**
- Get user confirmation on approach before generating
- Use semantic HTML
- Make the clone self-contained (no external dependencies on the original)
- Verify with visual verdict, don't just eyeball it

## Integration

**Uses:**
- **frontend-design** — quality principles for the generated code
- **visual-verdict** — verification against the original
- **brainstorming** — if the user wants modifications, not a pure clone
