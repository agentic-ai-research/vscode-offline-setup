#!/bin/bash
# =============================================================================
# setup.sh — VS Code Offline AI Setup (resilient version)
# Each step is independent — re-running this script is always safe.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS="✅"
FAIL="❌"
SKIP="⏭️ "
WARN="⚠️ "

step_ok()   { echo "$PASS $1"; }
step_skip() { echo "$SKIP $1"; }
step_warn() { echo "$WARN $1"; }
step_fail() { echo "$FAIL $1"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   VS Code Offline AI Setup               ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Homebrew ──────────────────────────────────────────────────────────────
echo "[ 1 / 8 ] Homebrew"
if command -v brew &>/dev/null; then
  step_skip "Already installed ($(brew --version | head -1))"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    && step_ok "Installed" || step_fail "Homebrew install failed"
  # Apple Silicon PATH fix
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi
fi

# ── 2. Ollama ─────────────────────────────────────────────────────────────────
echo ""
echo "[ 2 / 8 ] Ollama"
if command -v ollama &>/dev/null; then
  step_skip "Already installed ($(ollama --version 2>/dev/null || echo 'unknown version'))"
else
  brew install ollama && step_ok "Installed" || step_fail "Ollama install failed"
fi

# Install the reliable LaunchAgent instead of brew service
"$SCRIPT_DIR/install-launchagent.sh" && step_ok "LaunchAgent configured" \
  || step_warn "LaunchAgent setup failed — Ollama may not start on boot"

# Wait for Ollama to be responsive
echo "      Waiting for Ollama to be ready..."
for i in {1..15}; do
  if curl -sf http://localhost:11434 &>/dev/null; then
    step_ok "Ollama is running at http://localhost:11434"
    break
  fi
  sleep 2
done
if ! curl -sf http://localhost:11434 &>/dev/null; then
  step_warn "Ollama not responding yet — continuing anyway (it may still be starting)"
fi

# ── 3. Models ─────────────────────────────────────────────────────────────────
echo ""
echo "[ 3 / 8 ] Models"
"$SCRIPT_DIR/pick-models.sh" --pull && step_ok "Models ready" \
  || step_warn "One or more models failed to download — run 'ollama list' to check"

# ── 4. VS Code CLI ────────────────────────────────────────────────────────────
echo ""
echo "[ 4 / 8 ] VS Code CLI"
if ! command -v code &>/dev/null; then
  step_warn "'code' CLI not found. Open VS Code and run:"
  echo "          Cmd+Shift+P → Shell Command: Install 'code' command in PATH"
  echo "          Then re-run this script."
  exit 1
fi
step_skip "'code' CLI available"

# ── 5. VS Code extensions ─────────────────────────────────────────────────────
echo ""
echo "[ 5 / 8 ] VS Code Extensions"
for ext in Continue.continue saoudrizwan.claude-dev; do
  if code --list-extensions 2>/dev/null | grep -qi "^${ext}$"; then
    step_skip "$ext already installed"
  else
    code --install-extension "$ext" &>/dev/null \
      && step_ok "$ext installed" || step_warn "$ext install failed"
  fi
done

# ── 6. Continue config ────────────────────────────────────────────────────────
echo ""
echo "[ 6 / 8 ] Continue config"
mkdir -p ~/.continue
if [ -f ~/.continue/config.json ]; then
  cp ~/.continue/config.json ~/.continue/config.json.bak
  step_skip "Backed up existing config to config.json.bak"
fi
cp "$REPO_DIR/continue/config.json" ~/.continue/config.json \
  && step_ok "Copied to ~/.continue/config.json" \
  || step_fail "Failed to copy Continue config"

# ── 7. Cline config ───────────────────────────────────────────────────────────
echo ""
echo "[ 7 / 8 ] Cline config"
PRIMARY_MODEL="$("$SCRIPT_DIR/pick-models.sh" --primary)"
"$SCRIPT_DIR/configure-cline.sh" "$PRIMARY_MODEL" \
  && step_ok "Cline → Ollama → $PRIMARY_MODEL" \
  || step_warn "Cline config failed — run configure-cline.sh manually"

# ── 8. Cline watchdog ─────────────────────────────────────────────────────────
echo ""
echo "[ 8 / 8 ] Cline watchdog (auto-restore after VS Code updates)"
"$SCRIPT_DIR/install-cline-watchdog.sh" && step_ok "Watchdog installed" \
  || step_warn "Watchdog install failed — Cline config may reset on VS Code updates"

# ── VS Code workspace tasks ───────────────────────────────────────────────────
mkdir -p "$REPO_DIR/.vscode"
cp "$REPO_DIR/vscode/tasks.json" "$REPO_DIR/.vscode/tasks.json" 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Setup complete!                        ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Next: Reload VS Code"
echo "        Cmd+Shift+P → Developer: Reload Window"
echo ""
echo "  Then run a health check:"
echo "        bash scripts/check.sh"
echo ""
echo "  Continue  → Cmd+L         (AI chat)"
echo "  Cline     → Activity Bar  (robot icon)"
echo ""
