#!/bin/bash
# =============================================================================
# check.sh — End-to-end health check for the offline AI coding setup
# Run this any time something feels broken.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DB="$HOME/Library/Application Support/Code/User/globalStorage/state.vscdb"

PASS="✅"
FAIL="❌"
WARN="⚠️ "

all_ok=true

check() {
  local label="$1"
  local result="$2"   # "ok", "warn", "fail"
  local detail="$3"
  case "$result" in
    ok)   echo "$PASS $label${detail:+: $detail}" ;;
    warn) echo "$WARN $label${detail:+: $detail}"; all_ok=false ;;
    fail) echo "$FAIL $label${detail:+: $detail}"; all_ok=false ;;
  esac
}

echo ""
echo "=== Offline AI Health Check ==="
echo ""

# ── Ollama binary ─────────────────────────────────────────────────────────────
if command -v ollama &>/dev/null; then
  check "Ollama binary" ok "$(ollama --version 2>/dev/null || echo 'found')"
else
  check "Ollama binary" fail "not installed — run: brew install ollama"
fi

# ── Ollama server ─────────────────────────────────────────────────────────────
if curl -sf http://localhost:11434 &>/dev/null; then
  check "Ollama server" ok "running at http://localhost:11434"
else
  check "Ollama server" fail "not running — run: ollama serve  (or install the LaunchAgent)"
fi

# ── LaunchAgent ───────────────────────────────────────────────────────────────
if [ -f "$HOME/Library/LaunchAgents/com.ollama.server.plist" ]; then
  if launchctl list | grep -q "com.ollama.server"; then
    check "Ollama LaunchAgent" ok "installed and loaded"
  else
    check "Ollama LaunchAgent" warn "plist exists but not loaded — run: install-launchagent.sh"
  fi
else
  check "Ollama LaunchAgent" warn "not installed — Ollama won't auto-start on boot"
fi

# ── OLLAMA_KEEP_ALIVE ─────────────────────────────────────────────────────────
if grep -q "OLLAMA_KEEP_ALIVE" "$HOME/Library/LaunchAgents/com.ollama.server.plist" 2>/dev/null; then
  check "OLLAMA_KEEP_ALIVE" ok "-1 (model stays in RAM indefinitely)"
else
  check "OLLAMA_KEEP_ALIVE" warn "not set — model will be evicted from RAM after 5 min idle"
fi

# ── Models ────────────────────────────────────────────────────────────────────
echo ""
PRIMARY="$("$SCRIPT_DIR/pick-models.sh" --primary 2>/dev/null || echo 'gemma4')"
DOWNLOADED=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')

if [ -z "$DOWNLOADED" ]; then
  check "Models" fail "no models downloaded — run: scripts/setup.sh"
else
  MODEL_COUNT=$(echo "$DOWNLOADED" | wc -l | tr -d ' ')
  check "Models downloaded" ok "$MODEL_COUNT model(s)"

  if echo "$DOWNLOADED" | grep -q "^${PRIMARY}"; then
    check "Primary model ($PRIMARY)" ok "available"
  else
    check "Primary model ($PRIMARY)" warn "not downloaded — run: ollama pull $PRIMARY"
  fi

  # Test that Ollama can actually respond with the primary model
  if curl -sf http://localhost:11434 &>/dev/null; then
    RESPONSE=$(curl -sf -X POST http://localhost:11434/api/generate \
      -H 'Content-Type: application/json' \
      -d "{\"model\":\"$PRIMARY\",\"prompt\":\"say hi\",\"stream\":false,\"options\":{\"num_predict\":5}}" \
      --max-time 30 2>/dev/null)
    if echo "$RESPONSE" | grep -q '"response"'; then
      check "Model inference ($PRIMARY)" ok "responds correctly"
    else
      check "Model inference ($PRIMARY)" warn "no response in 30s — model may still be loading"
    fi
  fi
fi

# ── VS Code ───────────────────────────────────────────────────────────────────
echo ""
if command -v code &>/dev/null; then
  check "VS Code CLI" ok "'code' command available"
else
  check "VS Code CLI" warn "not in PATH — open VS Code and install 'code' command"
fi

# ── VS Code extensions ────────────────────────────────────────────────────────
if command -v code &>/dev/null; then
  EXTENSIONS=$(code --list-extensions 2>/dev/null)
  if echo "$EXTENSIONS" | grep -qi "Continue.continue"; then
    check "Continue extension" ok "installed"
  else
    check "Continue extension" fail "missing — run: code --install-extension Continue.continue"
  fi

  if echo "$EXTENSIONS" | grep -qi "saoudrizwan.claude-dev"; then
    check "Cline extension" ok "installed"
  else
    check "Cline extension" fail "missing — run: code --install-extension saoudrizwan.claude-dev"
  fi
fi

# ── Continue config ───────────────────────────────────────────────────────────
if [ -f ~/.continue/config.json ]; then
  if python3 -m json.tool ~/.continue/config.json &>/dev/null; then
    MODEL_COUNT=$(python3 -c "import json; d=json.load(open('$HOME/.continue/config.json')); print(len(d.get('models',[])))" 2>/dev/null)
    check "Continue config" ok "${MODEL_COUNT:-?} model(s) configured"
  else
    check "Continue config" fail "invalid JSON — re-copy from repo: cp continue/config.json ~/.continue/config.json"
  fi
else
  check "Continue config" fail "missing — run: cp continue/config.json ~/.continue/config.json"
fi

# ── Cline config ──────────────────────────────────────────────────────────────
if [ -f "$STATE_DB" ]; then
  CLINE_VAL=$(sqlite3 "$STATE_DB" "SELECT value FROM ItemTable WHERE key='saoudrizwan.claude-dev';" 2>/dev/null)
  if echo "$CLINE_VAL" | grep -q '"apiProvider":"ollama"'; then
    CLINE_MODEL=$(echo "$CLINE_VAL" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('ollamaModelId','?'))" 2>/dev/null)
    check "Cline config" ok "Ollama → ${CLINE_MODEL}"
  else
    check "Cline config" fail "not set to Ollama — run: scripts/configure-cline.sh $PRIMARY"
  fi
else
  check "Cline config" warn "VS Code state DB not found — open VS Code once"
fi

# ── Cline watchdog ────────────────────────────────────────────────────────────
if [ -f "$HOME/Library/LaunchAgents/com.vscode.cline-watchdog.plist" ]; then
  if launchctl list | grep -q "com.vscode.cline-watchdog"; then
    check "Cline watchdog" ok "running (auto-restores config if reset by updates)"
  else
    check "Cline watchdog" warn "plist exists but not loaded — run: install-cline-watchdog.sh"
  fi
else
  check "Cline watchdog" warn "not installed — Cline config may reset on VS Code updates"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if $all_ok; then
  echo "✅ Everything looks good — you're ready to code offline!"
else
  echo "⚠️  Some issues found above. Fix them, then re-run: bash scripts/check.sh"
fi
echo ""
