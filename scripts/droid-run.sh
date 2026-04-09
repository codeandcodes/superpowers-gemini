#!/usr/bin/env bash
# droid-run.sh — Outer persistence loop for multi-hour Gemini sessions
#
# Launches Gemini with the droid skill and auto-resumes if the session
# ends due to context window exhaustion or turn limits while the task
# is still incomplete.
#
# Usage:
#   ./scripts/droid-run.sh "build the authentication system"
#   ./scripts/droid-run.sh --max-retries 10 "build the auth system"
#   ./scripts/droid-run.sh --no-yolo "task description"

set -euo pipefail

STATE_FILE=".gemini/state/droid.json"
LOG_FILE=".gemini/state/droid-sessions.log"
MAX_RETRIES=5
USE_YOLO=true
TASK=""

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-retries)
      MAX_RETRIES="$2"
      shift 2
      ;;
    --no-yolo)
      USE_YOLO=false
      shift
      ;;
    --help|-h)
      echo "Usage: droid-run.sh [--max-retries N] [--no-yolo] <task description>"
      echo ""
      echo "Options:"
      echo "  --max-retries N   Maximum resume attempts (default: 5)"
      echo "  --no-yolo         Don't pass --yolo to gemini (use policy rules instead)"
      echo "  --help, -h        Show this help"
      echo ""
      echo "Examples:"
      echo "  ./scripts/droid-run.sh \"build the authentication system\""
      echo "  ./scripts/droid-run.sh --max-retries 10 \"build the auth system\""
      echo "  ./scripts/droid-run.sh --no-yolo \"task description\""
      exit 0
      ;;
    *)
      TASK="$1"
      shift
      ;;
  esac
done

if [[ -z "$TASK" ]]; then
  echo "Error: no task description provided"
  echo "Usage: droid-run.sh [--max-retries N] [--no-yolo] <task description>"
  exit 1
fi

# --- Ensure state directory exists ---
mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# --- Build gemini command ---
GEMINI_CMD="gemini"
if [[ "$USE_YOLO" == "true" ]]; then
  GEMINI_CMD="$GEMINI_CMD --yolo"
fi

# --- Session loop ---
ATTEMPT=0

log() {
  local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}

log "=== Droid session started ==="
log "Task: $TASK"
log "Max retries: $MAX_RETRIES"

while (( ATTEMPT < MAX_RETRIES )); do
  ATTEMPT=$((ATTEMPT + 1))
  log "--- Attempt $ATTEMPT/$MAX_RETRIES ---"

  EXIT_CODE=0
  if [[ $ATTEMPT -eq 1 ]]; then
    # First attempt: fresh session
    $GEMINI_CMD -p "Activate the droid skill. KEEP GOING UNTIL THE TASK IS FULLY RESOLVED. Do not pause between steps. Task: $TASK" || EXIT_CODE=$?
  else
    # Subsequent attempts: resume previous session
    log "Resuming previous session..."
    $GEMINI_CMD --resume || EXIT_CODE=$?
  fi

  log "Session exited with code $EXIT_CODE"

  # Check if droid is still active (task not complete)
  if [[ -f "$STATE_FILE" ]]; then
    ACTIVE=""
    if command -v python3 &>/dev/null; then
      ACTIVE=$(python3 -c "
import json
try:
    print(json.load(open('$STATE_FILE')).get('active', False))
except:
    print('False')
" 2>/dev/null || echo "False")
    elif command -v node &>/dev/null; then
      ACTIVE=$(node -e "
try {
  console.log(JSON.parse(require('fs').readFileSync('$STATE_FILE','utf8')).active||false);
} catch { console.log(false); }
" 2>/dev/null || echo "false")
    fi

    if [[ "$ACTIVE" == "True" || "$ACTIVE" == "true" ]]; then
      log "Task still active — will resume"
      continue
    else
      log "Task completed (active=false)"
      break
    fi
  else
    # No state file — either completed and cleaned up, or never started
    if [[ $EXIT_CODE -eq 0 ]]; then
      log "Session completed normally (no state file)"
      break
    elif [[ $EXIT_CODE -eq 53 ]]; then
      log "Turn limit exceeded — will resume"
      continue
    else
      log "Session failed with exit code $EXIT_CODE — stopping"
      break
    fi
  fi
done

if (( ATTEMPT >= MAX_RETRIES )); then
  log "Max retries ($MAX_RETRIES) reached"
fi

log "=== Droid session ended ==="
