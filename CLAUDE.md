# CLAUDE.md — VS Code Offline AI Setup

This repo automates setting up offline AI coding tools in VS Code on a new Mac.
When a user points Claude Code at this repo, follow the instructions below.

## What this repo does

Installs and configures:
- **Ollama** — local LLM server (port 11434) with reliable LaunchAgent + keep-alive
- **Jan.ai** — alternative local LLM desktop app (port 1337, OpenAI-compatible API)
- **Gemma 4 27B** (or RAM-appropriate model) — primary local AI model
- **Continue** VS Code extension — AI chat + tab autocomplete
- **Cline** VS Code extension — autonomous AI coding agent
- **Cline watchdog** — auto-restores Cline config if VS Code updates reset it

Both Ollama and Jan.ai can serve as the active backend. Use `configure-jan.sh` or `configure-cline.sh` to switch.

Target machine: macOS (Apple Silicon), 8 GB RAM minimum (16 GB for Gemma 4).

## How to run setup on a new machine

When the user asks you to set up their machine, run:

```bash
chmod +x scripts/*.sh && bash scripts/setup.sh
```

That script handles everything end-to-end. After it finishes tell the user:
> "Setup complete. Reload VS Code with Cmd+Shift+P → Developer: Reload Window, then run `bash scripts/check.sh` to verify."

## How to run a health check

```bash
bash scripts/check.sh
```

This checks every component. Read the output — any ❌ or ⚠️ line includes the fix command.

## File reference

| File | Purpose |
|------|---------|
| `scripts/setup.sh` | Master setup (resilient, re-runnable, 8 steps) |
| `scripts/check.sh` | Full health check with fix hints |
| `scripts/configure-jan.sh [model]` | Writes Jan.ai config into Continue + VS Code's state DB |
| `scripts/configure-cline.sh [model]` | Writes Ollama config into VS Code's state DB |
| `continue/config.jan.json` | Continue extension template for Jan.ai backend |
| `scripts/pick-models.sh` | RAM-aware model selection |
| `scripts/install-launchagent.sh` | Reliable Ollama boot service + OLLAMA_KEEP_ALIVE=-1 |
| `scripts/install-cline-watchdog.sh` | Watchdog that auto-restores Cline after VS Code updates |
| `scripts/update-models.sh` | Pull latest versions of all downloaded models |
| `scripts/backup-vscode.sh` | Backup/restore VS Code settings, keybindings, extensions |
| `continue/config.json` | Continue extension config (models + autocomplete) |
| `vscode/tasks.json` | VS Code tasks for health check, restore, update, backup |
| `vscode-backup/` | User's backed-up VS Code settings (committed to repo) |

## Individual fix commands

### Switch to Jan.ai backend
```bash
bash scripts/configure-jan.sh [model-id]
# Then: Cmd+Shift+P → Developer: Reload Window
```
If Jan.ai is running and a model is loaded, the model-id arg is optional — it auto-detects.

### Switch back to Ollama backend
```bash
bash scripts/configure-cline.sh
# Then: Cmd+Shift+P → Developer: Reload Window
```

### Ollama not running
```bash
bash scripts/install-launchagent.sh
```

### Cline config was reset by a VS Code update
```bash
bash scripts/configure-cline.sh
# Then: Cmd+Shift+P → Developer: Reload Window
```

### Missing models
```bash
bash scripts/pick-models.sh --pull
```

### Restore VS Code settings from backup
```bash
bash scripts/backup-vscode.sh restore
```

### Update all models to latest
```bash
bash scripts/update-models.sh
```

## Notes for Claude Code

- Always run `check.sh` after making any changes to verify the fix worked.
- If the user is on 8 GB RAM, the primary model will be `qwen2.5-coder:7b`, not `gemma4`. Do not override `pick-models.sh`.
- The Cline watchdog writes logs to `~/.ollama/cline-watchdog.log` — check this if Cline config keeps resetting.
- `setup.sh` is idempotent — re-running it is always safe and will skip already-completed steps.
- VS Code must be opened and closed once before the state DB exists for Cline config to be written.
