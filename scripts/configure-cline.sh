#!/bin/bash
# Configures Cline in VS Code to use Ollama with a specified model.
# Usage: ./configure-cline.sh [model_name]
# Default model: gemma4

MODEL="${1:-gemma4}"
DB="$HOME/Library/Application Support/Code/User/globalStorage/state.vscdb"

if [ ! -f "$DB" ]; then
  echo "Error: VS Code state database not found at: $DB"
  echo "Make sure VS Code has been opened at least once."
  exit 1
fi

sqlite3 "$DB" "
  UPDATE ItemTable
  SET value = '{\"welcomeViewCompleted\":true,\"apiProvider\":\"ollama\",\"ollamaModelId\":\"$MODEL\",\"ollamaBaseUrl\":\"http://localhost:11434\"}'
  WHERE key = 'saoudrizwan.claude-dev';
"

echo "Cline configured: Ollama → $MODEL"
echo "Reload VS Code (Cmd+Shift+P → Developer: Reload Window) to apply."
