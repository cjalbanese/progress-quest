---
description: Show your Progress Quest character sheet — level, XP, class, inventory, achievements, and stats
---

Run the following command and display the output to the user exactly as-is (preserve all formatting and ASCII art):

```bash
bash ~/.claude/hooks/quest-status.sh 2>/dev/null || bash "$CLAUDE_PLUGIN_ROOT/hooks-handlers/quest-status.sh" 2>/dev/null || echo "Progress Quest not found. Install it first."
```
