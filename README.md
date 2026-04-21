# VS Code Offline AI Coding Setup

A complete, battle-hardened guide to running AI coding assistants in VS Code **fully offline** — no API keys, no internet, no usage costs. Designed to survive reboots, VS Code updates, and new machine migrations without breaking.

This setup uses:
- **Ollama** — runs local LLMs as a background server
- **Gemma 4 27B** (or RAM-appropriate alternative) — the local AI brain
- **Continue** — AI chat + autocomplete inside VS Code
- **Cline** — autonomous AI coding agent inside VS Code

---

## Quick Start

```bash
git clone https://github.com/agentic-ai-research/vscode-offline-setup
cd vscode-offline-setup
chmod +x scripts/*.sh
bash scripts/setup.sh
```

Then reload VS Code: `Cmd+Shift+P` → **Developer: Reload Window**

Run a health check: `bash scripts/check.sh`

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [What the Setup Script Does](#what-the-setup-script-does)
3. [Scripts Reference](#scripts-reference)
4. [Manual Setup Steps](#manual-setup-steps)
5. [Transferring to a New Computer](#transferring-to-a-new-computer)
6. [Model Recommendations by RAM](#model-recommendations-by-ram)
7. [How the Reliability Features Work](#how-the-reliability-features-work)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- macOS (Apple Silicon recommended — M1/M2/M3/M4)
- [VS Code](https://code.visualstudio.com/) installed and opened at least once
- `code` CLI available: VS Code → `Cmd+Shift+P` → **Shell Command: Install 'code' command in PATH**
- [Homebrew](https://brew.sh/) installed (or let `setup.sh` install it)
- 8 GB RAM minimum (16 GB recommended for Gemma 4 27B)

---

## What the Setup Script Does

`setup.sh` runs 8 steps and is safe to re-run at any time:

| Step | What it does |
|------|-------------|
| 1 | Installs Homebrew (if missing) |
| 2 | Installs Ollama + sets up a reliable LaunchAgent with `OLLAMA_KEEP_ALIVE=-1` |
| 3 | Downloads the right models for your RAM (auto-detected) |
| 4 | Checks for the `code` CLI |
| 5 | Installs Continue and Cline VS Code extensions |
| 6 | Copies `continue/config.json` to `~/.continue/config.json` |
| 7 | Configures Cline to use Ollama |
| 8 | Installs the Cline watchdog (auto-restores config after VS Code updates) |

---

## Scripts Reference

| Script | What it does |
|--------|-------------|
| `scripts/setup.sh` | Full end-to-end setup. Re-runnable. |
| `scripts/check.sh` | Health check — run this when something feels broken |
| `scripts/configure-cline.sh [model]` | Sets Cline's Ollama model. Default: auto-detected |
| `scripts/pick-models.sh --pull` | Downloads the right models for your RAM |
| `scripts/pick-models.sh --primary` | Prints the recommended primary model for your RAM |
| `scripts/install-launchagent.sh` | Installs reliable Ollama LaunchAgent with keep-alive |
| `scripts/install-cline-watchdog.sh` | Installs watchdog that auto-restores Cline config |
| `scripts/update-models.sh` | Pulls latest version of all downloaded models |
| `scripts/backup-vscode.sh` | Backs up VS Code settings, keybindings, extensions, snippets |
| `scripts/backup-vscode.sh restore` | Restores VS Code settings from backup |

### VS Code Tasks (no terminal needed)

Open the Command Palette (`Cmd+Shift+P`) → **Tasks: Run Task**:

- `AI: Health Check` — same as `check.sh`
- `AI: Restore Cline Config` — fixes Cline after a VS Code update
- `AI: Update Models` — updates all Ollama models
- `AI: Backup VS Code Settings` — saves settings to `vscode-backup/`

---

## Manual Setup Steps

### 1. Install Ollama

```bash
brew install ollama
bash scripts/install-launchagent.sh   # reliable boot start + keep-alive
```

### 2. Download Models

```bash
bash scripts/pick-models.sh --list    # see what's recommended for your RAM
bash scripts/pick-models.sh --pull    # download them
```

Or manually:

```bash
ollama pull gemma4            # 9.6 GB — best quality (16 GB RAM)
ollama pull qwen2.5-coder:14b # 9 GB   — best for code (16 GB RAM)
ollama pull qwen2.5-coder:7b  # 4.7 GB — fast autocomplete (8 GB RAM)
```

### 3. Install VS Code Extensions

```bash
code --install-extension Continue.continue
code --install-extension saoudrizwan.claude-dev
```

### 4. Configure Continue

```bash
mkdir -p ~/.continue
cp continue/config.json ~/.continue/config.json
```

### 5. Configure Cline

```bash
bash scripts/configure-cline.sh         # uses auto-detected primary model
bash scripts/configure-cline.sh gemma4  # or specify a model
```

### 6. Install Reliability Features

```bash
bash scripts/install-cline-watchdog.sh  # auto-restores Cline after updates
```

---

## Transferring to a New Computer

### Before you leave the old machine

```bash
bash scripts/backup-vscode.sh    # saves settings to vscode-backup/
git add vscode-backup/ && git commit -m "backup: pre-migration VS Code settings"
git push
```

### On the new machine

```bash
git clone https://github.com/agentic-ai-research/vscode-offline-setup
cd vscode-offline-setup
chmod +x scripts/*.sh
bash scripts/setup.sh              # installs everything
bash scripts/backup-vscode.sh restore   # restores your settings
```

That's it. The script auto-detects your new machine's RAM and picks the right models.

---

## Model Recommendations by RAM

| RAM | Primary Model | Also Pulled | Autocomplete |
|-----|--------------|-------------|--------------|
| 32 GB+ | `gemma4` | `qwen2.5-coder:14b`, `qwen2.5-coder:7b`, `deepseek-r1:7b` | `qwen2.5-coder:7b` |
| 16 GB | `gemma4` | `qwen2.5-coder:14b`, `qwen2.5-coder:7b` | `qwen2.5-coder:7b` |
| 8 GB | `qwen2.5-coder:7b` | `phi4-mini` | `phi4-mini` |
| <8 GB | `phi4-mini` | — | `phi4-mini` |

`pick-models.sh` detects your RAM and selects the right tier automatically.

---

## How the Reliability Features Work

### Ollama LaunchAgent (not brew service)

`install-launchagent.sh` writes a plist to `~/Library/LaunchAgents/com.ollama.server.plist` that:
- Starts Ollama on every login (more reliable than brew services on Apple Silicon)
- Sets `OLLAMA_KEEP_ALIVE=-1` — keeps the model loaded in RAM instead of evicting it after 5 minutes of inactivity
- Restarts Ollama automatically if it crashes

Logs: `~/.ollama/launchagent.log`

### Cline Watchdog

`install-cline-watchdog.sh` installs a LaunchAgent that:
- Watches VS Code's state database (`state.vscdb`) for file changes
- Whenever it changes (e.g., after a VS Code or Cline update resets extension state), checks if Cline's Ollama config is still intact
- If it was reset, silently re-applies the Ollama config within seconds

Logs: `~/.ollama/cline-watchdog.log`

### RAM-Aware Model Selection

`pick-models.sh` reads `hw.memsize` via `sysctl` and selects appropriate models for your machine's RAM, so the same setup script works on any Mac without manual adjustment.

---

## Troubleshooting

### Run the health check first

```bash
bash scripts/check.sh
```

This checks every component and tells you exactly what's broken and how to fix it.

---

### Ollama not running

```bash
# Check status
curl http://localhost:11434

# Start manually
ollama serve

# Or reinstall the LaunchAgent
bash scripts/install-launchagent.sh

# Check logs
cat ~/.ollama/launchagent.log
cat ~/.ollama/launchagent.error.log
```

### Cline shows wrong model / no provider after VS Code update

```bash
bash scripts/configure-cline.sh
# Then: Cmd+Shift+P → Developer: Reload Window
```

The watchdog should prevent this automatically — if it keeps happening, reinstall it:

```bash
bash scripts/install-cline-watchdog.sh
```

### Slow first response

With `OLLAMA_KEEP_ALIVE=-1` the model stays in RAM, but on first boot it still needs to load (~10–30 seconds for Gemma 4). Subsequent responses will be fast.

If it's always slow, check available RAM:

```bash
bash scripts/pick-models.sh --list   # shows recommended model for your RAM
```

### Models not appearing in Continue dropdown

1. Confirm model name in `~/.continue/config.json` exactly matches `ollama list`
2. Reload VS Code: `Cmd+Shift+P` → **Developer: Reload Window**

### Check what's in RAM right now

```bash
ollama ps
```

---

## Quick Reference

```bash
bash scripts/check.sh              # health check
bash scripts/setup.sh              # full setup (safe to re-run)
bash scripts/configure-cline.sh    # fix Cline config
bash scripts/update-models.sh      # update all models
bash scripts/backup-vscode.sh      # back up VS Code settings

ollama list                        # downloaded models
ollama pull <model>                # download a model
ollama ps                          # models in RAM
ollama rm <model>                  # delete a model
```
