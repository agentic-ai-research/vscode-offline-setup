#!/bin/bash
# =============================================================================
# update-models.sh — Pull the latest version of all downloaded Ollama models
#
# Safe to run at any time. Skips models that are already up-to-date.
# Usage: bash scripts/update-models.sh
# =============================================================================

echo "=== Updating Ollama models ==="
echo ""

if ! curl -sf http://localhost:11434 &>/dev/null; then
  echo "❌ Ollama is not running. Start it first: ollama serve"
  exit 1
fi

MODELS=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')

if [ -z "$MODELS" ]; then
  echo "No models downloaded yet."
  exit 0
fi

COUNT=0
UPDATED=0
FAILED=0

while IFS= read -r model; do
  (( COUNT++ ))
  echo "⬇️  Checking $model..."
  if ollama pull "$model" 2>&1 | grep -q "up to date"; then
    echo "   ⏭️  Already up to date"
  elif ollama pull "$model" &>/dev/null; then
    echo "   ✅ Updated"
    (( UPDATED++ ))
  else
    echo "   ❌ Failed to update $model"
    (( FAILED++ ))
  fi
done <<< "$MODELS"

echo ""
echo "=== Done: $COUNT model(s) checked, $UPDATED updated, $FAILED failed ==="
