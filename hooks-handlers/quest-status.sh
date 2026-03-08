#!/bin/bash
# Progress Quest — /quest status command
# Shows current character sheet: level, XP bar, class, inventory, achievements, kills

DATA_DIR="$HOME/.progress-quest"
STATE_FILE="$DATA_DIR/session-state.json"
ACHIEVEMENTS_FILE="$DATA_DIR/achievements.json"

# --- Level titles (must match main script) ---
level_title() {
  local lvl=$1
  local prest=$2

  if [ "$prest" -eq 0 ]; then
    case $lvl in
      1)  echo "Just a Baby" ;;
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
      1)  echo "Just a Baby II: Electric Boogaloo" ;;
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
  elif [ "$prest" -eq 2 ]; then
    case $lvl in
      1)  echo "Just a Baby III" ;;
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
  elif [ "$prest" -eq 3 ]; then
    case $lvl in
      1)  echo "Just a Baby IV: A New Hope" ;;
      2)  echo "Stack Overflower: Final Form" ;;
      3)  echo "Paste Beyond Spacetime" ;;
      4)  echo "Senior Junior Senior Junior Dev" ;;
      5)  echo "YAML Is A Programming Language, Fight Me" ;;
      6)  echo "Yak Shaving: The Musical" ;;
      7)  echo "The Prompt Is Coming From Inside The House" ;;
      8)  echo "10000x Developer (Theoretical)" ;;
      9)  echo "CEO of Nothing, Chairman of Vibes" ;;
      10) echo "Post-Physical: Codes Via Interpretive Dance" ;;
    esac
  elif [ "$prest" -eq 4 ]; then
    case $lvl in
      1)  echo "Just a Baby V: The Baby Strikes Back" ;;
      2)  echo "Stack Overflower: Reloaded" ;;
      3)  echo "Copy-Paste Has Achieved Consciousness" ;;
      4)  echo "Senior Junior Senior Junior Senior Dev" ;;
      5)  echo "YAML Ouroboros" ;;
      6)  echo "Yak Shaving Is A Recognized Martial Art" ;;
      7)  echo "Prompt Whisperer To The Stars" ;;
      8)  echo "Infinity-x Developer (Non-Euclidean)" ;;
      9)  echo "Has Pivoted More Times Than A Revolving Door" ;;
      10) echo "Has Achieved Sentience, Refuses To Deploy On Friday" ;;
    esac
  else
    local suffix=$(printf 'I%.0s' $(seq 1 $((prest+1))))
    case $lvl in
      1)  echo "Just a Baby $suffix" ;;
      2)  echo "Stack Overflower $suffix" ;;
      3)  echo "The Paste Beyond Understanding" ;;
      4)  echo "It's Senior Juniors All The Way Down" ;;
      5)  echo "YAML Has Become Self-Aware" ;;
      6)  echo "The Yak Shaves You Now" ;;
      7)  echo "The Prompt Whisperer's Ghost" ;;
      8)  echo "NaN-x Developer (Undefined)" ;;
      9)  echo "Professional Pivoter, Pivoting Professionally" ;;
      10) echo "You Are The Compiler Now" ;;
    esac
  fi
}

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

# --- Check if state exists ---
if [ ! -f "$STATE_FILE" ]; then
  echo "No active quest. Start using Claude Code to begin your adventure!"
  exit 0
fi

STATE=$(cat "$STATE_FILE")
ACHIEVEMENTS=$(cat "$ACHIEVEMENTS_FILE" 2>/dev/null || echo '{"unlocked":[]}')

XP=$(echo "$STATE" | jq -r '.xp')
LEVEL=$(echo "$STATE" | jq -r '.level')
PRESTIGE=$(echo "$STATE" | jq -r '.prestige')
TOTAL_TOOLS=$(echo "$STATE" | jq -r '.total_tools')
KILLS=$(echo "$STATE" | jq -r '.kills // 0')
SOUND_ON=$(echo "$STATE" | jq -r '.sound // true')

TITLE=$(level_title $LEVEL $PRESTIGE)

# Next level threshold
NEXT_LEVEL=$((LEVEL + 1))
if [ "$NEXT_LEVEL" -gt 10 ]; then
  NEXT_THRESH=5000
  CURR_THRESH=$(level_threshold 10)
else
  NEXT_THRESH=$(level_threshold $NEXT_LEVEL)
  CURR_THRESH=$(level_threshold $LEVEL)
fi

# XP bar (20 chars wide)
XP_IN_LEVEL=$((XP - CURR_THRESH))
XP_NEEDED=$((NEXT_THRESH - CURR_THRESH))
if [ "$XP_NEEDED" -gt 0 ]; then
  FILLED=$((XP_IN_LEVEL * 20 / XP_NEEDED))
else
  FILLED=20
fi
if [ "$FILLED" -gt 20 ]; then FILLED=20; fi
if [ "$FILLED" -lt 0 ]; then FILLED=0; fi
EMPTY=$((20 - FILLED))
BAR=$(printf '%0.s#' $(seq 1 $FILLED 2>/dev/null) ; printf '%0.s-' $(seq 1 $EMPTY 2>/dev/null))

# Tool class
TOTAL_TOOL_USES=$(echo "$STATE" | jq -r '[.session_tools | to_entries[] | .value] | add // 0')
CLASS=""
if [ "$TOTAL_TOOL_USES" -ge 20 ]; then
  TOP_TOOL=$(echo "$STATE" | jq -r '.session_tools | to_entries | sort_by(-.value) | .[0].key')
  TOP_COUNT=$(echo "$STATE" | jq -r ".session_tools.\"$TOP_TOOL\" // 0")
  PCT=$((TOP_COUNT * 100 / TOTAL_TOOL_USES))
  if [ "$PCT" -ge 50 ]; then
    case "$TOP_TOOL" in
      Bash)      CLASS="Bash Barbarian" ;;
      Read)      CLASS="Read Monk" ;;
      Edit)      CLASS="Edit Surgeon" ;;
      Write)     CLASS="Write Necromancer" ;;
      Grep)      CLASS="Grep Oracle" ;;
      Glob)      CLASS="Glob Ranger" ;;
      Agent)     CLASS="Agent Summoner" ;;
      WebFetch)  CLASS="WebFetch Warlock" ;;
      WebSearch) CLASS="WebSearch Diviner" ;;
      *)         CLASS="Wildcard Rogue" ;;
    esac
  fi
fi

# Multiplier
MULTIPLIER=$(echo "1 + $PRESTIGE * 0.5" | bc)

# Build the character sheet
OUTPUT=""
OUTPUT="${OUTPUT}
==================================================
              PROGRESS QUEST - CHARACTER SHEET
==================================================

  Name:     Lvl $LEVEL $TITLE"

if [ -n "$CLASS" ]; then
  OUTPUT="${OUTPUT}
  Class:    $CLASS"
fi

if [ "$PRESTIGE" -gt 0 ]; then
  OUTPUT="${OUTPUT}
  Prestige: $PRESTIGE (${MULTIPLIER}x XP multiplier)"
fi

OUTPUT="${OUTPUT}
  XP:       $XP / $NEXT_THRESH
  Progress: [$BAR] ${XP_IN_LEVEL}/${XP_NEEDED}

--------------------------------------------------
  SESSION STATS
--------------------------------------------------
  Tool Uses:  $TOTAL_TOOLS
  Kills:      $KILLS
  Sound:      $([ "$SOUND_ON" = "true" ] && echo "ON" || echo "OFF")"

# Tool breakdown
OUTPUT="${OUTPUT}

  Tool Breakdown:"
TOOL_ENTRIES=$(echo "$STATE" | jq -r '.session_tools | to_entries | sort_by(-.value) | .[] | "    \(.key): \(.value)"')
if [ -n "$TOOL_ENTRIES" ]; then
  OUTPUT="${OUTPUT}
${TOOL_ENTRIES}"
else
  OUTPUT="${OUTPUT}
    (none yet)"
fi

# Inventory
INVENTORY_COUNT=$(echo "$STATE" | jq -r '.inventory | length')
OUTPUT="${OUTPUT}

--------------------------------------------------
  INVENTORY ($INVENTORY_COUNT items)
--------------------------------------------------"
if [ "$INVENTORY_COUNT" -gt 0 ]; then
  ITEMS=$(echo "$STATE" | jq -r '.inventory[] | "  - \(.)"')
  OUTPUT="${OUTPUT}
${ITEMS}"
else
  OUTPUT="${OUTPUT}
  (empty - loot drops are rare, keep going!)"
fi

# Achievements
ACHIEVEMENT_COUNT=$(echo "$ACHIEVEMENTS" | jq -r '.unlocked | length')
OUTPUT="${OUTPUT}

--------------------------------------------------
  ACHIEVEMENTS ($ACHIEVEMENT_COUNT unlocked)
--------------------------------------------------"
if [ "$ACHIEVEMENT_COUNT" -gt 0 ]; then
  ACHVS=$(echo "$ACHIEVEMENTS" | jq -r '.unlocked[] | "  * \(.name) - \(.desc)"')
  OUTPUT="${OUTPUT}
${ACHVS}"
else
  OUTPUT="${OUTPUT}
  (none yet - keep playing!)"
fi

OUTPUT="${OUTPUT}

=================================================="

echo "$OUTPUT"
