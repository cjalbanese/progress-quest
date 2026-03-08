# Progress Quest

An RPG overlay for [Claude Code](https://claude.ai/code). Earn XP, level up, fight enemies, collect loot, unlock achievements, and more.

Every tool call Claude makes — reads, writes, edits, bash commands — earns you XP. Level up from **Just a Baby** to **God Mode: Retired to Substack**. Unlock a tool-specific class. Fight named enemies. Collect loot drops. Meet NPCs. Get roasted by git-aware events. Prestige and do it all again with new titles (up to 5 unique prestige tiers).

## Install

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/cjalbanese/progress-quest/main/install.sh | bash
```

### As a Claude Code plugin

```bash
claude plugin install /path/to/progress-quest
```

### Requirements

- [Claude Code](https://claude.ai/code) CLI
- [jq](https://jqlang.github.io/jq/) (`brew install jq` / `apt install jq`)

## What you'll see

Most tool calls show nothing (scarcity keeps it fun). But sometimes:

```
Read earned 5 XP (45/100) | Lvl 1 Just a Baby [Read Monk]
```

```
  _     _______     _______ _       _   _ ____  _
 | |   | ____\ \   / / ____| |     | | | |  _ \| |
 | |   |  _|  \ \ / /|  _| | |     | | | | |_) | |
 | |___| |___  \ V / | |___| |___  | |_| |  __/|_|
 |_____|_____|  \_/  |_____|_____|   \___/|_|   (_)
LEVEL UP! You are now a Lvl 3 Copy-Paste Artisan!
```

```
    /|
   / |
  /  |
 /   |
/    |
\    |
 \   |
  \__|__
   |    |
   |____|
     ||
     ||
     ||
    /__\
ENEMY ENCOUNTER: A Wild Deadlock Demon (Lvl 4) attacks! You take 15 damage! (exit code 1)
```

```
LOOT DROP: 'Left Pad' (Artifact, Mythic). +50 XP. You hold the power of the entire npm ecosystem.
```

```
NPC ENCOUNTER: The CTO drops in. 'What if we rewrote everything in Rust?' Everyone nods. Nothing happens.
```

```
GIT SENSE TINGLING: You have 14 uncommitted changes. The code gods grow restless.
```

## `/quest` — Character Sheet

Check your progress anytime with the `/quest` slash command (when installed as a plugin) or by running:

```bash
bash ~/.claude/hooks/quest-status.sh
```

Shows your level, XP bar, tool class, inventory, achievements, kill count, and session stats.

## Levels

| Level | Title | XP |
|-------|-------|-----|
| 1 | Just a Baby | 0 |
| 2 | Stack Overflower | 100 |
| 3 | Copy-Paste Artisan | 300 |
| 4 | Senior Junior Dev | 600 |
| 5 | YAML Engineer | 1000 |
| 6 | Principal Yak Shaver | 1500 |
| 7 | Distinguished Prompt Whisperer | 2100 |
| 8 | 10x Developer (Mythical) | 2800 |
| 9 | CTO of a Deprecated Startup | 3600 |
| 10 | God Mode: Retired to Substack | 5000 |

Hit Level 10 and you **prestige** — reset to Level 1 with a 1.5x XP multiplier and a new set of titles. There are **5 unique prestige tiers** with increasingly absurd titles, from "Ctrl+C Ctrl+V Grandmaster" to "Has Achieved Sentience, Refuses To Deploy On Friday".

## Tool Classes

Once 50%+ of your tool uses come from a single tool, you earn a class title shown alongside your level:

| Tool | Class |
|------|-------|
| Bash | Bash Barbarian |
| Read | Read Monk |
| Edit | Edit Surgeon |
| Write | Write Necromancer |
| Grep | Grep Oracle |
| Glob | Glob Ranger |
| Agent | Agent Summoner |
| WebFetch | WebFetch Warlock |
| WebSearch | WebSearch Diviner |

## XP per tool

| Tool | XP |
|------|-----|
| Read | 5 |
| Glob | 5 |
| Grep | 10 |
| WebFetch | 10 |
| WebSearch | 10 |
| Edit | 15 |
| Bash | 20 |
| Write | 25 |
| Agent | 30 |

## Enemy Encounters

Failed Bash commands spawn randomized enemies from a bestiary of 15 creatures:

Wild Segfault, Null Pointer Phantom, Race Condition Wraith, Stack Overflow Slime, Deadlock Demon, Memory Leak Ooze, Off-By-One Ogre, Syntax Error Sprite, Dependency Hell Hound, Timezone Troll, Floating Point Phantom, Callback Hell Hydra, Zombie Process, Cache Invalidation Specter, Heisenbug

Each has a random level (1-5) and deals 5-20 damage. Defeat 10 for the **Monster Hunter** achievement; defeat 50 for **Exterminator**.

## Boss Fights

- **OOM Killer** — exit code 137: -50 XP
- **The Flaky Test Hydra** — 3+ consecutive failures: -30 XP
- **Command Not Found Specter** — exit code 126/127: -20 XP
- **Git Merge Conflict Golem** — exit code 128: -35 XP
- **The Infinite Loop Worm** — timeout (exit code 124): -25 XP
- **The Gatekeeper** — permission denied: -15 XP

Boss fights include ASCII art.

## NPC Encounters

~3% chance per tool call. Meet the cast:

- **The Tech Lead** — wants you to "just make it more robust"
- **The Product Manager** — 2 pixels bigger, top priority
- **The Staff Engineer** — distributed systems implications
- **The QA Tester** — have you tested in IE11?
- **The DevOps Engineer** — hollow eyes, Slack buzzing
- **The Scrum Master** — timeboxed to 2 minutes, it's been 47
- **The Intern** — asks a question you can't answer
- **The CTO** — what if we rewrote everything in Rust?
- **The Recruiter** — flee for cardio XP
- **The Security Engineer** — staring at your .env file
- **The Junior Dev** — pushing to main on Fridays?
- **The Designer** — "small changes" to a completely different mockup

## Git-Aware Events

~3% chance. Reads your actual git state:

- Uncommitted changes count ("the code gods grow restless")
- Working on main/master ("living dangerously")
- Last commit age ("you were a different person")
- High commit count repos ("it has seen terrible things")
- Stash count ("they whisper from the shadows")
- Long branch names ("that's not a branch, that's a novella")
- Untracked file count ("they belong to no branch")
- Bad commit messages ("future you will not forgive this")

## Events

- **First Blood** — bonus XP for your first Bash command
- **Precision Strike** — tiny edits (< 5 characters changed) earn bonus XP
- **The Holy Trinity** — Grep > Read > Edit in sequence: +40 XP
- **The Debugger** — Bash > Read > Edit > Bash: +60 XP
- **Combo x5** — same tool 5 times in a row: +50 XP
- **Write-Only Developer** — 5+ consecutive Writes with 0 Reads: +20 XP
- **Multi-File Refactor** — 3+ Edits across files detected
- **Scholar Mode** — 5+ Reads with no edits: -5 XP penalty
- **Side Quest** — writing test files earns bonus XP
- **Random flavor** — 25 possible random events (~8% chance)
- **Mega rare events** — 5 legendary events (~0.5% chance)
- **Seasonal events** — Friday afternoon, Monday morning

## Loot Drops

~5% chance per tool call. Loot is stored in your inventory (visible via `/quest`).

| Item | Rarity | XP |
|------|--------|-----|
| The Renamed Variable | Legendary | +15 |
| The Mass-Protected Branch | Epic | +20 |
| Socks With Sandals of Agility | Uncommon | +10 |
| The Unnested Ternary | Legendary | +25 |
| A Reviewed PR From 2022 | Cursed | -5 |
| Left Pad | Artifact, Mythic | +50 |
| An Unresolved Merge Conflict | Cursed | -10 |
| The .env File of Secrets | Forbidden | +30 |
| node_modules/ | Bag of Holding | +5 |
| The Correctly Configured ESLint | Mythic | +40 |

## Achievements

Persistent across sessions. Unlocked once, shown once.

| Achievement | Trigger | Description |
|-------------|---------|-------------|
| First Blood | First Bash command | "There's no going back." |
| Architect | Create 10+ files in one session | "You're building an empire." |
| Rubber Duck | Read 15 files without changing any | "Impressive restraint." |
| Scope Creep | Touch files in 8+ directories | "The PR review will be legendary." |
| Sisyphus | Same command fails 3 times | "Pushed the same boulder 3 times." |
| Speed Run | Hit Level 5 in under 50 tool calls | "Gotta go fast." |
| Refactorer's Remorse | Edit the same file 10 times | "It's not getting better, is it?" |
| Rage Quit | 5 failed commands in a row | "Have you tried turning it off and on again?" |
| Night Owl | Code between 2-5 AM | "Go to bed." |
| Ghost Writer | Write 10 files without reading any | "Bold strategy." |
| Archaeologist | Read a file of 1000+ lines | "Carbon dating says... 2021." |
| One-Liner | Bash command over 200 characters | "That's not a command, that's a novel." |
| Overkill | Replace 500+ characters in one edit | "You could have just rewritten the file." |
| Prestige Addict | Prestige 3 times | "You know this doesn't go on your resume, right?" |
| Monster Hunter | Defeat 10 enemies | "The bugs fear you now." |
| Exterminator | Defeat 50 enemies | "You don't fix bugs. You hunt them." |

## Sound Effects

Terminal bell (`\a`) plays on level-ups, boss fights, deaths, achievements, loot drops, and prestige events. Sound is on by default. To toggle, edit `~/.progress-quest/session-state.json` and set `"sound": false`.

## Death

If your XP drops to 0 from a boss fight or cursed loot:

```
    _____
   /     \
  | () () |
   \  ^  /
    |||||
    |||||
YOU DIED. Your code was collected by garbage collection. Respawning at 0 XP...
```

## Data

- Session state: `~/.progress-quest/session-state.json` (resets on new session)
- Achievements: `~/.progress-quest/achievements.json` (persistent forever)

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/cjalbanese/progress-quest/main/uninstall.sh | bash
```

To also remove your achievement history:

```bash
rm -rf ~/.progress-quest
```

## License

MIT
