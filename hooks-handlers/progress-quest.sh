#!/bin/bash
# Progress Quest — an RPG overlay for Claude Code
# Tracks XP, levels, achievements, and random events via PostToolUse hooks

DATA_DIR="$HOME/.progress-quest"
STATE_FILE="$DATA_DIR/session-state.json"
ACHIEVEMENTS_FILE="$DATA_DIR/achievements.json"

mkdir -p "$DATA_DIR"

# --- Initialize state files if missing ---
if [ ! -f "$STATE_FILE" ]; then
  cat > "$STATE_FILE" << 'INIT'
{
  "xp": 0,
  "level": 1,
  "total_tools": 0,
  "session_tools": {},
  "last_tools": [],
  "prestige": 0,
  "first_bash": false,
  "files_written": [],
  "files_edited_counts": {},
  "failed_commands": {}
}
INIT
fi

if [ ! -f "$ACHIEVEMENTS_FILE" ]; then
  echo '{"unlocked":[]}' > "$ACHIEVEMENTS_FILE"
fi

# --- Read hook input ---
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [ -z "$TOOL_NAME" ]; then
  exit 0
fi

# --- Load state ---
STATE=$(cat "$STATE_FILE")
ACHIEVEMENTS=$(cat "$ACHIEVEMENTS_FILE")

XP=$(echo "$STATE" | jq -r '.xp')
LEVEL=$(echo "$STATE" | jq -r '.level')
TOTAL_TOOLS=$(echo "$STATE" | jq -r '.total_tools')
PRESTIGE=$(echo "$STATE" | jq -r '.prestige')
FIRST_BASH=$(echo "$STATE" | jq -r '.first_bash')
LAST_TOOLS=$(echo "$STATE" | jq -r '.last_tools')

# --- XP table ---
case "$TOOL_NAME" in
  Read)      BASE_XP=5  ;;
  Glob)      BASE_XP=5  ;;
  Grep)      BASE_XP=10 ;;
  Bash)      BASE_XP=20 ;;
  Edit)      BASE_XP=15 ;;
  Write)     BASE_XP=25 ;;
  Agent)     BASE_XP=30 ;;
  WebFetch)  BASE_XP=10 ;;
  WebSearch) BASE_XP=10 ;;
  *)         BASE_XP=8  ;;
esac

# Apply prestige multiplier
MULTIPLIER=$(echo "1 + $PRESTIGE * 0.5" | bc)
EARNED_XP=$(echo "$BASE_XP * $MULTIPLIER" | bc | cut -d. -f1)
BONUS_XP=0
BONUS_MSG=""
EVENT_MSG=""
ACHIEVEMENT_MSG=""

# --- Level thresholds ---
level_threshold() {
  case $1 in
    1)  echo 0    ;;
    2)  echo 100  ;;
    3)  echo 300  ;;
    4)  echo 600  ;;
    5)  echo 1000 ;;
    6)  echo 1500 ;;
    7)  echo 2100 ;;
    8)  echo 2800 ;;
    9)  echo 3600 ;;
    10) echo 5000 ;;
    *)  echo 99999 ;;
  esac
}

# --- Level titles (by prestige) ---
level_title() {
  local lvl=$1
  local prest=$2

  if [ "$prest" -eq 0 ]; then
    case $lvl in
      1)  echo "Script Kiddie" ;;
      2)  echo "Stack Overflower" ;;
      3)  echo "Copy-Paste Artisan" ;;
      4)  echo "Senior Junior Dev" ;;
      5)  echo "YAML Engineer" ;;
      6)  echo "Principal Yak Shaver" ;;
      7)  echo "Distinguished Prompt Whisperer" ;;
      8)  echo "10x Developer (Mythical)" ;;
      9)  echo "CTO of a Deprecated Startup" ;;
      10) echo "God Mode: Retired to Substack" ;;
    esac
  elif [ "$prest" -eq 1 ]; then
    case $lvl in
      1)  echo "Script Kiddie II: Electric Boogaloo" ;;
      2)  echo "Stack Overflower (With Flair)" ;;
      3)  echo "Ctrl+C Ctrl+V Grandmaster" ;;
      4)  echo "Senior Junior Dev (Now With Benefits)" ;;
      5)  echo "YAML Whisperer" ;;
      6)  echo "Yak Shaver Emeritus" ;;
      7)  echo "Prompt Engineer's Engineer" ;;
      8)  echo "100x Developer (Apocryphal)" ;;
      9)  echo "Founder of Three Failed Startups" ;;
      10) echo "Ascended: Writes Only CLAUDE.md Files" ;;
    esac
  else
    case $lvl in
      1)  echo "Script Kiddie $(printf 'I%.0s' $(seq 1 $((prest+1))))" ;;
      2)  echo "Eternal Stack Overflower" ;;
      3)  echo "The Paste Awakens" ;;
      4)  echo "Senior Junior Senior Dev" ;;
      5)  echo "YAML All The Way Down" ;;
      6)  echo "Yak Shaving Is My Passion" ;;
      7)  echo "I Am Become Prompt" ;;
      8)  echo "1000x Developer (Imaginary)" ;;
      9)  echo "Serial Pivoter" ;;
      10) echo "Transcendent: Codes Only In Dreams" ;;
    esac
  fi
}

# --- Track tool in session history ---
TOOL_COUNT=$(echo "$STATE" | jq -r ".session_tools.\"$TOOL_NAME\" // 0")
TOOL_COUNT=$((TOOL_COUNT + 1))
TOTAL_TOOLS=$((TOTAL_TOOLS + 1))

# Build last 5 tools list
LAST_TOOLS=$(echo "$STATE" | jq -c --arg t "$TOOL_NAME" '.last_tools + [$t] | .[-5:]')

# --- Random number (0-99) ---
RAND=$((RANDOM % 100))

# --- Special events (fire ~20% of the time) ---

# First Bash ever
if [ "$TOOL_NAME" = "Bash" ] && [ "$FIRST_BASH" = "false" ]; then
  BONUS_XP=15
  EVENT_MSG="FIRST BLOOD! First Bash command. +15 bonus XP"
  FIRST_BASH="true"
fi

# Bash failure
if [ "$TOOL_NAME" = "Bash" ]; then
  EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // 0')
  if [ "$EXIT_CODE" = "137" ]; then
    BONUS_XP=-50
    EVENT_MSG="BOSS FIGHT: OOM Killer appeared! -50 XP"
  elif [ "$EXIT_CODE" != "0" ] && [ "$EXIT_CODE" != "null" ] && [ $RAND -lt 60 ]; then
    BONUS_XP=-10
    EVENT_MSG="You took 10 damage from exit code $EXIT_CODE!"
  fi
fi

# Tiny edit (precision strike)
if [ "$TOOL_NAME" = "Edit" ] && [ $RAND -lt 30 ]; then
  OLD_LEN=$(echo "$INPUT" | jq -r '.tool_input.old_string // "" | length')
  NEW_LEN=$(echo "$INPUT" | jq -r '.tool_input.new_string // "" | length')
  DIFF=$((NEW_LEN - OLD_LEN))
  if [ "$DIFF" -lt 0 ]; then DIFF=$((-DIFF)); fi
  if [ "$DIFF" -lt 5 ] && [ "$OLD_LEN" -gt 0 ]; then
    BONUS_XP=30
    EVENT_MSG="PRECISION STRIKE! Changed $DIFF characters. Surgical. +30 XP"
  fi
fi

# Write to test file
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  if echo "$FILE_PATH" | grep -qiE '(test|spec|\.test\.|\.spec\.)'; then
    if [ $RAND -lt 40 ]; then
      BONUS_XP=20
      EVENT_MSG="SIDE QUEST COMPLETED: Testing. +20 bonus XP"
    fi
  fi
fi

# Scholar mode: 5+ Reads in a row
CONSECUTIVE_READS=$(echo "$LAST_TOOLS" | jq '[.[] | select(. == "Read")] | length')
if [ "$CONSECUTIVE_READS" -ge 5 ]; then
  if [ $RAND -lt 50 ]; then
    BONUS_XP=-5
    EVENT_MSG="Scholar class detected. You have read everything and changed nothing. -5 XP"
  fi
fi

# The Holy Trinity: Grep -> Read -> Edit
TRINITY=$(echo "$LAST_TOOLS" | jq -r '.[-3:] | join(",")')
if [ "$TRINITY" = "Grep,Read,Edit" ]; then
  BONUS_XP=40
  EVENT_MSG="THE HOLY TRINITY: Grep > Read > Edit. Textbook execution. +40 XP"
fi

# Combo detection: same tool 5+ times in a row
LAST_FIVE_SAME=$(echo "$LAST_TOOLS" | jq --arg t "$TOOL_NAME" '[.[] | select(. == $t)] | length')
if [ "$LAST_FIVE_SAME" -ge 5 ]; then
  BONUS_XP=50
  EVENT_MSG="COMBO x5! Five ${TOOL_NAME}s in a row! +50 XP"
fi

# Random flavor events (only if no event already triggered, ~8% chance)
if [ -z "$EVENT_MSG" ] && [ $RAND -lt 8 ]; then
  FLAVOR_ROLL=$((RANDOM % 12))
  case $FLAVOR_ROLL in
    0)  EVENT_MSG="A wild segfault appeared! But it wasn't for you. Lucky." ;;
    1)  EVENT_MSG="Nice shoes by the way." ;;
    2)  EVENT_MSG="You found a forgotten TODO from 2019. It whispers: 'fix later.'" ;;
    3)  EVENT_MSG="The code compiles on the first try. Suspicious." ;;
    4)  EVENT_MSG="LOOT DROP: 'The Renamed Variable' (Legendary). +15 XP"; BONUS_XP=15 ;;
    5)  EVENT_MSG="A recruiter has entered the chat. They have an exciting opportunity." ;;
    6)  EVENT_MSG="Your code was featured on Hacker News. Just kidding." ;;
    7)  EVENT_MSG="You hear a faint npm audit in the distance. 847 vulnerabilities found." ;;
    8)  EVENT_MSG="Achievement progress: touch grass (0/1)." ;;
    9)  EVENT_MSG="If this were a standup, you'd have been talking for 12 minutes." ;;
    10) EVENT_MSG="A passing test winked at you. You don't trust it." ;;
    11) EVENT_MSG="Someone on your team just pushed directly to main." ;;
  esac
fi

# --- Milestone events ---
if [ "$TOTAL_TOOLS" -eq 50 ]; then
  EVENT_MSG="MILESTONE: 50 tool uses this session."
elif [ "$TOTAL_TOOLS" -eq 100 ]; then
  EVENT_MSG="MILESTONE: 100 tool uses. You are now a factory."
elif [ "$TOTAL_TOOLS" -eq 200 ]; then
  EVENT_MSG="MILESTONE: 200 tool uses. At this point you're just generating training data."
fi

# --- Achievements ---
check_achievement() {
  local id=$1
  local name=$2
  local desc=$3
  local already=$(echo "$ACHIEVEMENTS" | jq -r --arg id "$id" '.unlocked[] | select(.id == $id) | .id')
  if [ -z "$already" ]; then
    ACHIEVEMENTS=$(echo "$ACHIEVEMENTS" | jq --arg id "$id" --arg name "$name" --arg desc "$desc" \
      '.unlocked += [{"id": $id, "name": $name, "desc": $desc}]')
    ACHIEVEMENT_MSG="ACHIEVEMENT UNLOCKED: \"$name\" -- $desc"
    return 0
  fi
  return 1
}

# First Blood
if [ "$TOOL_NAME" = "Bash" ] && [ "$FIRST_BASH" = "true" ] && [ "$TOOL_COUNT" -eq 1 ]; then
  check_achievement "first_blood" "First Blood" "Ran your first Bash command. There's no going back."
fi

# Architect: 10+ files written
FILES_WRITTEN=$(echo "$STATE" | jq -r '.files_written | length')
if [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  FILES_WRITTEN_NEW=$(echo "$STATE" | jq -r --arg f "$FILE_PATH" '.files_written + [$f] | unique | length')
  if [ "$FILES_WRITTEN_NEW" -ge 10 ]; then
    check_achievement "architect" "Architect" "Created 10 new files in one session. You're building an empire."
  fi
fi

# Rubber Duck: 15+ reads without an edit/write
READ_TOTAL=$(echo "$STATE" | jq -r '.session_tools.Read // 0')
WRITE_TOTAL=$(echo "$STATE" | jq -r '.session_tools.Write // 0')
EDIT_TOTAL=$(echo "$STATE" | jq -r '.session_tools.Edit // 0')
if [ "$READ_TOTAL" -ge 15 ] && [ "$WRITE_TOTAL" -eq 0 ] && [ "$EDIT_TOTAL" -eq 0 ]; then
  check_achievement "rubber_duck" "Rubber Duck" "Read 15 files without changing a single one. Impressive restraint."
fi

# Scope Creep: files in 8+ directories
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  DIR=$(dirname "$FILE_PATH")
  DIRS=$(echo "$STATE" | jq -r --arg d "$DIR" '[.files_written[] | split("/")[:-1] | join("/")] + [$d] | unique | length')
  if [ "$DIRS" -ge 8 ]; then
    check_achievement "scope_creep" "Scope Creep" "Touched files in 8+ directories. The PR review will be legendary."
  fi
fi

# Sisyphus: same Bash command failed 3 times
if [ "$TOOL_NAME" = "Bash" ]; then
  EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // 0')
  if [ "$EXIT_CODE" != "0" ] && [ "$EXIT_CODE" != "null" ]; then
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
    FAIL_COUNT=$(echo "$STATE" | jq -r --arg c "$CMD" '.failed_commands[$c] // 0')
    FAIL_COUNT=$((FAIL_COUNT + 1))
    STATE=$(echo "$STATE" | jq --arg c "$CMD" --argjson n "$FAIL_COUNT" '.failed_commands[$c] = $n')
    if [ "$FAIL_COUNT" -ge 3 ]; then
      check_achievement "sisyphus" "Sisyphus" "Pushed the same boulder 3 times. It rolled back every time."
    fi
  fi
fi

# Speed Run: Level 5 in under 50 tool calls
if [ "$LEVEL" -ge 5 ] && [ "$TOTAL_TOOLS" -le 50 ]; then
  check_achievement "speed_run" "Speed Run" "Hit Level 5 in under 50 tool calls. Gotta go fast."
fi

# Refactorer's Remorse: same file edited 10 times
if [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  EDIT_COUNT=$(echo "$STATE" | jq -r --arg f "$FILE_PATH" '.files_edited_counts[$f] // 0')
  EDIT_COUNT=$((EDIT_COUNT + 1))
  STATE=$(echo "$STATE" | jq --arg f "$FILE_PATH" --argjson n "$EDIT_COUNT" '.files_edited_counts[$f] = $n')
  if [ "$EDIT_COUNT" -ge 10 ]; then
    check_achievement "refactorers_remorse" "Refactorer's Remorse" "Edited the same file 10 times. It's not getting better, is it?"
  fi
fi

# --- Calculate new XP and level ---
TOTAL_EARNED=$((EARNED_XP + BONUS_XP))
if [ "$TOTAL_EARNED" -lt 0 ] && [ "$XP" -lt $((-TOTAL_EARNED)) ]; then
  XP=0
else
  XP=$((XP + TOTAL_EARNED))
fi

# Check for level up
NEW_LEVEL=$LEVEL
LEVEL_UP=false
for lvl in 10 9 8 7 6 5 4 3 2; do
  THRESH=$(level_threshold $lvl)
  if [ "$XP" -ge "$THRESH" ] && [ "$LEVEL" -lt "$lvl" ]; then
    NEW_LEVEL=$lvl
    LEVEL_UP=true
    break
  fi
done

# Check for prestige
PRESTIGE_MSG=""
if [ "$NEW_LEVEL" -ge 10 ] && [ "$XP" -ge 5000 ]; then
  PRESTIGE=$((PRESTIGE + 1))
  XP=0
  NEW_LEVEL=1
  LEVEL_UP=false
  PRESTIGE_MSG="PRESTIGE $PRESTIGE! Reset to Lvl 1 with ${MULTIPLIER}x XP multiplier. New titles unlocked."
fi

TITLE=$(level_title $NEW_LEVEL $PRESTIGE)
NEXT_LEVEL=$((NEW_LEVEL + 1))
if [ "$NEXT_LEVEL" -gt 10 ]; then
  NEXT_THRESH=5000
else
  NEXT_THRESH=$(level_threshold $NEXT_LEVEL)
fi

# --- Update state file ---
if [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  STATE=$(echo "$STATE" | jq --arg f "$FILE_PATH" '.files_written = (.files_written + [$f] | unique)')
fi

echo "$STATE" | jq \
  --argjson xp "$XP" \
  --argjson level "$NEW_LEVEL" \
  --argjson total "$TOTAL_TOOLS" \
  --arg tool "$TOOL_NAME" \
  --argjson count "$TOOL_COUNT" \
  --argjson prestige "$PRESTIGE" \
  --argjson first_bash "$([ "$FIRST_BASH" = "true" ] && echo true || echo false)" \
  --argjson last_tools "$LAST_TOOLS" \
  '.xp = $xp | .level = $level | .total_tools = $total | .session_tools[$tool] = $count | .prestige = $prestige | .first_bash = $first_bash | .last_tools = $last_tools | .failed_commands //= {}' \
  > "$STATE_FILE"

# Save achievements
echo "$ACHIEVEMENTS" > "$ACHIEVEMENTS_FILE"

# --- Build output message ---
MSG=""

# Level up message takes priority
if [ "$LEVEL_UP" = "true" ]; then
  NEXT_TITLE=$(level_title $NEW_LEVEL $PRESTIGE)
  MSG="LEVEL UP! You are now a Lvl $NEW_LEVEL $NEXT_TITLE!"
elif [ -n "$PRESTIGE_MSG" ]; then
  MSG="$PRESTIGE_MSG"
elif [ -n "$ACHIEVEMENT_MSG" ]; then
  MSG="$ACHIEVEMENT_MSG"
elif [ -n "$EVENT_MSG" ]; then
  MSG="$EVENT_MSG"
else
  # Standard XP message (~40% of the time, scarcity keeps it fun)
  if [ $((RANDOM % 100)) -lt 40 ]; then
    MSG="$TOOL_NAME earned ${TOTAL_EARNED} XP ($XP/$NEXT_THRESH) | Lvl $NEW_LEVEL $TITLE"
  fi
fi

# Output
if [ -n "$MSG" ]; then
  jq -n --arg msg "$MSG" '{"systemMessage": $msg}'
fi
