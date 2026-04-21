#!/bin/bash
# =============================================================================
# pick-models.sh — RAM-aware model selection
#
# Usage:
#   pick-models.sh --primary   prints the best model name for this machine
#   pick-models.sh --pull      downloads the right set of models for this RAM
#   pick-models.sh --list      prints all recommended models for this RAM
# =============================================================================

# Detect RAM in GB (macOS)
RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
RAM_GB=$(( RAM_BYTES / 1024 / 1024 / 1024 ))

# Model tiers by RAM
if   (( RAM_GB >= 32 )); then
  PRIMARY="gemma4"
  MODELS=("gemma4" "qwen2.5-coder:14b" "qwen2.5-coder:7b" "deepseek-r1:7b")
  AUTOCOMPLETE="qwen2.5-coder:7b"
elif (( RAM_GB >= 16 )); then
  PRIMARY="gemma4"
  MODELS=("gemma4" "qwen2.5-coder:14b" "qwen2.5-coder:7b")
  AUTOCOMPLETE="qwen2.5-coder:7b"
elif (( RAM_GB >= 8 )); then
  PRIMARY="qwen2.5-coder:7b"
  MODELS=("qwen2.5-coder:7b" "phi4-mini")
  AUTOCOMPLETE="phi4-mini"
else
  PRIMARY="phi4-mini"
  MODELS=("phi4-mini")
  AUTOCOMPLETE="phi4-mini"
fi

case "${1:-}" in
  --primary)
    echo "$PRIMARY"
    ;;

  --autocomplete)
    echo "$AUTOCOMPLETE"
    ;;

  --list)
    echo "Detected RAM: ${RAM_GB}GB"
    echo "Primary model: $PRIMARY"
    echo "All models for this machine:"
    for m in "${MODELS[@]}"; do echo "  - $m"; done
    ;;

  --pull)
    echo "      Detected RAM: ${RAM_GB}GB → pulling ${#MODELS[@]} model(s)"
    FAILED=0
    for model in "${MODELS[@]}"; do
      if ollama show "$model" &>/dev/null; then
        echo "      ⏭️  $model already downloaded"
      else
        echo "      ⬇️  Pulling $model..."
        ollama pull "$model" && echo "      ✅ $model ready" \
          || { echo "      ❌ $model failed"; FAILED=1; }
      fi
    done
    exit $FAILED
    ;;

  *)
    echo "Usage: pick-models.sh [--primary | --autocomplete | --list | --pull]"
    exit 1
    ;;
esac
