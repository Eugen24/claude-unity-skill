# unity-safe — Claude Code Skill for Unity

A `/unity-safe` slash command for Claude Code that enforces one rule in every Unity project:

> **Create new scripts. Never modify vendor/asset source files. Always ask before changing existing code.**

Works with any Unity project. Compatible with Claude Code, Cursor, Codex, or any AI coding tool that supports slash commands.

---

## Install

**Global** (works in every Unity project on this machine):
```bash
# macOS / Linux
cp commands/unity-safe.md ~/.claude/commands/unity-safe.md

# Windows (PowerShell)
Copy-Item commands\unity-safe.md "$env:USERPROFILE\.claude\commands\unity-safe.md"
```

**Per-project** (only active in one project):
```bash
mkdir -p YourUnityProject/.claude/commands
cp commands/unity-safe.md YourUnityProject/.claude/commands/unity-safe.md
```

---

## Usage

```
/unity-safe fix the inventory UI crash
/unity-safe add a new save event listener
/unity-safe the AudioManager allocates every frame — fix it
/unity-safe I need to hook into the third-party localization system
```

---

## What it enforces

**Before every change:**
- Scans the project to classify vendor folders vs your own scripts
- Vendor file? Stops. Creates a new companion/bridge/extension instead
- Existing project file? Asks before modifying
- New file? Writes it with clean architecture rules

**Preferred patterns (no vendor files touched):**
| Pattern | When |
|---|---|
| Companion MonoBehaviour | Add behaviour to a vendor component's GameObject |
| Extension Method | Add methods using vendor's public API |
| Event Bridge | Connect two vendor systems without touching either |
| RuntimeInitializeOnLoadMethod | Hook startup without editing any existing file |

**When a vendor file truly must be edited** (last resort):
- Asks the user first and explains why
- Adds a `// CUSTOM — date — what changed — re-apply after which update` header
- Records the file in `CLAUDE.md`

**Clean architecture rules for every new script:**
- `GetComponent` cached in `Awake` — never in `Update`
- Events subscribed in `OnEnable`, unsubscribed in `OnDisable`
- No allocations inside `Update`
- `[SerializeField] private` — not public fields
- No `.meta` file deletions, no file moves inside `Plugins/`
- Warns on serialized field renames (requires `[FormerlySerializedAs]`)

---

## Project-specific overlay

Copy `examples/project-overlay.md` to `.claude/commands/unity.md` in your project and fill in your stack. Then `/unity` loads the generic skill with your project context pre-filled — no re-scanning needed.

---

## Files

```
commands/
  unity-safe.md          ← the skill — copy to ~/.claude/commands/
examples/
  project-overlay.md     ← template for per-project context
README.md
```

---

## License

MIT
