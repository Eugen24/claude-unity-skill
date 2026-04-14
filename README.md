# unity-safe — Claude Code Skill for Unity

A `/unity-safe` slash command for Claude Code that acts as a senior Unity engineer with a strict production workflow:

> **Create new scripts. Never modify vendor/asset source. Always ask before changing existing code. Plan features before building them. Keep CLAUDE.md as project memory.**

Works with any Unity project, any size, any stack.
Compatible with Claude Code, Cursor, Codex, or any AI tool that supports slash commands.

---

## Install

### Option 1 — One-liner (no clone needed)

**macOS / Linux / WSL** — global install:
```bash
mkdir -p ~/.claude/commands && curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/unity-safe-claude-skill/main/commands/unity-safe.md -o ~/.claude/commands/unity-safe.md
```

**Windows PowerShell** — global install:
```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\commands" | Out-Null; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/YOUR_USERNAME/unity-safe-claude-skill/main/commands/unity-safe.md" -OutFile "$env:USERPROFILE\.claude\commands\unity-safe.md"
```

### Option 2 — Install script (after cloning)

```bash
git clone https://github.com/YOUR_USERNAME/unity-safe-claude-skill.git
cd unity-safe-claude-skill
```

**Global** (every Claude Code session on this machine):
```bash
./install.sh                                    # macOS / Linux / WSL
.\install.ps1                                   # Windows PowerShell
```

**Per-project** (only active inside one Unity project):
```bash
./install.sh /path/to/your/unity/project        # macOS / Linux / WSL
.\install.ps1 -Project "C:\path\to\project"     # Windows PowerShell
```

The install script backs up any existing file before overwriting, and offers to install the project overlay template.

### Option 3 — Manual copy

```bash
cp commands/unity-safe.md ~/.claude/commands/unity-safe.md          # macOS / Linux / WSL
Copy-Item commands\unity-safe.md "$env:USERPROFILE\.claude\commands\unity-safe.md"  # Windows
```

### Verify

Open any folder in Claude Code and type `/unity-safe`. It activates immediately.

### Update

Re-run the same install command. Previous file is backed up automatically.

### Uninstall

```bash
rm ~/.claude/commands/unity-safe.md                                  # macOS / Linux / WSL
Remove-Item "$env:USERPROFILE\.claude\commands\unity-safe.md"        # Windows
```

---

## Usage

```
/unity-safe add a quest tracking system
/unity-safe fix the inventory UI crash
/unity-safe I need to hook into the save system without editing vendor files
/unity-safe audit performance in AudioManager.cs
/unity-safe the project structure is messy, help me organise new scripts cleanly
/unity-safe plan a dialogue system before we build it
```

---

## What it does

### 1. Architecture assessment — before writing anything

Reads the project and rates it on three axes: folder structure, code quality, naming consistency.
Then picks the right strategy:

| Project state | Strategy |
|---|---|
| Clean structure, clean code | Extend — follow existing patterns exactly |
| Clean structure, mixed code | Extend + note debt — don't fix what wasn't asked |
| Flat (everything in one folder) | Introduce feature folders for new code only |
| Messy (mixed vendor/project, no pattern) | Create a clean `[ProjectName]/` root — never mix into the mess |
| Legacy code (public fields, polling, no events) | Write new code clean alongside it, bridge where needed |

### 2. Feature planning — before writing any new system

Produces a plan with file list, folder location, dependencies, patterns, and open questions.
Confirms with you before writing a single file.

### 3. Folder architecture for new code

For clean projects: matches existing conventions.
For messy projects: creates a structured root:

```
Assets/[ProjectName]/
├── Core/           ← singletons, bootstrap, app lifecycle
├── Features/
│   └── [Feature]/  ← Controller, System, UI, Data, Interface
├── Data/           ← ScriptableObject definitions and configs
├── UI/             ← UI scripts and bridges
├── Extensions/     ← extension methods for vendor classes
├── Bridges/        ← connectors between vendor systems
└── Editor/         ← editor-only tools
```

### 4. File classification — every file before every touch

Vendor file → stops, creates a new script instead.
Existing project file → asks before changing.
New file → writes clean with full architecture rules.

### 5. Seven non-invasive patterns — no vendor files modified

| Pattern | When |
|---|---|
| A — Companion MonoBehaviour | Add behaviour to a vendor component's GameObject |
| B — Extension Method | Add methods using vendor's public API |
| C — Event Bridge | Connect two vendor systems without touching either |
| D — ScriptableObject Config | Externalise vendor settings to your own asset |
| E — Subclass Override | Change vendor logic when you control the prefab |
| F — RuntimeInitializeOnLoadMethod | Hook startup without editing any file |
| G — Facade / Wrapper | Shield project code from vendor API changes |

### 6. Clean code rules on every new script
- `GetComponent` cached in `Awake` — never in `Update`
- Events subscribed in `OnEnable`, unsubscribed in `OnDisable`
- `[SerializeField] private` — never public fields
- Namespaced per feature — never global namespace
- `[FormerlySerializedAs]` on any renamed field
- No `async void`, no `using System.Diagnostics`, no raw path concat
- No `Debug.Log` outside `#if UNITY_EDITOR`

### 7. CLAUDE.md — project memory that persists across sessions

After every session, updates `CLAUDE.md` with:
- Folder map (safe vs vendor)
- Active and completed features
- Architecture decisions and why they were made
- Modified vendor files (what changed, what to re-apply after update)
- Known tech debt

Every future AI session reads this file and picks up exactly where the last one left off — no re-scanning, no repeated explanations.

### 8. AI-tool safety rules
Applies to Claude Code, Cursor, Copilot, Codex — any tool that touches the project:
- Never generates code inside vendor folders
- Never deletes `.meta` files
- Never removes `// CUSTOM` headers
- Never moves files in `Assets/Plugins/` (breaks GUIDs)
- Never adds `[ExecuteInEditMode]` without explicit confirmation
- Never changes `[DefaultExecutionOrder]` without checking all dependents

### 9. Performance audit (on request)
Reports file + line for every hit. Fixes highest-impact items first.
Covers: `GetComponent` in `Update`, allocations in `Update`, `Canvas.ForceUpdateCanvases` per element, `Camera.main` in `Update`, raycasts without `LayerMask`, static events not unsubscribed, and more.

---

## Project-specific overlay

The generic skill scans your project on first use. For faster results on a specific project, create an overlay that pre-fills your stack:

```bash
cp examples/project-overlay.md /path/to/your/project/.claude/commands/unity.md
```

Edit the file, then use `/unity` inside that project. No scanning needed — goes straight to the task.

---

## Files

```
commands/
  unity-safe.md          ← the skill
examples/
  project-overlay.md     ← per-project context template
install.sh               ← installer for macOS / Linux / WSL
install.ps1              ← installer for Windows PowerShell
README.md
```

---

## Pair with caveman for token efficiency

[caveman](https://github.com/JuliusBrussee/caveman) is a Claude Code skill that strips AI responses down to the minimum — no summaries, no explanations, just the output. Pair it with `/unity-safe` on large sessions to cut token usage significantly.

```
/caveman
/unity-safe add a quest tracking system
```

---

## License

MIT
