# CLAUDE.md — VS Code Offline AI Setup

This repo automates setting up offline AI coding tools in VS Code on a new Mac.
When a user points Claude Code at this repo, follow the instructions below.

## What this repo does

Installs and configures:
- **Ollama** — local LLM server (port 11434)
- **Gemma 4 27B** — primary local AI model (~9.6 GB)
- **Continue** VS Code extension — AI chat + tab autocomplete
- **Cline** VS Code extension — autonomous AI coding agent

Target machine: macOS (Apple Silicon), 16 GB RAM minimum.

## How to run setup

When the user asks you to set up their machine, run this single command:

```bash
chmod +x scripts/setup.sh scripts/configure-cline.sh && bash scripts/setup.sh
```

That script handles everything end-to-end. After it finishes, tell the user:
> "Setup complete. Reload VS Code with Cmd+Shift+P → Developer: Reload Window."

## File reference

| File | Purpose |
|---|---|
| `scripts/setup.sh` | Master setup script — runs all steps in order |
| `scripts/configure-cline.sh` | Writes Cline's Ollama config into VS Code's state DB |
| `continue/config.json` | Continue extension config (models, autocomplete, embeddings) |
| `README.md` | Full manual setup guide with troubleshooting |

## Individual steps (if setup.sh fails partway)

### Install Ollama
```bash
brew install ollama && brew services start ollama
```

### Download models
```bash
ollama pull gemma4
ollama pull qwen2.5-coder:14b
ollama pull qwen2.5-coder:7b
```

### Install VS Code extensions
```bash
code --install-extension Continue.continue
code --install-extension saoudrizwan.claude-dev
```

### Apply Continue config
```bash
mkdir -p ~/.continue && cp continue/config.json ~/.continue/config.json
```

### Configure Cline
```bash
bash scripts/configure-cline.sh gemma4
```

## Switching models

To change the model Cline uses:
```bash
bash scripts/configure-cline.sh qwen2.5-coder:14b
```

To add a model to Continue, edit `~/.continue/config.json` and add a new entry to the `models` array, then reload VS Code.

## Verify everything is working

```bash
# Ollama running?
curl http://localhost:11434

# Models downloaded?
ollama list

# Model loaded in RAM?
ollama ps
```

## Notes

- 16 GB RAM is the minimum for Gemma 4 27B. It will work but leave little headroom — close Chrome and other heavy apps.
- If the user only has 8 GB RAM, use `qwen2.5-coder:7b` instead of `gemma4` throughout.
- Cline's config is written to VS Code's SQLite state database. If VS Code updates and resets it, re-run `configure-cline.sh`.
- The `code` CLI must be available in PATH. If not, open VS Code → Cmd+Shift+P → "Shell Command: Install 'code' command in PATH".
