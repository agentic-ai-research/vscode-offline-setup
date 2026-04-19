# VS Code Offline AI Coding Setup

A complete, reproducible guide to running AI coding assistants in VS Code **fully offline** — no API keys, no internet, no usage costs.

This setup uses:
- **Ollama** — runs local LLMs as a background server
- **Gemma 4 27B** (or any other model) — the local AI brain
- **Continue** — AI chat + autocomplete inside VS Code
- **Cline** — autonomous AI coding agent inside VS Code

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1 — Install Ollama](#step-1--install-ollama)
3. [Step 2 — Download a Model](#step-2--download-a-model)
4. [Step 3 — Install VS Code Extensions](#step-3--install-vs-code-extensions)
5. [Step 4 — Configure Continue](#step-4--configure-continue)
6. [Step 5 — Configure Cline](#step-5--configure-cline)
7. [Transferring to a New Computer](#transferring-to-a-new-computer)
8. [Model Recommendations](#model-recommendations)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- macOS (Apple Silicon recommended — M1/M2/M3/M4)
- [VS Code](https://code.visualstudio.com/) installed
- [Homebrew](https://brew.sh/) installed
- At least 16 GB RAM for 27B models; 8 GB works for smaller models (7B–9B)

---

## Step 1 — Install Ollama

```bash
brew install ollama
```

Start the Ollama server (runs in the background on port 11434):

```bash
ollama serve
```

To have Ollama start automatically on login:

```bash
brew services start ollama
```

Verify it's running:

```bash
curl http://localhost:11434
# Should return: Ollama is running
```

---

## Step 2 — Download a Model

### Gemma 4 27B (recommended for 16 GB RAM)

```bash
ollama pull gemma4
```

~9.6 GB download. Uses ~14–16 GB RAM when loaded.

### Lighter alternatives (8 GB RAM)

```bash
ollama pull qwen2.5-coder:7b     # Great for code, fast
ollama pull gemma4:4b             # Smaller Gemma 4 variant
ollama pull phi4-mini             # Very fast, surprisingly capable
```

List all downloaded models:

```bash
ollama list
```

---

## Step 3 — Install VS Code Extensions

Install both extensions from the terminal:

```bash
# Continue — AI chat + inline autocomplete
code --install-extension Continue.continue

# Cline — autonomous AI coding agent
code --install-extension saoudrizwan.claude-dev
```

---

## Step 4 — Configure Continue

Continue is configured via `~/.continue/config.json`.

### Full config (copy-paste ready)

```json
{
  "models": [
    {
      "title": "Gemma 4 27B (Local)",
      "provider": "ollama",
      "model": "gemma4",
      "apiBase": "http://localhost:11434",
      "contextLength": 32768,
      "completionOptions": {
        "temperature": 0.1,
        "maxTokens": 4096
      }
    },
    {
      "title": "Qwen Coder 14B (Fast)",
      "provider": "ollama",
      "model": "qwen2.5-coder:14b",
      "apiBase": "http://localhost:11434",
      "contextLength": 32768,
      "completionOptions": {
        "temperature": 0.1,
        "maxTokens": 4096
      }
    }
  ],
  "tabAutocompleteModel": {
    "title": "Tab Autocomplete",
    "provider": "ollama",
    "model": "qwen2.5-coder:7b",
    "apiBase": "http://localhost:11434"
  },
  "allowAnonymousTelemetry": false,
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text",
    "apiBase": "http://localhost:11434"
  }
}
```

> **Tip:** Add as many models as you like. You can switch between them in Continue's model picker at the bottom of the chat panel.

### Apply the config

```bash
# Create the directory if it doesn't exist
mkdir -p ~/.continue

# Open the config file
code ~/.continue/config.json
```

Paste the config above, save, and reload VS Code (`Cmd+Shift+P` → `Developer: Reload Window`).

---

## Step 5 — Configure Cline

Cline stores its settings in VS Code's internal SQLite state database. The easiest way to configure it on a new machine is via the UI or via a script.

### Option A — Via the VS Code UI (simplest)

1. Open VS Code
2. Click the **Cline icon** in the Activity Bar (robot icon on the left)
3. On the welcome screen, choose **Ollama** as the provider
4. Set model to `gemma4` (or any `ollama list` model name)
5. Set API base URL to `http://localhost:11434`

### Option B — Via script (for automation / new machines)

This script writes directly to VS Code's state database:

```bash
#!/bin/bash
# configure-cline.sh
# Sets Cline to use Ollama with a specified model

MODEL="${1:-gemma4}"
DB="$HOME/Library/Application Support/Code/User/globalStorage/state.vscdb"

sqlite3 "$DB" "
  UPDATE ItemTable
  SET value = '{\"welcomeViewCompleted\":true,\"apiProvider\":\"ollama\",\"ollamaModelId\":\"$MODEL\",\"ollamaBaseUrl\":\"http://localhost:11434\"}'
  WHERE key = 'saoudrizwan.claude-dev';
"

echo "Cline configured to use Ollama model: $MODEL"
echo "Reload VS Code (Cmd+Shift+P → Developer: Reload Window) to apply."
```

Make it executable and run:

```bash
chmod +x configure-cline.sh
./configure-cline.sh gemma4
```

To switch models later:

```bash
./configure-cline.sh qwen2.5-coder:14b
```

---

## Transferring to a New Computer

Everything you need to copy to a new Mac:

### Files to back up

| File / Path | What it is |
|---|---|
| `~/.continue/config.json` | Continue model config |
| `scripts/configure-cline.sh` | Cline setup script (from this repo) |

### Steps on the new machine

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Ollama
brew install ollama
brew services start ollama

# 3. Download models (will take a while)
ollama pull gemma4
ollama pull qwen2.5-coder:14b
ollama pull qwen2.5-coder:7b

# 4. Install VS Code extensions
code --install-extension Continue.continue
code --install-extension saoudrizwan.claude-dev

# 5. Restore Continue config
mkdir -p ~/.continue
cp config.json ~/.continue/config.json

# 6. Configure Cline
./configure-cline.sh gemma4

# 7. Reload VS Code
# Cmd+Shift+P → Developer: Reload Window
```

---

## Model Recommendations

| Model | Size | RAM | Best for |
|---|---|---|---|
| `gemma4` | 9.6 GB | 16 GB | Best quality, general coding |
| `qwen2.5-coder:14b` | 9 GB | 16 GB | Best for code specifically |
| `qwen2.5-coder:7b` | 4.7 GB | 8 GB | Fast autocomplete |
| `phi4-mini` | 2.5 GB | 8 GB | Very fast, low memory |
| `deepseek-r1:7b` | 4.7 GB | 8 GB | Reasoning / debugging |

Pull any model with `ollama pull <name>`.

---

## Troubleshooting

### Ollama not running / models not appearing in Continue

```bash
# Check if Ollama is running
curl http://localhost:11434

# Start it manually if not
ollama serve

# Or as a background service
brew services start ollama
```

### Model not showing in Continue dropdown

1. Make sure the model name in `~/.continue/config.json` exactly matches `ollama list`
2. Reload VS Code (`Cmd+Shift+P` → `Developer: Reload Window`)

### Cline shows wrong model after restart

VS Code sometimes resets extension state on update. Re-run `configure-cline.sh` or reconfigure via the Cline UI.

### Slow responses on 16 GB Mac

- Use a smaller model (`qwen2.5-coder:7b` or `phi4-mini`) for autocomplete
- Close other memory-heavy apps (Chrome, etc.) before loading large models
- Gemma 4 27B is the upper limit for 16 GB — it works but leaves little headroom

### Check which model is loaded in RAM

```bash
ollama ps
```

---

## Quick Reference

```bash
ollama list              # Show downloaded models
ollama pull <model>      # Download a model
ollama ps                # Show models currently in RAM
ollama rm <model>        # Delete a model
brew services start ollama   # Auto-start Ollama on login
brew services stop ollama    # Stop auto-start
```
