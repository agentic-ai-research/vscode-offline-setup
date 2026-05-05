#!/bin/bash
# Configures Continue and Cline in VS Code to use Jan.ai's local API server.
# Usage: ./configure-jan.sh [model_id]
# If no model_id given, auto-detects the first available model from Jan.ai.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAN_API="http://localhost:1337/v1"
DB="$HOME/Library/Application Support/Code/User/globalStorage/state.vscdb"
CONTINUE_CONFIG="$HOME/.continue/config.json"

# ── Resolve model ─────────────────────────────────────────────────────────────
if [ -n "$1" ]; then
  MODEL="$1"
else
  echo "No model specified — querying Jan.ai for available models..."
  MODELS_JSON=$(curl -sf --max-time 5 "$JAN_API/models" 2>/dev/null)
  if [ -z "$MODELS_JSON" ]; then
    echo "Error: Jan.ai is not running or not reachable at $JAN_API"
    echo "Open the Jan desktop app and make sure a model is loaded, then retry."
    exit 1
  fi
  MODEL=$(echo "$MODELS_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
models = data.get('data', [])
if not models:
    print('')
else:
    # Prefer coding models, otherwise take the first
    coding = [m['id'] for m in models if any(k in m['id'].lower() for k in ('coder','code','deepseek','qwen'))]
    print(coding[0] if coding else models[0]['id'])
" 2>/dev/null)
  if [ -z "$MODEL" ]; then
    echo "Error: Jan.ai returned no models. Load a model in the Jan app first."
    exit 1
  fi
  echo "Detected model: $MODEL"
fi

# ── Configure Continue ────────────────────────────────────────────────────────
mkdir -p "$HOME/.continue"

# Backup existing config if it isn't already a Jan config
if [ -f "$CONTINUE_CONFIG" ] && ! grep -q '"apiBase": "http://localhost:1337"' "$CONTINUE_CONFIG" 2>/dev/null; then
  cp "$CONTINUE_CONFIG" "${CONTINUE_CONFIG}.ollama-backup"
  echo "Backed up existing Continue config to ${CONTINUE_CONFIG}.ollama-backup"
fi

# Substitute model ID into the Jan template
sed "s/__MODEL_ID__/$MODEL/g" "$SCRIPT_DIR/../continue/config.jan.json" > "$CONTINUE_CONFIG"
echo "Continue config written: $CONTINUE_CONFIG → $MODEL"

# ── Configure Cline ───────────────────────────────────────────────────────────
if [ ! -f "$DB" ]; then
  echo ""
  echo "Warning: VS Code state database not found at: $DB"
  echo "Open VS Code once, then re-run this script to configure Cline."
else
  sqlite3 "$DB" "
    UPDATE ItemTable
    SET value = '{\"welcomeViewCompleted\":true,\"apiProvider\":\"openai\",\"openAiBaseUrl\":\"http://localhost:1337\",\"openAiApiKey\":\"jan\",\"openAiModelId\":\"$MODEL\"}'
    WHERE key = 'saoudrizwan.claude-dev';
  "
  echo "Cline config written: Jan.ai → $MODEL"
fi

echo ""
echo "Done. Reload VS Code (Cmd+Shift+P → Developer: Reload Window) to apply."
