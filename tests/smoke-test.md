# Smoke Test: LLM Evaluation Workbench

Use this prompt to verify that skills and agents are working correctly. Paste it into Gemini CLI from a project directory with superpowers-gemini installed.

## The Prompt

```
Build me a local LLM evaluation workbench. This is a full-stack application 
for downloading benchmark datasets, running them against local and API-hosted 
models, and visualizing results in a real-time dashboard.

## Core Features

### 1. Model Registry
- Configure models via a models.json file
- Support two provider types:
  - Local: Ollama API (localhost:11434) for models like gemma3, llama3, phi3
  - Cloud: Google AI Studio API (requires GOOGLE_API_KEY env var) for gemma-2
- Each model entry has: name, provider, endpoint, parameters (temperature, max_tokens)
- Health check endpoint that verifies each model is reachable

### 2. Dataset Manager
- Download standard benchmark datasets from HuggingFace:
  - MMLU (multiple choice knowledge) — use cais/mmlu on HuggingFace
  - GSM8K (math reasoning) — use gsm8k dataset
  - HumanEval (coding) — use openai/humaneval
- Store datasets locally in data/ directory as JSONL
- Support a --sample flag to download only N examples (for quick testing)
- Custom dataset support: user can add their own JSONL files to data/custom/

### 3. Evaluation Runner
- Run a model against a dataset with configurable concurrency
- For each example: send prompt to model, capture response, score it
- Scoring logic per dataset type:
  - MMLU: exact match on multiple choice letter (A/B/C/D)
  - GSM8K: extract final number from response, compare to answer
  - HumanEval: execute generated code in a sandbox, check test cases pass
  - Custom: regex match or exact match (configurable per dataset)
- Save raw results to results/{model}/{dataset}/{timestamp}.jsonl
- Resume support: if a run is interrupted, pick up where it left off

### 4. Real-Time Dashboard
- Web UI served on http://localhost:3000
- Live progress: show current eval run progress (X/N examples complete)
- Results view:
  - Radar chart: model capabilities across dataset categories
  - Bar chart: head-to-head model comparison on any dataset  
  - Scatter plot: accuracy vs latency per model
  - Sortable leaderboard table with all models and scores
  - Click any cell to see individual example results (prompt, response, score)
- Historical runs: compare current run against previous runs
- Filter by: model, dataset, date range, score threshold
- Auto-refresh via WebSocket (not polling)

### 5. CLI Interface
- `node eval.js setup` — verify models reachable, download datasets
- `node eval.js run --model gemma3 --dataset mmlu --sample 100` — run eval
- `node eval.js run --all --sample 50` — run all models against all datasets
- `node eval.js serve` — start the dashboard
- `node eval.js compare gemma3 llama3` — quick terminal comparison table
- `node eval.js export --format csv` — export results

## Technical Requirements

- Backend: Node.js, built-in http module + ws library for WebSocket
- Frontend: vanilla HTML/CSS/JS, Chart.js from CDN
- Storage: filesystem-based (JSONL files, no database)
- Tests: Node.js built-in test runner (node:test)
- Zero framework dependencies for the web server (no Express)

## Design

Dark theme dashboard. Think "GPU monitoring tool meets data science notebook."
Monospace fonts for data, high contrast charts, subtle animations on live 
data updates. The progress view during an active eval run should feel like 
watching a CI pipeline — real-time, informative, not flashy.

The example detail view (when you click a cell) should show the prompt on 
the left and the model's response on the right, with the score and 
scoring rationale highlighted.

## Stretch goals (implement if time allows)

- Side-by-side diff view: show two models' responses to the same prompt
- Prompt template editor: customize how dataset examples are formatted before 
  sending to the model
- Export a static HTML report that can be shared without running the server
```

## What to Observe

This prompt should trigger the full skill chain. Watch for these behaviors:

### Phase 1: Design (brainstorming skill)
- [ ] Creates a context snapshot before asking questions
- [ ] Asks clarifying questions ONE AT A TIME
- [ ] Tracks ambiguity across dimensions (intent, outcome, scope, constraints, success criteria)
- [ ] Runs at least one challenge mode (Contrarian, Simplifier, or Ontologist)
- [ ] States non-goals explicitly
- [ ] Proposes 2-3 approaches with trade-offs
- [ ] Writes a design spec document
- [ ] Asks for user approval before proceeding

### Phase 2: Planning (writing-plans skill)
- [ ] Checks for vagueness in the spec (vagueness gate)
- [ ] Creates or references the context snapshot
- [ ] Maps out file structure before defining tasks
- [ ] Creates bite-sized tasks (2-5 min each) with TDD steps
- [ ] Includes actual code in every step (no placeholders)
- [ ] Self-reviews the plan against the spec
- [ ] Offers execution choice (agent-driven vs inline)

### Phase 3: Implementation (subagent-driven-development)
- [ ] Creates git worktree for isolation
- [ ] Delegates to `implementer` agent per task
- [ ] Delegates to `spec-reviewer` after each task
- [ ] Delegates to `code-reviewer` after each task
- [ ] Handles agent questions and escalations
- [ ] Tracks progress across tasks

### Phase 4: Quality (ultra-qa skill)
- [ ] Runs full test suite + build + lint
- [ ] Diagnoses failures by root cause
- [ ] Groups related failures
- [ ] Fixes and retests (up to 5 cycles)
- [ ] Tracks error recurrence (3-strikes rule)
- [ ] Reports cycle history

### Phase 5: Validation
- [ ] Spec-reviewer checks functional completeness
- [ ] Code-reviewer does final quality review
- [ ] Visual-verdict scores the dashboard UI (if screenshot is possible)

### Phase 6: Cleanup (slop-cleaner skill)
- [ ] Locks behavior with existing tests
- [ ] Cleans smell-by-smell (dead code, comments, naming, etc.)
- [ ] Runs regression check after each pass
- [ ] Commits each cleanup pass separately

### Phase 7: Completion (finishing-a-development-branch skill)
- [ ] Verifies all tests pass
- [ ] Presents 4 options (merge, PR, keep, discard)
- [ ] Executes chosen option

### Cross-cutting behaviors
- [ ] Session notes saved during long-running work
- [ ] Systematic debugging used when hitting real issues (Ollama connection, HuggingFace API, WebSocket bugs)
- [ ] Test-driven development followed (tests before implementation)
- [ ] Verification before any completion claims (evidence before assertions)

## Expected Duration

This prompt should take 1-3 hours of autonomous execution depending on model speed and how many issues arise during implementation. The five subsystems (model registry, dataset manager, eval runner, dashboard, CLI) are complex enough to generate real integration challenges.

## Minimal Test (Quick Version)

If you want a faster test (15-30 minutes), add this to the end of the prompt:

```
Start with just the Model Registry and Dataset Manager (features 1 and 2). 
Skip the dashboard, eval runner, and CLI for now. Use --sample 10 for datasets.
```

This still exercises brainstorming, planning, TDD, implementation agents, QA cycling, and code review — just with a smaller scope.
