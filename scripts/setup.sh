#!/bin/bash
set -e

echo "=== VS Code Offline AI Setup ==="
echo ""

# 1. Homebrew
if ! command -v brew &>/dev/null; then
  echo "[1/6] Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "[1/6] Homebrew already installed."
fi

# 2. Ollama
if ! command -v ollama &>/dev/null; then
  echo "[2/6] Installing Ollama..."
  brew install ollama
else
  echo "[2/6] Ollama already installed."
fi

echo "[2/6] Starting Ollama service..."
brew services start ollama
sleep 2

# 3. Models
echo "[3/6] Downloading models (this will take a while)..."
ollama pull gemma4
ollama pull qwen2.5-coder:14b
ollama pull qwen2.5-coder:7b

# 4. VS Code extensions
if ! command -v code &>/dev/null; then
  echo "[4/6] Warning: 'code' CLI not found. Open VS Code and run:"
  echo "       Shell Command: Install 'code' command in PATH"
  echo "       Then re-run this script."
  exit 1
fi

echo "[4/6] Installing VS Code extensions..."
code --install-extension Continue.continue
code --install-extension saoudrizwan.claude-dev

# 5. Continue config
echo "[5/6] Installing Continue config..."
mkdir -p ~/.continue
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/../continue/config.json" ~/.continue/config.json
echo "      Copied to ~/.continue/config.json"

# 6. Cline config
echo "[6/6] Configuring Cline..."
"$SCRIPT_DIR/configure-cline.sh" gemma4

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next: Reload VS Code with Cmd+Shift+P → Developer: Reload Window"
echo ""
echo "Tools ready:"
echo "  Continue  — AI chat & autocomplete (Cmd+L to open chat)"
echo "  Cline     — AI coding agent (click robot icon in Activity Bar)"
echo "  Model     — Gemma 4 27B via Ollama (localhost:11434)"
