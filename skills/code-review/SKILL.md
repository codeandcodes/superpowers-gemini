---
name: code-review
description: >
  Code review a pull request. Dispatches multiple review agents in parallel to check for
  bugs, standards compliance, and historical context.
---

# Code Review a Pull Request

Provide a thorough code review for a given pull request.

## Process

1. **Eligibility check** -- verify PR is not closed, not a draft, and needs review
2. **Gather context** -- find relevant GEMINI.md/CLAUDE.md files in directories touched by the PR
3. **View PR** -- get a summary of the change
4. **Parallel review** -- dispatch agents to independently review:
   a. Standards compliance (GEMINI.md / CLAUDE.md adherence)
   b. Bug scan (shallow scan for obvious bugs in the diff)
   c. Historical context (git blame/history for bugs in light of past changes)
   d. Previous PR comments (check if past feedback on these files applies)
   e. Code comment compliance (changes comply with guidance in code comments)
5. **Score issues** -- for each issue found, score confidence 0-100:
   - 0: False positive
   - 25: Might be real, couldn't verify
   - 50: Real but minor/nitpick
   - 75: Very likely real, important
   - 100: Definitely real, confirmed
6. **Filter** -- only keep issues scored >= 80
7. **Re-check eligibility** -- make sure PR is still open
8. **Comment** -- post results to the PR

## False Positives to Ignore

- Pre-existing issues
- Things a linter/typechecker/compiler would catch
- General code quality issues (unless required by project config)
- Changes in functionality that are likely intentional
- Issues on lines the user did not modify

## Output Format

```markdown
### Code review

Found N issues:

1. <brief description> (reason: <source>)
   <link to file and line>

2. ...
```

Or if no issues: "No issues found. Checked for bugs and standards compliance."
