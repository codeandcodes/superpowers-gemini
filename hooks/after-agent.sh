#!/usr/bin/env bash
# Droid auto-continuation hook for Gemini CLI
# Hook type: AfterAgent
# Runs after each model turn. When droid mode is active, detects
# stopping signals and injects continuation messages.
#
# Install: copy to .gemini/hooks/after-agent.sh in your project
# Toggle: installed by install.sh --with-droid-hook

set -euo pipefail

STATE_FILE=".gemini/state/droid.json"

# --- Fast exit if droid is not active ---
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Parse droid state (use python3 or node for JSON)
parse_state() {
  local field="$1"
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
try:
    state = json.load(open('$STATE_FILE'))
    print(state.get('$field', ''))
except:
    print('')
"
  elif command -v node &>/dev/null; then
    node -e "
try {
  const s = JSON.parse(require('fs').readFileSync('$STATE_FILE', 'utf8'));
  console.log(s['$field'] || '');
} catch { console.log(''); }
"
  else
    echo ""
  fi
}

ACTIVE=$(parse_state "active")
if [[ "$ACTIVE" != "true" && "$ACTIVE" != "True" ]]; then
  exit 0
fi

ITERATION=$(parse_state "iteration")
MAX_ITERATIONS=$(parse_state "max_iterations")

# Check if max iterations reached — let model stop naturally
if [[ -n "$ITERATION" && -n "$MAX_ITERATIONS" ]]; then
  if (( ITERATION >= MAX_ITERATIONS )); then
    exit 0
  fi
fi

# --- Read model output from stdin ---
# Gemini CLI passes hook context as JSON on stdin
INPUT=$(cat)

# Extract the model's last text output
MODEL_OUTPUT=""
if command -v python3 &>/dev/null; then
  MODEL_OUTPUT=$(python3 -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    # Try common fields for model output
    output = data.get('response', data.get('text', data.get('content', '')))
    if isinstance(output, list):
        output = ' '.join(str(x) for x in output)
    print(str(output).lower())
except:
    print('')
" "$INPUT" 2>/dev/null || echo "")
elif command -v node &>/dev/null; then
  MODEL_OUTPUT=$(node -e "
try {
  const d = JSON.parse(process.argv[1]);
  let o = d.response || d.text || d.content || '';
  if (Array.isArray(o)) o = o.join(' ');
  console.log(String(o).toLowerCase());
} catch { console.log(''); }
" "$INPUT" 2>/dev/null || echo "")
fi

# If we couldn't parse output, exit safely
if [[ -z "$MODEL_OUTPUT" ]]; then
  exit 0
fi

# --- Detect stopping signals ---
STOPPING=false

# Pattern: model asks if it should continue
if echo "$MODEL_OUTPUT" | grep -qiE \
  '(shall I (continue|proceed|go ahead|move on)|would you like (me to|to)|ready to (proceed|continue|move on)|let me know (if|when|whether)|want me to (continue|proceed|start|begin)|should I (proceed|continue|go ahead|move on)|do you want (me to|to))'; then
  STOPPING=true
fi

# Pattern: output ends with a continuation question
if [[ "$STOPPING" == "false" ]]; then
  LAST_LINE=$(echo "$MODEL_OUTPUT" | tail -1 | xargs)
  if [[ "$LAST_LINE" == *"?" ]]; then
    if echo "$LAST_LINE" | grep -qiE '(continue|proceed|next|move on|go ahead|shall|should|would you|want me|ready)'; then
      STOPPING=true
    fi
  fi
fi

# --- If stopping detected, inject continuation ---
if [[ "$STOPPING" == "true" ]]; then
  # Increment iteration in state file
  if command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$STATE_FILE', 'r') as f:
    state = json.load(f)
state['iteration'] = state.get('iteration', 0) + 1
from datetime import datetime, timezone
state['updated_at'] = datetime.now(timezone.utc).isoformat()
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null || true
  fi

  NEW_ITER=$((${ITERATION:-0} + 1))

  # Output continuation message for Gemini CLI to inject
  cat <<EOJSON
{
  "message": "Droid mode is active (iteration ${NEW_ITER}/${MAX_ITERATIONS:-50}). Continue executing the current task. Do not pause for confirmation. Proceed to the next step immediately."
}
EOJSON

  exit 0
fi

# No stopping detected — no-op
exit 0
