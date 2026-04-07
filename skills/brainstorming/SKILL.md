---
name: brainstorming
description: >
  Use before any creative work - creating features, building components, adding functionality,
  or modifying behavior. Explores user intent, requirements and design before implementation.
  Uses structured ambiguity scoring and challenge modes to pressure-test ideas.
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs and specs through structured collaborative dialogue. Use ambiguity scoring to identify weak spots and challenge modes to pressure-test assumptions.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

## Hard Gate

Do NOT write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change -- all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Checklist

Complete these steps in order:

1. **Create context snapshot** -- capture task, desired outcome, constraints, unknowns
2. **Explore project context** -- check files, docs, recent commits
3. **Deep interview** -- structured questioning with ambiguity scoring
4. **Challenge round** -- pressure-test the emerging design with challenge modes
5. **Propose 2-3 approaches** -- with trade-offs and your recommendation
6. **Present design** -- in sections scaled to their complexity, get user approval after each section
7. **Write design doc** -- save to `docs/specs/YYYY-MM-DD-<topic>-design.md` and commit
8. **Spec self-review** -- check for placeholders, contradictions, ambiguity, scope
9. **User reviews written spec** -- ask user to review the spec file before proceeding
10. **Transition to implementation** -- activate writing-plans skill to create implementation plan

## Context Snapshot

Before asking any questions, create a context snapshot:

```markdown
## Context Snapshot

**Task:** [What the user asked for — their words]
**Desired outcome:** [What success looks like — if unclear, this is the first question]
**Known facts:** [What we know about the codebase, constraints, etc.]
**Constraints:** [Time, technology, compatibility requirements]
**Unknowns:** [What we need to figure out]
**Codebase touchpoints:** [Key files/modules that will be affected]
```

Update this snapshot as you learn more. It becomes part of the spec document.

## Deep Interview

### Ambiguity Scoring

Track five dimensions of understanding. Each starts at 0 and moves toward 100 as questions are answered:

| Dimension | Weight | What it measures |
|-----------|--------|-----------------|
| **Intent** | 0.30 | Why does the user want this? What problem does it solve? |
| **Outcome** | 0.25 | What does "done" look like? How will success be measured? |
| **Scope** | 0.20 | What's in and what's out? Where are the boundaries? |
| **Constraints** | 0.15 | Technical limitations, compatibility, performance, timeline? |
| **Success criteria** | 0.10 | How will we verify this works? What are the acceptance tests? |

**Readiness score** = weighted sum of all dimensions.

- Below 60: Keep asking questions. Target the lowest-scoring dimension.
- 60-80: Good enough to propose approaches, but flag remaining gaps.
- Above 80: Ready to present design.

**Always target the weakest dimension** with your next question. Don't ask about constraints when intent is still at 20.

### Questioning Rules

- **One question per message** — never ask two questions at once
- **Prefer multiple choice** when the answer space is bounded
- **Open-ended when exploring** new territory the user hasn't mentioned
- **State the dimension** you're targeting: "I want to understand the scope better..."
- **Update scores** internally after each answer (you don't need to show the numbers every time, but if the user asks, show them)

### Mandatory Readiness Gates

Before moving to approaches, these MUST be explicit:

1. **Non-goals** — what this project deliberately does NOT do
2. **Decision boundaries** — which decisions are settled vs. open for the design to decide

If the user hasn't volunteered these, ask directly: "What should this explicitly NOT do?" and "Which technical decisions are already made vs. open?"

## Challenge Modes

After the deep interview (readiness > 60), run at least one challenge pass before proposing approaches. Pick the most relevant mode:

### Contrarian
Challenge the core assumptions. What if the user is solving the wrong problem?
- "What if you didn't build this at all — what's the workaround?"
- "What if the requirement you're most certain about is wrong?"
- "Is there an existing solution that covers 80% of this?"

### Simplifier
Probe for minimal scope. What's the smallest thing that would be useful?
- "If you could only ship one feature from this list, which one?"
- "What's the version that takes 1 day instead of 1 week?"
- "Which requirements are must-haves vs. nice-to-haves?"

### Ontologist
Reframe at the essence level. Are the abstractions right?
- "You said 'users' — is that one type of user or several with different needs?"
- "You described this as a 'dashboard' — is it really a dashboard or a report or a monitoring tool?"
- "What's the actual data flow here, ignoring the UI?"

**One challenge pass is mandatory.** If the design survives the challenge, proceed. If it cracks open, loop back to questioning.

## Process (after interview and challenge)

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose
- Each unit should communicate through well-defined interfaces and be understood and tested independently
- Smaller, well-bounded units are easier to work with

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work, include targeted improvements as part of the design
- Don't propose unrelated refactoring.

## After the Design

**Documentation:**

- Write the validated design (spec) to `docs/specs/YYYY-MM-DD-<topic>-design.md`
  - Include the context snapshot at the top
  - Include non-goals and decision boundaries
  - (User preferences for spec location override this default)
- Commit the design document to git

**Spec Self-Review:**
After writing the spec document, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other?
3. **Scope check:** Is this focused enough for a single implementation plan?
4. **Ambiguity check:** Could any requirement be interpreted two different ways?
5. **Non-goals check:** Are non-goals explicitly stated?

Fix any issues inline.

**User Review Gate:**
After the spec review loop passes, ask the user to review the written spec before proceeding:

> "Spec written and committed. Please review it and let me know if you want to make any changes before we start writing the implementation plan."

Wait for the user's response. Only proceed once the user approves.

**Implementation:**

- Activate the writing-plans skill to create a detailed implementation plan
- Do NOT activate any other skill. writing-plans is the next step.

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Target the weakest dimension** - Don't ask about constraints when intent is unclear
- **Challenge before committing** - Run at least one challenge mode
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design, get approval before moving on
- **Non-goals are required** - Every spec must say what it does NOT do
