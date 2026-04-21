#!/bin/bash
# =============================================================================
# backup-vscode.sh — Backs up VS Code settings to this repo
#
# Captures: settings.json, keybindings.json, installed extensions list,
#           Continue config, and snippets.
#
# Usage:
#   bash scripts/backup-vscode.sh          # backs up to repo/vscode-backup/
#   bash scripts/backup-vscode.sh restore  # restores from repo/vscode-backup/
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/vscode-backup"
VSCODE_DIR="$HOME/Library/Application Support/Code/User"

backup() {
  mkdir -p "$BACKUP_DIR/snippets"

  # Core settings
  for f in settings.json keybindings.json; do
    if [ -f "$VSCODE_DIR/$f" ]; then
      cp "$VSCODE_DIR/$f" "$BACKUP_DIR/$f"
      echo "✅ Backed up $f"
    else
      echo "⏭️  $f not found (skipped)"
    fi
  done

  # Snippets
  if [ -d "$VSCODE_DIR/snippets" ]; then
    cp -r "$VSCODE_DIR/snippets/." "$BACKUP_DIR/snippets/"
    echo "✅ Backed up snippets"
  fi

  # Continue config
  if [ -f ~/.continue/config.json ]; then
    cp ~/.continue/config.json "$BACKUP_DIR/continue-config.json"
    echo "✅ Backed up Continue config"
  fi

  # Installed extensions list
  code --list-extensions 2>/dev/null > "$BACKUP_DIR/extensions.txt" \
    && echo "✅ Backed up extensions list ($(wc -l < "$BACKUP_DIR/extensions.txt" | tr -d ' ') extensions)" \
    || echo "⚠️  Could not list extensions ('code' CLI not found)"

  echo ""
  echo "Backup saved to: $BACKUP_DIR"
  echo "Commit it to keep it version-controlled:"
  echo "  cd $(cd "$SCRIPT_DIR/.." && pwd) && git add vscode-backup/ && git commit -m 'chore: update VS Code backup'"
}

restore() {
  if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ No backup found at $BACKUP_DIR"
    exit 1
  fi

  mkdir -p "$VSCODE_DIR/snippets"

  for f in settings.json keybindings.json; do
    if [ -f "$BACKUP_DIR/$f" ]; then
      cp "$BACKUP_DIR/$f" "$VSCODE_DIR/$f"
      echo "✅ Restored $f"
    fi
  done

  if [ -d "$BACKUP_DIR/snippets" ] && [ -n "$(ls -A "$BACKUP_DIR/snippets" 2>/dev/null)" ]; then
    cp -r "$BACKUP_DIR/snippets/." "$VSCODE_DIR/snippets/"
    echo "✅ Restored snippets"
  fi

  if [ -f "$BACKUP_DIR/continue-config.json" ]; then
    mkdir -p ~/.continue
    cp "$BACKUP_DIR/continue-config.json" ~/.continue/config.json
    echo "✅ Restored Continue config"
  fi

  if [ -f "$BACKUP_DIR/extensions.txt" ]; then
    echo ""
    echo "Installing extensions from backup..."
    while IFS= read -r ext; do
      [ -z "$ext" ] && continue
      code --install-extension "$ext" &>/dev/null \
        && echo "  ✅ $ext" || echo "  ❌ $ext (failed)"
    done < "$BACKUP_DIR/extensions.txt"
  fi

  echo ""
  echo "✅ Restore complete — reload VS Code to apply settings"
}

case "${1:-backup}" in
  backup)  backup ;;
  restore) restore ;;
  *)
    echo "Usage: backup-vscode.sh [backup|restore]"
    exit 1
    ;;
esac
