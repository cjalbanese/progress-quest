#!/bin/bash
# Progress Quest uninstaller for Claude Code

set -e

SETTINGS_FILE="$HOME/.claude/settings.json"

echo "Uninstalling Progress Quest..."

# Remove the hook script
rm -f "$HOME/.claude/hooks/progress-quest.sh"

# Remove from settings.json
if [ -f "$SETTINGS_FILE" ]; then
  jq '.hooks.PostToolUse = [.hooks.PostToolUse[]? | select(.hooks[]?.command | contains("progress-quest") | not)]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
  mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

  # Clean up empty PostToolUse array
  REMAINING=$(jq '.hooks.PostToolUse | length' "$SETTINGS_FILE")
  if [ "$REMAINING" = "0" ]; then
    jq 'del(.hooks.PostToolUse)' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  fi

  # Clean up empty hooks object
  HOOK_KEYS=$(jq '.hooks | keys | length' "$SETTINGS_FILE" 2>/dev/null || echo "0")
  if [ "$HOOK_KEYS" = "0" ]; then
    jq 'del(.hooks)' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  fi
fi

echo ""
echo "Progress Quest uninstalled."
echo ""
echo "Your achievements are still saved at ~/.progress-quest/achievements.json"
echo "To fully remove all data: rm -rf ~/.progress-quest"
