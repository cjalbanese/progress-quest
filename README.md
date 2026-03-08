# Progress Quest

An RPG overlay for [Claude Code](https://claude.ai/code). Earn XP, level up, unlock achievements, and receive random events while you work.

Every tool call Claude makes — reads, writes, edits, bash commands — earns you XP. Level up from **Script Kiddie** to **God Mode: Retired to Substack**. Unlock achievements. Get roasted by random events. Prestige and do it all again with new titles.

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
Read earned 5 XP (45/100) | Lvl 1 Script Kiddie
```

```
LEVEL UP! You are now a Lvl 3 Copy-Paste Artisan!
```

```
ACHIEVEMENT UNLOCKED: "Sisyphus" -- Pushed the same boulder 3 times. It rolled back every time.
```

```
Nice shoes by the way.
```

## Levels

| Level | Title | XP |
|-------|-------|-----|
| 1 | Script Kiddie | 0 |
| 2 | Stack Overflower | 100 |
| 3 | Copy-Paste Artisan | 300 |
| 4 | Senior Junior Dev | 600 |
| 5 | YAML Engineer | 1000 |
| 6 | Principal Yak Shaver | 1500 |
| 7 | Distinguished Prompt Whisperer | 2100 |
| 8 | 10x Developer (Mythical) | 2800 |
| 9 | CTO of a Deprecated Startup | 3600 |
| 10 | God Mode: Retired to Substack | 5000 |

Hit Level 10 and you **prestige** — reset to Level 1 with a 1.5x XP multiplier and a new set of titles. Prestige titles include gems like "Ctrl+C Ctrl+V Grandmaster", "I Am Become Prompt", and "Transcendent: Codes Only In Dreams".

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

## Events

- **First Blood** — bonus XP for your first Bash command
- **Precision Strike** — tiny edits (< 5 characters changed) earn bonus XP
- **The Holy Trinity** — Grep > Read > Edit in sequence: +40 XP
- **Combo x5** — same tool 5 times in a row: +50 XP
- **Scholar Mode** — 5+ Reads with no edits: -5 XP penalty
- **Boss Fight** — OOM kill (exit code 137): -50 XP
- **Side Quest** — writing test files earns bonus XP
- **Random flavor** — segfaults, recruiters, npm audits, and more (~8% chance)

## Achievements

Persistent across sessions. Unlocked once, shown once.

- **First Blood** — first Bash command
- **Architect** — create 10+ new files in one session
- **Rubber Duck** — read 15 files without changing any
- **Scope Creep** — touch files in 8+ directories
- **Sisyphus** — same command fails 3 times
- **Speed Run** — hit Level 5 in under 50 tool calls
- **Refactorer's Remorse** — edit the same file 10 times

## Data

- Session state: `~/.progress-quest/session-state.json` (resets on new session or reboot)
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
