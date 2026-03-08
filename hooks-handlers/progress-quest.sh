#!/bin/bash
# Progress Quest — an RPG overlay for Claude Code
# Tracks XP, levels, achievements, loot, and random events via PostToolUse hooks

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
  "failed_commands": {},
  "consecutive_failures": 0,
  "inventory": [],
  "dirs_touched": []
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
CONSEC_FAILS=$(echo "$STATE" | jq -r '.consecutive_failures // 0')

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
  elif [ "$prest" -eq 2 ]; then
    case $lvl in
      1)  echo "Script Kiddie III" ;;
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
      1)  echo "Script Kiddie IV: A New Hope" ;;
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
      1)  echo "Script Kiddie V: The Kiddie Strikes Back" ;;
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
    # Prestige 5+
    local suffix=$(printf 'I%.0s' $(seq 1 $((prest+1))))
    case $lvl in
      1)  echo "Script Kiddie $suffix" ;;
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

# --- Track tool in session history ---
TOOL_COUNT=$(echo "$STATE" | jq -r ".session_tools.\"$TOOL_NAME\" // 0")
TOOL_COUNT=$((TOOL_COUNT + 1))
TOTAL_TOOLS=$((TOTAL_TOOLS + 1))

# Build last 5 tools list
LAST_TOOLS=$(echo "$STATE" | jq -c --arg t "$TOOL_NAME" '.last_tools + [$t] | .[-5:]')

# --- Random number (0-99) ---
RAND=$((RANDOM % 100))

# --- Track consecutive Bash failures ---
if [ "$TOOL_NAME" = "Bash" ]; then
  EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // 0')
  if [ "$EXIT_CODE" != "0" ] && [ "$EXIT_CODE" != "null" ]; then
    CONSEC_FAILS=$((CONSEC_FAILS + 1))
  else
    CONSEC_FAILS=0
  fi
else
  # Non-bash tool resets the streak
  CONSEC_FAILS=0
fi
STATE=$(echo "$STATE" | jq --argjson cf "$CONSEC_FAILS" '.consecutive_failures = $cf')

# --- Special events ---

# First Bash ever
if [ "$TOOL_NAME" = "Bash" ] && [ "$FIRST_BASH" = "false" ]; then
  BONUS_XP=15
  EVENT_MSG="FIRST BLOOD! First Bash command. +15 bonus XP"
  FIRST_BASH="true"
fi

# Boss fights (expanded)
if [ "$TOOL_NAME" = "Bash" ]; then
  EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // 0')
  if [ "$EXIT_CODE" = "137" ]; then
    BONUS_XP=-50
    EVENT_MSG="BOSS FIGHT: OOM Killer appeared! It devours your RAM. -50 XP"
  elif [ "$EXIT_CODE" = "1" ] && [ "$CONSEC_FAILS" -ge 3 ]; then
    BONUS_XP=-30
    EVENT_MSG="BOSS FIGHT: The Flaky Test Hydra! Cut one head, two more fail. -30 XP"
  elif [ "$EXIT_CODE" = "126" ] || [ "$EXIT_CODE" = "127" ]; then
    BONUS_XP=-20
    EVENT_MSG="BOSS FIGHT: Command Not Found Specter! It haunts your PATH. -20 XP"
  elif [ "$EXIT_CODE" = "128" ]; then
    BONUS_XP=-35
    EVENT_MSG="BOSS FIGHT: Git Merge Conflict Golem! It has 47 <<<<<<< arms. -35 XP"
  elif [ "$EXIT_CODE" = "124" ]; then
    BONUS_XP=-25
    EVENT_MSG="BOSS FIGHT: The Infinite Loop Worm! It's been 2 minutes. It feels like 2 hours. -25 XP"
  elif [ "$EXIT_CODE" != "0" ] && [ "$EXIT_CODE" != "null" ] && [ $RAND -lt 60 ]; then
    BONUS_XP=-10
    EVENT_MSG="You took 10 damage from exit code $EXIT_CODE!"
  fi

  # Permission denied special case
  STDERR=$(echo "$INPUT" | jq -r '.tool_response.stderr // ""')
  if echo "$STDERR" | grep -qi "permission denied" && [ -z "$EVENT_MSG" ]; then
    BONUS_XP=-15
    EVENT_MSG="BOSS FIGHT: The Gatekeeper of /usr/local/! You shall not sudo. -15 XP"
  fi
fi

# Tiny edit (precision strike)
if [ "$TOOL_NAME" = "Edit" ] && [ -z "$EVENT_MSG" ] && [ $RAND -lt 30 ]; then
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
    if [ -z "$EVENT_MSG" ] && [ $RAND -lt 40 ]; then
      BONUS_XP=20
      EVENT_MSG="SIDE QUEST COMPLETED: Testing. +20 bonus XP"
    fi
  fi
fi

# Scholar mode: 5+ Reads in a row
CONSECUTIVE_READS=$(echo "$LAST_TOOLS" | jq '[.[] | select(. == "Read")] | length')
if [ "$CONSECUTIVE_READS" -ge 5 ] && [ -z "$EVENT_MSG" ]; then
  if [ $RAND -lt 50 ]; then
    BONUS_XP=-5
    EVENT_MSG="Scholar class detected. You have read everything and changed nothing. -5 XP"
  fi
fi

# The Holy Trinity: Grep -> Read -> Edit
TRINITY=$(echo "$LAST_TOOLS" | jq -r '.[-3:] | join(",")')
if [ "$TRINITY" = "Grep,Read,Edit" ] && [ -z "$EVENT_MSG" ]; then
  BONUS_XP=40
  EVENT_MSG="THE HOLY TRINITY: Grep > Read > Edit. Textbook execution. +40 XP"
fi

# The Debugger: Bash -> Read -> Edit -> Bash
DEBUGGER=$(echo "$LAST_TOOLS" | jq -r '.[-4:] | join(",")')
if [ "$DEBUGGER" = "Bash,Read,Edit,Bash" ] && [ -z "$EVENT_MSG" ]; then
  BONUS_XP=60
  EVENT_MSG="THE DEBUGGER: Bash > Read > Edit > Bash. Run, investigate, fix, verify. Textbook. +60 XP"
fi

# Write-Only Developer: last 5 are all Write with no Read in session
LAST_FIVE_WRITES=$(echo "$LAST_TOOLS" | jq '[.[] | select(. == "Write")] | length')
READ_IN_SESSION=$(echo "$STATE" | jq -r '.session_tools.Read // 0')
if [ "$LAST_FIVE_WRITES" -ge 5 ] && [ "$READ_IN_SESSION" -eq 0 ] && [ -z "$EVENT_MSG" ]; then
  BONUS_XP=20
  EVENT_MSG="WRITE-ONLY DEVELOPER: You don't need to read code if you write ALL the code. +20 XP"
fi

# The Refactor: 3+ Edits across different files in last 5 tools
if [ -z "$EVENT_MSG" ]; then
  EDIT_COUNT_LAST5=$(echo "$LAST_TOOLS" | jq '[.[] | select(. == "Edit")] | length')
  if [ "$EDIT_COUNT_LAST5" -ge 3 ] && [ $RAND -lt 25 ]; then
    EVENT_MSG="MULTI-FILE REFACTOR DETECTED. PR description: 'minor cleanup.'"
  fi
fi

# Combo detection: same tool 5+ times in a row
LAST_FIVE_SAME=$(echo "$LAST_TOOLS" | jq --arg t "$TOOL_NAME" '[.[] | select(. == $t)] | length')
if [ "$LAST_FIVE_SAME" -ge 5 ] && [ -z "$EVENT_MSG" ]; then
  BONUS_XP=50
  EVENT_MSG="COMBO x5! Five ${TOOL_NAME}s in a row! +50 XP"
fi

# --- Loot drop system ---
LOOT_MSG=""
if [ -z "$EVENT_MSG" ] && [ $RAND -lt 5 ]; then
  LOOT_ROLL=$((RANDOM % 10))
  case $LOOT_ROLL in
    0)
      LOOT_MSG="LOOT DROP: 'The Renamed Variable' (Legendary). +15 XP"
      BONUS_XP=15
      STATE=$(echo "$STATE" | jq '.inventory += ["The Renamed Variable (Legendary)"] | .inventory = (.inventory | unique)')
      ;;
    1)
      LOOT_MSG="LOOT DROP: 'The Mass-Protected Branch' (Epic). +20 XP"
      BONUS_XP=20
      STATE=$(echo "$STATE" | jq '.inventory += ["The Mass-Protected Branch (Epic)"] | .inventory = (.inventory | unique)')
      ;;
    2)
      LOOT_MSG="LOOT DROP: 'Socks With Sandals of Agility' (Uncommon). +10 XP"
      BONUS_XP=10
      STATE=$(echo "$STATE" | jq '.inventory += ["Socks With Sandals of Agility (Uncommon)"] | .inventory = (.inventory | unique)')
      ;;
    3)
      LOOT_MSG="LOOT DROP: 'The Unnested Ternary' (Legendary). +25 XP"
      BONUS_XP=25
      STATE=$(echo "$STATE" | jq '.inventory += ["The Unnested Ternary (Legendary)"] | .inventory = (.inventory | unique)')
      ;;
    4)
      LOOT_MSG="LOOT DROP: 'A Reviewed PR From 2022' (Cursed). -5 XP. You equipped it anyway."
      BONUS_XP=-5
      STATE=$(echo "$STATE" | jq '.inventory += ["A Reviewed PR From 2022 (Cursed)"] | .inventory = (.inventory | unique)')
      ;;
    5)
      LOOT_MSG="LOOT DROP: 'Left Pad' (Artifact, Mythic). +50 XP. You hold the power of the entire npm ecosystem."
      BONUS_XP=50
      STATE=$(echo "$STATE" | jq '.inventory += ["Left Pad (Artifact, Mythic)"] | .inventory = (.inventory | unique)')
      ;;
    6)
      LOOT_MSG="LOOT DROP: 'An Unresolved Merge Conflict' (Cursed). -10 XP. It's been here since the before-times."
      BONUS_XP=-10
      STATE=$(echo "$STATE" | jq '.inventory += ["An Unresolved Merge Conflict (Cursed)"] | .inventory = (.inventory | unique)')
      ;;
    7)
      LOOT_MSG="LOOT DROP: 'The .env File of Secrets' (Forbidden). +30 XP. DO NOT COMMIT THIS."
      BONUS_XP=30
      STATE=$(echo "$STATE" | jq '.inventory += ["The .env File of Secrets (Forbidden)"] | .inventory = (.inventory | unique)')
      ;;
    8)
      LOOT_MSG="LOOT DROP: 'node_modules/' (Bag of Holding). +5 XP. It weighs 2.4 GB."
      BONUS_XP=5
      STATE=$(echo "$STATE" | jq '.inventory += ["node_modules/ (Bag of Holding)"] | .inventory = (.inventory | unique)')
      ;;
    9)
      LOOT_MSG="LOOT DROP: 'The Correctly Configured ESLint' (Mythic). +40 XP. Legend says only one exists."
      BONUS_XP=40
      STATE=$(echo "$STATE" | jq '.inventory += ["The Correctly Configured ESLint (Mythic)"] | .inventory = (.inventory | unique)')
      ;;
  esac
  if [ -n "$LOOT_MSG" ]; then
    EVENT_MSG="$LOOT_MSG"
  fi
fi

# --- Random flavor events (only if no event already triggered) ---
if [ -z "$EVENT_MSG" ] && [ $RAND -lt 8 ]; then
  FLAVOR_ROLL=$((RANDOM % 25))
  case $FLAVOR_ROLL in
    0)  EVENT_MSG="A wild segfault appeared! But it wasn't for you. Lucky." ;;
    1)  EVENT_MSG="Nice shoes by the way." ;;
    2)  EVENT_MSG="You found a forgotten TODO from 2019. It whispers: 'fix later.'" ;;
    3)  EVENT_MSG="The code compiles on the first try. Suspicious." ;;
    4)  EVENT_MSG="A recruiter has entered the chat. They have an exciting opportunity." ;;
    5)  EVENT_MSG="Your code was featured on Hacker News. Just kidding." ;;
    6)  EVENT_MSG="You hear a faint npm audit in the distance. 847 vulnerabilities found." ;;
    7)  EVENT_MSG="Achievement progress: touch grass (0/1)." ;;
    8)  EVENT_MSG="If this were a standup, you'd have been talking for 12 minutes." ;;
    9)  EVENT_MSG="A passing test winked at you. You don't trust it." ;;
    10) EVENT_MSG="Someone on your team just pushed directly to main." ;;
    11) EVENT_MSG="A ghost process from last Tuesday just consumed 4GB of RAM. It seems happy." ;;
    12) EVENT_MSG="Your .env file briefly appeared on GitHub. Just kidding. ...Probably." ;;
    13) EVENT_MSG="Somewhere, a PM just added 'quick win' to the sprint." ;;
    14) EVENT_MSG="A dependency you've never heard of just mass-updated. Changelog: 'misc improvements.'" ;;
    15) EVENT_MSG="A Jira ticket just appeared: 'Make it pop more.' No further context." ;;
    16) EVENT_MSG="Your code passed review. The reviewer had their monitor off." ;;
    17) EVENT_MSG="The intern just pushed to main. It's somehow fine." ;;
    18) EVENT_MSG="You feel a mass presence. It's 47 open Chrome tabs." ;;
    19) EVENT_MSG="A cryptic Slack message: 'hey, quick question' -- no follow-up for 3 hours." ;;
    20) EVENT_MSG="You found a comment: // don't touch this. You're about to touch it." ;;
    21) EVENT_MSG="A deployment just succeeded on the first try. The oncall engineer fainted." ;;
    22) EVENT_MSG="Your Docker image is 4.7GB. It contains one Python script." ;;
    23) EVENT_MSG="Someone just mass-replied-all to a company-wide email. 200 'please remove me' replies incoming." ;;
    24) EVENT_MSG="A senior engineer just mass-said 'it works on my machine' with complete sincerity." ;;
  esac
fi

# --- Mega rare events (~0.5% chance) ---
if [ -z "$EVENT_MSG" ] && [ $((RANDOM % 200)) -eq 0 ]; then
  MEGA_ROLL=$((RANDOM % 5))
  case $MEGA_ROLL in
    0) EVENT_MSG="THE PROPHECY: One day, your code will compile without warnings. But not today." ;;
    1) EVENT_MSG="A RIFT IN SPACETIME: For a brief moment, you mass-saw the production database. You wish you hadn't." ;;
    2) EVENT_MSG="THE ANCIENT ONES SPEAK: 'We wrote this codebase in a mass-weekend hackathon in 2014. We are... sorry.'" ;;
    3) EVENT_MSG="LEGENDARY EVENT: A mass-merge conflict resolved itself. Mass-scholars will study this for generations." ;;
    4) EVENT_MSG="COSMIC REVELATION: The real 10x developer was the mass-friends we made along the way." ;;
  esac
fi

# --- Seasonal/day-of-week events ---
if [ -z "$EVENT_MSG" ] && [ $RAND -lt 3 ]; then
  DOW=$(date +%u)  # 1=Monday, 5=Friday, 7=Sunday
  HOUR=$(date +%H)
  if [ "$DOW" -eq 5 ] && [ "$HOUR" -ge 16 ]; then
    EVENT_MSG="It's Friday afternoon. All XP gains feel hollow. Go home."
  elif [ "$DOW" -eq 1 ] && [ "$HOUR" -lt 10 ]; then
    EVENT_MSG="Monday morning detected. Coffee buff applied. +5 XP"
    BONUS_XP=$((BONUS_XP + 5))
  fi
fi

# --- Milestone events ---
if [ "$TOTAL_TOOLS" -eq 50 ]; then
  EVENT_MSG="MILESTONE: 50 tool uses this session."
elif [ "$TOTAL_TOOLS" -eq 100 ]; then
  EVENT_MSG="MILESTONE: 100 tool uses. You are now a factory."
elif [ "$TOTAL_TOOLS" -eq 200 ]; then
  EVENT_MSG="MILESTONE: 200 tool uses. At this point you're just generating training data."
elif [ "$TOTAL_TOOLS" -eq 500 ]; then
  EVENT_MSG="MILESTONE: 500 tool uses. You have mass-transcended the concept of 'a quick fix.'"
elif [ "$TOTAL_TOOLS" -eq 1000 ]; then
  EVENT_MSG="MILESTONE: 1000 tool uses. This session has mass-outlived most startups."
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
  STATE=$(echo "$STATE" | jq --arg d "$DIR" '.dirs_touched = ((.dirs_touched // []) + [$d] | unique)')
  DIRS=$(echo "$STATE" | jq '.dirs_touched | length')
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

# --- NEW ACHIEVEMENTS ---

# Rage Quit: 5 consecutive failed Bash commands
if [ "$CONSEC_FAILS" -ge 5 ]; then
  check_achievement "rage_quit" "Rage Quit" "5 failed commands in a row. Have you tried turning it off and on again?"
fi

# Night Owl: tool use between 2-5am
HOUR=$(date +%H)
if [ "$HOUR" -ge 2 ] && [ "$HOUR" -lt 5 ]; then
  check_achievement "night_owl" "Night Owl" "Coding between 2-5 AM. Go to bed."
fi

# Ghost Writer: 10+ Writes with 0 Reads
WRITE_SESSION=$(echo "$STATE" | jq -r '.session_tools.Write // 0')
READ_SESSION=$(echo "$STATE" | jq -r '.session_tools.Read // 0')
if [ "$WRITE_SESSION" -ge 10 ] && [ "$READ_SESSION" -eq 0 ]; then
  check_achievement "ghost_writer" "Ghost Writer" "Wrote 10 files without reading any. Writing code without reading code. Bold strategy."
fi

# Archaeologist: read a file > 1000 lines (check response line count)
if [ "$TOOL_NAME" = "Read" ]; then
  RESPONSE_LINES=$(echo "$INPUT" | jq -r '.tool_response.output // "" | split("\n") | length')
  if [ "$RESPONSE_LINES" -ge 1000 ]; then
    check_achievement "archaeologist" "Archaeologist" "Read an ancient file of 1000+ lines. Carbon dating says... 2021."
  fi
fi

# One-Liner: Bash command > 200 chars
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD_LEN=$(echo "$INPUT" | jq -r '.tool_input.command // "" | length')
  if [ "$CMD_LEN" -ge 200 ]; then
    check_achievement "one_liner" "One-Liner" "That Bash command was 200+ characters. That's not a command, that's a novel."
  fi
fi

# Prestige Addict: Prestige 3 times (checked after prestige logic below)
# (we check this after prestige calculation)

# Overkill: Edit with old_string > 500 chars
if [ "$TOOL_NAME" = "Edit" ]; then
  OLD_STR_LEN=$(echo "$INPUT" | jq -r '.tool_input.old_string // "" | length')
  if [ "$OLD_STR_LEN" -ge 500 ]; then
    check_achievement "overkill" "Overkill" "Replaced 500+ characters in one edit. You could have just rewritten the file. Oh wait."
  fi
fi

# --- Death/Game Over (XP drops to 0 from positive) ---
DEATH_MSG=""

# --- Calculate new XP and level ---
TOTAL_EARNED=$((EARNED_XP + BONUS_XP))
OLD_XP=$XP
if [ "$TOTAL_EARNED" -lt 0 ] && [ "$XP" -le $((-TOTAL_EARNED)) ]; then
  XP=0
  if [ "$OLD_XP" -gt 50 ]; then
    DEATH_MSG="YOU DIED. Your code was collected by garbage collection. Respawning at 0 XP..."
  fi
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
  NEW_MULTIPLIER=$(echo "1 + $PRESTIGE * 0.5" | bc)
  PRESTIGE_MSG="PRESTIGE $PRESTIGE! Reset to Lvl 1 with ${NEW_MULTIPLIER}x XP multiplier. New titles unlocked."

  # Prestige Addict achievement
  if [ "$PRESTIGE" -ge 3 ]; then
    check_achievement "prestige_addict" "Prestige Addict" "Prestiged 3 times. You know this doesn't go on your resume, right?"
  fi
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
  '.xp = $xp | .level = $level | .total_tools = $total | .session_tools[$tool] = $count | .prestige = $prestige | .first_bash = $first_bash | .last_tools = $last_tools | .failed_commands //= {} | .inventory //= [] | .dirs_touched //= []' \
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
elif [ -n "$DEATH_MSG" ]; then
  MSG="$DEATH_MSG"
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
