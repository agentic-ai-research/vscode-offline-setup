#!/bin/bash
# =============================================================================
# install-cline-watchdog.sh
#
# Installs a launchd watchdog that monitors VS Code's state database.
# When Cline's config is reset (e.g. after a VS Code or Cline extension update),
# the watchdog detects the change and automatically re-applies the Ollama config.
#
# How it works:
#   - A LaunchAgent watches the state.vscdb file for modifications (WatchPaths)
#   - When the file changes, it runs cline-watchdog-runner.sh
#   - The runner checks if Cline's config has been reset (apiProvider missing)
#   - If reset, it re-applies configure-cline.sh silently
# =============================================================================

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.vscode.cline-watchdog.plist"
RUNNER="$HOME/.local/bin/cline-watchdog-runner.sh"
STATE_DB="$HOME/Library/Application Support/Code/User/globalStorage/state.vscdb"
CONFIGURE_CLINE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/configure-cline.sh"

# Resolve the primary model for this machine
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIMARY_MODEL="$("$SCRIPT_DIR/pick-models.sh" --primary 2>/dev/null || echo 'gemma4')"

if [ ! -f "$STATE_DB" ]; then
  echo "VS Code state database not found — open VS Code once first."
  exit 1
fi

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.ollama"

# Write the runner script that gets triggered on DB changes
cat > "$RUNNER" << RUNNER_EOF
#!/bin/bash
# Cline watchdog runner — called by launchd when state.vscdb changes

STATE_DB="\$HOME/Library/Application Support/Code/User/globalStorage/state.vscdb"
LOG="\$HOME/.ollama/cline-watchdog.log"
CONFIGURE_SCRIPT="${CONFIGURE_CLINE}"
MODEL="${PRIMARY_MODEL}"

# Give VS Code a moment to finish writing
sleep 3

# Check if Cline's apiProvider is still set to ollama
CURRENT=\$(sqlite3 "\$STATE_DB" "SELECT value FROM ItemTable WHERE key='saoudrizwan.claude-dev';" 2>/dev/null)

if echo "\$CURRENT" | grep -q '"apiProvider":"ollama"'; then
  # Config intact — nothing to do
  exit 0
fi

# Config was reset — restore it
echo "\$(date): Cline config was reset. Restoring Ollama config (model: \$MODEL)..." >> "\$LOG"
bash "\$CONFIGURE_SCRIPT" "\$MODEL" >> "\$LOG" 2>&1 \
  && echo "\$(date): Restored successfully." >> "\$LOG" \
  || echo "\$(date): Restore failed." >> "\$LOG"
RUNNER_EOF

chmod +x "$RUNNER"

# Install the LaunchAgent with WatchPaths
launchctl unload "$PLIST_FILE" &>/dev/null || true

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.vscode.cline-watchdog</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${RUNNER}</string>
  </array>

  <!-- Trigger whenever VS Code's state database is modified -->
  <key>WatchPaths</key>
  <array>
    <string>${STATE_DB}</string>
  </array>

  <key>StandardOutPath</key>
  <string>${HOME}/.ollama/cline-watchdog.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/.ollama/cline-watchdog.error.log</string>
</dict>
</plist>
EOF

launchctl load "$PLIST_FILE" 2>/dev/null \
  && echo "Cline watchdog installed — will auto-restore Ollama config if Cline resets" \
  || echo "Failed to load watchdog plist"
