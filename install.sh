#!/bin/bash
# Progress Quest installer for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/cjalbanese/progress-quest/main/install.sh | bash

set -e

HOOK_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"
SCRIPT_URL="https://raw.githubusercontent.com/cjalbanese/progress-quest/main/hooks-handlers/progress-quest.sh"
STATUS_URL="https://raw.githubusercontent.com/cjalbanese/progress-quest/main/hooks-handlers/quest-status.sh"

echo "Installing Progress Quest for Claude Code..."

# Create hooks directory
mkdir -p "$HOOK_DIR"
mkdir -p "$HOME/.progress-quest"

# Download the hook scripts
curl -fsSL "$SCRIPT_URL" -o "$HOOK_DIR/progress-quest.sh"
curl -fsSL "$STATUS_URL" -o "$HOOK_DIR/quest-status.sh"
chmod +x "$HOOK_DIR/progress-quest.sh"
chmod +x "$HOOK_DIR/quest-status.sh"

# Check for jq dependency
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  echo "  macOS:  brew install jq"
  echo "  Ubuntu: sudo apt install jq"
  exit 1
fi

# Merge hook into settings.json
HOOK_ENTRY='{
  "hooks": [{
    "type": "command",
    "command": "$HOME/.claude/hooks/progress-quest.sh",
    "timeout": 10
  }]
}'

if [ ! -f "$SETTINGS_FILE" ]; then
  # No settings file — create one
  echo "{}" > "$SETTINGS_FILE"
fi

# Check if hooks.PostToolUse already exists
HAS_HOOKS=$(jq -r '.hooks.PostToolUse // empty' "$SETTINGS_FILE")

if [ -z "$HAS_HOOKS" ]; then
  # No PostToolUse hooks — add the array
  jq --argjson hook "$HOOK_ENTRY" '.hooks.PostToolUse = [$hook]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
  mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
else
  # PostToolUse exists — check if progress-quest is already there
  ALREADY=$(jq -r '.hooks.PostToolUse[] | .hooks[]? | select(.command | contains("progress-quest"))' "$SETTINGS_FILE")
  if [ -z "$ALREADY" ]; then
    jq --argjson hook "$HOOK_ENTRY" '.hooks.PostToolUse += [$hook]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  else
    echo "Progress Quest hook already registered in settings."
  fi
fi

echo ""
echo "Progress Quest installed!"
echo "Start a new Claude Code session to begin earning XP."
echo ""
echo "  State:        ~/.progress-quest/session-state.json"
echo "  Achievements: ~/.progress-quest/achievements.json"
echo "  Status:       Run 'bash ~/.claude/hooks/quest-status.sh' to see your character sheet"
echo ""
echo "To uninstall: bash <(curl -fsSL https://raw.githubusercontent.com/cjalbanese/progress-quest/main/uninstall.sh)"
