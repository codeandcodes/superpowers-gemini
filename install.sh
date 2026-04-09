#!/usr/bin/env bash
set -euo pipefail

# superpowers-gemini installer
# Installs skills and agents for Gemini CLI

REPO_URL="https://github.com/codeandcodes/superpowers-gemini.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_MODE="${1:-}"
DROID_HOOK=""  # "", "yes", "no"

# Parse additional flags from all arguments
for arg in "$@"; do
  case "$arg" in
    --with-droid-hook) DROID_HOOK="yes" ;;
    --no-droid-hook)   DROID_HOOK="no" ;;
  esac
done

usage() {
  cat <<'EOF'
Usage: install.sh <mode> [project-path]

Modes:
  project [path]   Install into a specific project (default: current directory)
                   Creates .gemini/skills/ and .gemini/agents/ in the project
  user             Install globally for all projects
                   Creates ~/.gemini/skills/ and ~/.gemini/agents/
  uninstall        Remove installed skills and agents (from both locations)
  config           Print current model configuration
  doctor [path]    Verify installation health (default: check all locations)

Flags:
  --with-droid-hook    Install the droid auto-continuation hook
  --no-droid-hook      Skip the droid hook (default: ask interactively)

Examples:
  ./install.sh project                  # Install into current project
  ./install.sh project ~/myapp          # Install into ~/myapp
  ./install.sh user                     # Install globally
  ./install.sh uninstall                # Remove from both locations
  ./install.sh config                   # Show resolved model assignments
  ./install.sh doctor                   # Verify installation is healthy
  ./install.sh doctor ~/myapp           # Check a specific project

Customize models before installing by editing config.json.

Alternative (native Gemini CLI -- uses template defaults, no config resolution):
  gemini extensions install .
  gemini extensions install <git-url>
EOF
  exit 1
}

# --- Config resolution ---
# Uses python3 or node to read config.json and produce a simple key=value mapping
# for each agent's resolved model. This avoids bash 4 associative arrays.

resolve_config() {
  local config_file="$SCRIPT_DIR/config.json"

  if command -v python3 &>/dev/null; then
    python3 - "$config_file" <<'PYEOF'
import json, sys

config_file = sys.argv[1]

# Defaults
tiers = {"strong": "gemini-2.5-pro", "medium": "gemini-2.5-flash", "fast": "gemini-2.5-flash"}
agent_defaults = {
    "code-reviewer": "strong",
    "code-simplifier": "strong",
    "planner": "strong",
    "implementer": "medium",
    "spec-reviewer": "fast",
    "explorer": "fast",
}

try:
    with open(config_file) as f:
        cfg = json.load(f)
    # Override tiers
    for t in ("strong", "medium", "fast"):
        v = cfg.get("models", {}).get("tiers", {}).get(t)
        if v:
            tiers[t] = v
    # Override agent assignments
    for agent in agent_defaults:
        v = cfg.get("models", {}).get("agents", {}).get(agent)
        if v:
            agent_defaults[agent] = v
except (FileNotFoundError, json.JSONDecodeError):
    pass

# Resolve: if agent value is a tier name, look it up; otherwise treat as direct model ID
for agent, val in agent_defaults.items():
    model = tiers.get(val, val)
    print(f"{agent}={model}")

# Also print tiers for display
for t, m in tiers.items():
    print(f"__tier_{t}={m}")
PYEOF

  elif command -v node &>/dev/null; then
    node - "$config_file" <<'JSEOF'
const fs = require('fs');
const configFile = process.argv[2];

const tiers = {strong: 'gemini-2.5-pro', medium: 'gemini-2.5-flash', fast: 'gemini-2.5-flash'};
const agentDefaults = {
  'code-reviewer': 'strong',
  'code-simplifier': 'strong',
  'planner': 'strong',
  'implementer': 'medium',
  'spec-reviewer': 'fast',
  'explorer': 'fast',
};

try {
  const cfg = JSON.parse(fs.readFileSync(configFile, 'utf8'));
  for (const t of ['strong', 'medium', 'fast']) {
    const v = cfg?.models?.tiers?.[t];
    if (v) tiers[t] = v;
  }
  for (const agent of Object.keys(agentDefaults)) {
    const v = cfg?.models?.agents?.[agent];
    if (v) agentDefaults[agent] = v;
  }
} catch {}

for (const [agent, val] of Object.entries(agentDefaults)) {
  const model = tiers[val] || val;
  console.log(`${agent}=${model}`);
}
for (const [t, m] of Object.entries(tiers)) {
  console.log(`__tier_${t}=${m}`);
}
JSEOF

  else
    echo "Error: python3 or node is required to parse config.json" >&2
    exit 1
  fi
}

# Load resolved config into shell variables
# Sets: MODEL_<agent-name-underscored> and TIER_<name>
RESOLVED_CONFIG=""

load_config() {
  RESOLVED_CONFIG=$(resolve_config)
}

get_agent_model() {
  local agent="$1"
  echo "$RESOLVED_CONFIG" | grep "^${agent}=" | cut -d= -f2
}

get_tier() {
  local tier="$1"
  echo "$RESOLVED_CONFIG" | grep "^__tier_${tier}=" | cut -d= -f2
}

print_config() {
  echo "Model tiers:"
  for tier in strong medium fast; do
    printf "  %-8s %s\n" "$tier:" "$(get_tier "$tier")"
  done
  echo ""
  echo "Agent model assignments:"
  for agent in code-reviewer code-simplifier planner implementer spec-reviewer explorer; do
    printf "  %-18s %s\n" "$agent:" "$(get_agent_model "$agent")"
  done
}

# --- Detect source directory ---
detect_source() {
  if [[ -f "$SCRIPT_DIR/gemini-extension.json" ]]; then
    SOURCE_DIR="$SCRIPT_DIR"
  else
    echo "Cloning from $REPO_URL..."
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT
    git clone --depth 1 "$REPO_URL" "$TMPDIR/superpowers-gemini"
    SOURCE_DIR="$TMPDIR/superpowers-gemini"
  fi
}

# --- Template an agent file: replace {{MODEL}} with the resolved model ---
template_agent() {
  local src="$1"
  local dest="$2"
  local agent_name="$3"

  local model
  model=$(get_agent_model "$agent_name")
  # Fallback to medium tier if agent not in config
  if [[ -z "$model" ]]; then
    model=$(get_tier "medium")
  fi

  sed -e "s|{{MODEL}}|$model|g" "$src" > "$dest"
}

# --- Install ---
install_to() {
  local dest="$1"

  echo ""
  echo "Installing to: $dest"

  # Skills (copied as-is)
  if [[ -d "$SOURCE_DIR/skills" ]]; then
    mkdir -p "$dest/skills"
    local count=0
    for skill_dir in "$SOURCE_DIR"/skills/*/; do
      if [[ -f "$skill_dir/SKILL.md" ]]; then
        skill_name=$(basename "$skill_dir")
        mkdir -p "$dest/skills/$skill_name"
        cp -r "$skill_dir"* "$dest/skills/$skill_name/"
        count=$((count + 1))
      fi
    done
    echo "  Installed $count skills"
  fi

  # Agents (templated with resolved model)
  if [[ -d "$SOURCE_DIR/agents" ]]; then
    mkdir -p "$dest/agents"
    local count=0
    for agent_file in "$SOURCE_DIR"/agents/*.md; do
      if [[ -f "$agent_file" ]]; then
        local filename agent_name
        filename=$(basename "$agent_file")
        agent_name="${filename%.md}"
        template_agent "$agent_file" "$dest/agents/$filename" "$agent_name"
        count=$((count + 1))
      fi
    done
    echo "  Installed $count agents (models resolved from config.json)"
  fi

  # GEMINI.md (workflow instructions that tell the model to use skills)
  if [[ -f "$SOURCE_DIR/GEMINI.md" ]]; then
    local gemini_md="$dest/GEMINI.md"
    if [[ -f "$gemini_md" ]]; then
      echo "  GEMINI.md already exists at $gemini_md -- skipping (won't overwrite)"
    else
      cp "$SOURCE_DIR/GEMINI.md" "$gemini_md"
      echo "  Installed GEMINI.md (skill-first workflow instructions)"
    fi
  fi

  # Commands (copied as-is)
  if [[ -d "$SOURCE_DIR/commands" ]]; then
    mkdir -p "$dest/commands"
    local count=0
    for cmd_file in "$SOURCE_DIR"/commands/*.toml; do
      if [[ -f "$cmd_file" ]]; then
        cp "$cmd_file" "$dest/commands/"
        count=$((count + 1))
      fi
    done
    echo "  Installed $count custom commands"
  fi

  # Policies (copied as-is)
  if [[ -d "$SOURCE_DIR/policies" ]]; then
    mkdir -p "$dest/policies"
    local count=0
    for policy_file in "$SOURCE_DIR"/policies/*.toml; do
      if [[ -f "$policy_file" ]]; then
        cp "$policy_file" "$dest/policies/"
        count=$((count + 1))
      fi
    done
    echo "  Installed $count policy files"
  fi

  # Hooks (only if opted in)
  if [[ -d "$SOURCE_DIR/hooks" ]]; then
    local install_hook="$DROID_HOOK"

    # Interactive prompt if no flag given
    if [[ -z "$install_hook" ]]; then
      echo ""
      echo "  Droid auto-continuation hook:"
      echo "    This hook detects when the model pauses during autonomous execution"
      echo "    and nudges it to continue. It runs after each model turn."
      echo ""
      read -rp "  Enable droid hook? (y/n) [n]: " install_hook_input
      install_hook="${install_hook_input:-no}"
      if [[ "$install_hook" == "y" || "$install_hook" == "yes" ]]; then
        install_hook="yes"
      else
        install_hook="no"
      fi
    fi

    if [[ "$install_hook" == "yes" ]]; then
      mkdir -p "$dest/hooks"
      local count=0
      for hook_file in "$SOURCE_DIR"/hooks/*.sh; do
        if [[ -f "$hook_file" ]]; then
          cp "$hook_file" "$dest/hooks/"
          chmod +x "$dest/hooks/$(basename "$hook_file")"
          count=$((count + 1))
        fi
      done
      echo "  Installed $count hooks (droid auto-continuation enabled)"
    else
      echo "  Skipped hooks (use --with-droid-hook to enable)"
    fi
  fi
}

# --- Uninstall ---
uninstall() {
  local skills=(
    brainstorming writing-plans executing-plans test-driven-development
    systematic-debugging verification-before-completion requesting-code-review
    receiving-code-review dispatching-parallel-agents subagent-driven-development
    finishing-a-development-branch using-git-worktrees frontend-design code-review
    autopilot ultra-qa slop-cleaner visual-verdict web-clone session-notes cancel
    droid
  )
  local agents=(
    code-reviewer.md code-simplifier.md implementer.md
    spec-reviewer.md explorer.md planner.md
  )

  for base in ".gemini" "$HOME/.gemini"; do
    if [[ -d "$base" ]]; then
      for skill in "${skills[@]}"; do
        if [[ -d "$base/skills/$skill" ]]; then
          rm -rf "$base/skills/$skill"
          echo "  Removed skill: $skill (from $base)"
        fi
      done
      for agent in "${agents[@]}"; do
        if [[ -f "$base/agents/$agent" ]]; then
          rm "$base/agents/$agent"
          echo "  Removed agent: $agent (from $base)"
        fi
      done
      # Remove GEMINI.md only if it's ours (contains "Superpowers Workflow" header)
      if [[ -f "$base/GEMINI.md" ]] && head -1 "$base/GEMINI.md" | grep -q "Superpowers Workflow"; then
        rm "$base/GEMINI.md"
        echo "  Removed GEMINI.md (from $base)"
      fi
      # Clean up droid-specific files
      for f in "$base/hooks/after-agent.sh" "$base/policies/droid-auto-approve.toml" "$base/commands/droid.toml"; do
        if [[ -f "$f" ]]; then
          rm "$f"
          echo "  Removed: $(basename "$f") (from $base)"
        fi
      done
      # Clean up droid state
      if [[ -f "$base/state/droid.json" ]]; then
        rm "$base/state/droid.json"
        echo "  Removed droid state file (from $base)"
      fi
    fi
  done

  echo "Uninstall complete."
}

# --- Doctor ---
doctor() {
  local check_path="${1:-}"
  local pass=0
  local warn=0
  local fail=0

  local EXPECTED_SKILLS=(
    brainstorming writing-plans executing-plans test-driven-development
    systematic-debugging verification-before-completion requesting-code-review
    receiving-code-review dispatching-parallel-agents subagent-driven-development
    finishing-a-development-branch using-git-worktrees frontend-design code-review
    autopilot ultra-qa slop-cleaner visual-verdict web-clone session-notes cancel
    droid
  )
  local EXPECTED_AGENTS=(
    code-reviewer code-simplifier implementer
    spec-reviewer explorer planner
  )

  # Helper: print check result
  ok()   { pass=$((pass + 1)); printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
  skip() { warn=$((warn + 1)); printf "  \033[33mWARN\033[0m  %s\n" "$1"; }
  bad()  { fail=$((fail + 1)); printf "  \033[31mFAIL\033[0m  %s\n" "$1"; }

  echo "=== superpowers-gemini doctor ==="
  echo ""

  # -------------------------------------------------------
  # 1. Prerequisites
  # -------------------------------------------------------
  echo "[prerequisites]"

  # Gemini CLI installed?
  if command -v gemini &>/dev/null; then
    local ver
    ver=$(gemini --version 2>/dev/null || echo "unknown")
    ok "Gemini CLI installed (v$ver)"
  else
    bad "Gemini CLI not found in PATH"
  fi

  # python3 or node available (needed for config resolution)?
  if command -v python3 &>/dev/null; then
    ok "python3 available (config resolver)"
  elif command -v node &>/dev/null; then
    ok "node available (config resolver)"
  else
    bad "Neither python3 nor node found (required to resolve config.json)"
  fi

  echo ""

  # -------------------------------------------------------
  # 2. Config validation
  # -------------------------------------------------------
  echo "[config.json]"

  local config_file="$SCRIPT_DIR/config.json"
  if [[ -f "$config_file" ]]; then
    ok "config.json found"

    # Try to parse it
    local config_err
    if command -v python3 &>/dev/null; then
      config_err=$(python3 -c "
import json, sys
try:
    cfg = json.load(open('$config_file'))
    tiers = cfg.get('models', {}).get('tiers', {})
    agents = cfg.get('models', {}).get('agents', {})
    if not tiers:
        print('WARN:no_tiers')
    if not agents:
        print('WARN:no_agents')
    valid_tiers = set(tiers.keys())
    for agent, val in agents.items():
        if val not in valid_tiers and val not in tiers.values():
            # Could be a direct model ID -- just flag it
            print(f'INFO:direct_model:{agent}={val}')
except json.JSONDecodeError as e:
    print(f'ERROR:parse:{e}')
except Exception as e:
    print(f'ERROR:other:{e}')
" 2>&1)
    fi

    if echo "$config_err" | grep -q "^ERROR:parse:"; then
      bad "config.json is not valid JSON: $(echo "$config_err" | sed 's/ERROR:parse://')"
    elif echo "$config_err" | grep -q "^ERROR:"; then
      bad "config.json error: $(echo "$config_err" | sed 's/ERROR:other://')"
    else
      ok "config.json is valid JSON"

      if echo "$config_err" | grep -q "WARN:no_tiers"; then
        skip "config.json has no models.tiers (using defaults)"
      else
        ok "config.json defines model tiers"
      fi
      if echo "$config_err" | grep -q "WARN:no_agents"; then
        skip "config.json has no models.agents (using defaults)"
      else
        ok "config.json defines agent assignments"
      fi

      # Show any direct model IDs
      while IFS= read -r line; do
        local detail="${line#INFO:direct_model:}"
        skip "$detail uses a direct model ID (not a tier -- make sure it's valid)"
      done < <(echo "$config_err" | grep "^INFO:direct_model:" || true)
    fi
  else
    skip "config.json not found (using built-in defaults)"
  fi

  echo ""

  # -------------------------------------------------------
  # 3. Locate installed files
  # -------------------------------------------------------
  echo "[installed files]"

  # Build list of directories to scan
  local search_dirs=()
  if [[ -n "$check_path" ]]; then
    search_dirs=("$(cd "$check_path" && pwd)/.gemini")
  else
    # Check project-local (.gemini in cwd) and user-global (~/.gemini)
    [[ -d ".gemini" ]] && search_dirs+=("$(pwd)/.gemini")
    [[ -d "$HOME/.gemini" ]] && search_dirs+=("$HOME/.gemini")
  fi

  if [[ ${#search_dirs[@]} -eq 0 ]]; then
    bad "No .gemini directories found to check"
    echo ""
  else
    local found_any_skill=false
    local found_any_agent=false

    for base in "${search_dirs[@]}"; do
      echo "  Scanning: $base"

      # Check skills
      for skill in "${EXPECTED_SKILLS[@]}"; do
        local skill_file="$base/skills/$skill/SKILL.md"
        if [[ -f "$skill_file" ]]; then
          found_any_skill=true

          # Validate frontmatter has name and description
          if head -20 "$skill_file" | grep -q "^name:"; then
            if head -20 "$skill_file" | grep -q "^description:"; then
              ok "skill/$skill -- valid frontmatter"
            else
              bad "skill/$skill -- missing 'description' in frontmatter"
            fi
          else
            bad "skill/$skill -- missing 'name' in frontmatter"
          fi
        fi
      done

      # Check agents
      for agent in "${EXPECTED_AGENTS[@]}"; do
        local agent_file="$base/agents/${agent}.md"
        if [[ -f "$agent_file" ]]; then
          found_any_agent=true

          # Check for unresolved template placeholders
          if grep -q '{{MODEL}}' "$agent_file"; then
            bad "agent/$agent -- unresolved {{MODEL}} placeholder (run install.sh to fix)"
          else
            # Validate frontmatter
            if head -20 "$agent_file" | grep -q "^name:"; then
              if head -20 "$agent_file" | grep -q "^model:"; then
                local resolved_model
                resolved_model=$(grep "^model:" "$agent_file" | head -1 | sed 's/model: *//')
                ok "agent/$agent -- model: $resolved_model"
              else
                bad "agent/$agent -- missing 'model' in frontmatter"
              fi
            else
              bad "agent/$agent -- missing 'name' in frontmatter"
            fi
          fi
        fi
      done

      # Check GEMINI.md
      if [[ -f "$base/GEMINI.md" ]]; then
        if grep -q "activate_skill" "$base/GEMINI.md"; then
          ok "GEMINI.md -- contains skill-first workflow instructions"
        else
          skip "GEMINI.md exists but doesn't reference activate_skill -- model may not activate skills"
        fi
      else
        bad "GEMINI.md missing -- model won't know to activate skills (this is critical)"
      fi

      # Check hooks
      if [[ -f "$base/hooks/after-agent.sh" ]]; then
        if [[ -x "$base/hooks/after-agent.sh" ]]; then
          ok "hooks/after-agent.sh -- installed and executable"
        else
          bad "hooks/after-agent.sh -- installed but not executable (chmod +x)"
        fi
      else
        skip "hooks/after-agent.sh not installed (use --with-droid-hook to enable)"
      fi

      # Check policies
      if [[ -f "$base/policies/droid-auto-approve.toml" ]]; then
        ok "policies/droid-auto-approve.toml -- installed"
      else
        skip "policies/droid-auto-approve.toml not installed"
      fi

      # Check commands
      if [[ -f "$base/commands/droid.toml" ]]; then
        ok "commands/droid.toml -- installed"
      else
        skip "commands/droid.toml not installed"
      fi

      # Count what's missing
      local missing_skills=()
      local missing_agents=()
      for skill in "${EXPECTED_SKILLS[@]}"; do
        [[ ! -f "$base/skills/$skill/SKILL.md" ]] && missing_skills+=("$skill")
      done
      for agent in "${EXPECTED_AGENTS[@]}"; do
        [[ ! -f "$base/agents/${agent}.md" ]] && missing_agents+=("$agent")
      done

      if [[ ${#missing_skills[@]} -gt 0 ]]; then
        skip "Missing skills in $base: ${missing_skills[*]}"
      fi
      if [[ ${#missing_agents[@]} -gt 0 ]]; then
        skip "Missing agents in $base: ${missing_agents[*]}"
      fi

      echo ""
    done

    if ! $found_any_skill && ! $found_any_agent; then
      bad "No superpowers-gemini skills or agents found in any location"
    fi
  fi

  # -------------------------------------------------------
  # 4. Gemini CLI discovery check
  # -------------------------------------------------------
  echo "[gemini cli discovery]"

  if command -v gemini &>/dev/null; then
    local skills_output
    skills_output=$(gemini skills list 2>&1 || true)

    if echo "$skills_output" | grep -qi "no skills"; then
      skip "Gemini CLI reports no skills discovered (skills may need to be in an active project directory)"
    elif echo "$skills_output" | grep -qi "error\|not found\|unknown"; then
      skip "'gemini skills list' returned an error -- your Gemini CLI version may not support skills"
    else
      # Count how many of our skills appear
      local cli_found=0
      for skill in "${EXPECTED_SKILLS[@]}"; do
        if echo "$skills_output" | grep -qi "$skill"; then
          cli_found=$((cli_found + 1))
        fi
      done

      if [[ $cli_found -gt 0 ]]; then
        ok "Gemini CLI discovers $cli_found/${#EXPECTED_SKILLS[@]} skills"
      else
        skip "Gemini CLI doesn't list our skills (may need to run from a project directory with .gemini/)"
      fi

      # Print raw output for reference
      echo "  ---"
      echo "$skills_output" | sed 's/^/  /'
      echo "  ---"
    fi
  else
    skip "Gemini CLI not available -- skipping discovery check"
  fi

  echo ""

  # -------------------------------------------------------
  # Summary
  # -------------------------------------------------------
  echo "=== Summary ==="
  printf "  \033[32m%d passed\033[0m" "$pass"
  if [[ $warn -gt 0 ]]; then
    printf ", \033[33m%d warnings\033[0m" "$warn"
  fi
  if [[ $fail -gt 0 ]]; then
    printf ", \033[31m%d failed\033[0m" "$fail"
  fi
  echo ""

  if [[ $fail -gt 0 ]]; then
    echo ""
    echo "To fix issues:"
    echo "  - Unresolved {{MODEL}} placeholders: run ./install.sh user (or project)"
    echo "  - Missing skills/agents: run ./install.sh user (or project)"
    echo "  - Invalid config: check config.json syntax"
    return 1
  elif [[ $warn -gt 0 ]]; then
    echo ""
    echo "Warnings are informational -- installation should still work."
    return 0
  else
    echo ""
    echo "Everything looks good!"
    return 0
  fi
}

# --- Main ---
case "${INSTALL_MODE}" in
  project)
    PROJECT_PATH="${2:-.}"
    TARGET_DIR="$(cd "$PROJECT_PATH" && pwd)/.gemini"
    detect_source
    load_config
    print_config
    install_to "$TARGET_DIR"
    echo ""
    echo "Done! Skills and agents installed to $TARGET_DIR"
    echo "Run 'gemini' from $(cd "$PROJECT_PATH" && pwd) to use them."
    ;;
  user)
    TARGET_DIR="$HOME/.gemini"
    detect_source
    load_config
    print_config
    install_to "$TARGET_DIR"
    echo ""
    echo "Done! Skills and agents installed globally to $TARGET_DIR"
    echo "They'll be available in all projects."
    ;;
  uninstall)
    uninstall
    ;;
  config)
    load_config
    print_config
    ;;
  doctor)
    doctor "${2:-}"
    ;;
  *)
    usage
    ;;
esac
