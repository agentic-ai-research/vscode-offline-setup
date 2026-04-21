#!/bin/bash
# =============================================================================
# install-launchagent.sh — Installs a reliable macOS LaunchAgent for Ollama
#
# Why not just `brew services start ollama`?
# Brew services use launchd under the hood but can fail to start after hard
# reboots on Apple Silicon. This script installs the plist directly and sets
# OLLAMA_KEEP_ALIVE=-1 so the model stays loaded in RAM instead of being
# evicted after 5 minutes of inactivity.
# =============================================================================

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.ollama.server.plist"
OLLAMA_BIN="$(command -v ollama)"

if [ -z "$OLLAMA_BIN" ]; then
  echo "Ollama not found in PATH. Install it first."
  exit 1
fi

mkdir -p "$PLIST_DIR"

# Stop any existing brew service to avoid conflicts
brew services stop ollama &>/dev/null || true
launchctl unload "$PLIST_FILE" &>/dev/null || true

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.ollama.server</string>

  <key>ProgramArguments</key>
  <array>
    <string>${OLLAMA_BIN}</string>
    <string>serve</string>
  </array>

  <!-- Keep model in RAM indefinitely — no 5-minute eviction -->
  <key>EnvironmentVariables</key>
  <dict>
    <key>OLLAMA_KEEP_ALIVE</key>
    <string>-1</string>
    <key>HOME</key>
    <string>${HOME}</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>

  <!-- Start on login, restart if it crashes -->
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>

  <!-- Logs -->
  <key>StandardOutPath</key>
  <string>${HOME}/.ollama/launchagent.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/.ollama/launchagent.error.log</string>
</dict>
</plist>
EOF

launchctl load "$PLIST_FILE" 2>/dev/null

# Wait a moment and verify
sleep 2
if curl -sf http://localhost:11434 &>/dev/null; then
  echo "Ollama LaunchAgent installed and running (OLLAMA_KEEP_ALIVE=-1)"
else
  echo "LaunchAgent installed — Ollama will start on next login"
fi
