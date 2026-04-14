# unity-safe — Claude Code Skill for Unity

A `/unity-safe` slash command for Claude Code that enforces one rule in every Unity project:

> **Create new scripts. Never modify vendor/asset source files. Always ask before changing existing code.**

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

**Global** (works in every Claude Code session on this machine):
```bash
# macOS / Linux / WSL
./install.sh

# Windows PowerShell
.\install.ps1
```

**Per-project** (only active inside one Unity project):
```bash
# macOS / Linux / WSL
./install.sh /path/to/your/unity/project

# Windows PowerShell
.\install.ps1 -Project "C:\path\to\your\unity\project"
```

The install script:
- Creates the destination folder if it does not exist
- Backs up any existing `unity-safe.md` to `.bak` before overwriting
- Optionally installs the project overlay template (for per-project installs)

### Option 3 — Manual copy

```bash
# macOS / Linux / WSL — global
cp commands/unity-safe.md ~/.claude/commands/unity-safe.md

# Windows PowerShell — global
Copy-Item commands\unity-safe.md "$env:USERPROFILE\.claude\commands\unity-safe.md"
```

### Verify installation

Open any folder in Claude Code and type `/unity-safe`. It should activate immediately.

---

## Usage

```
/unity-safe fix the inventory UI crash
/unity-safe add a new save event listener
/unity-safe the AudioManager allocates every frame — optimise it
/unity-safe I need to hook into the third-party localization system without editing it
/unity-safe audit performance in Assets/Scripts/GameManager.cs
```

---

## What it does

### Before every change — classifies files
Scans `Assets/`, `Packages/manifest.json`, and `.asmdef` files once per session to map vendor folders vs project folders. Every file gets classified before it is touched.

| File location | Rule |
|---|---|
| `Library/PackageCache/`, `Packages/com.*/` | Never edit — UPM managed |
| `Assets/Plugins/[Vendor]/` | Never edit — use companion/bridge |
| `Assets/[AssetStoreName]/` | Never edit — use companion/bridge |
| Your project scripts folder | Edit freely |

### Vendor file? Creates a new script instead

Seven non-invasive patterns — no vendor files modified:

| Pattern | When to use |
|---|---|
| **A — Companion MonoBehaviour** | Add behaviour to a vendor component's GameObject |
| **B — Extension Method** | Add methods using vendor's existing public API |
| **C — Event Bridge** | Connect two vendor systems without touching either |
| **D — ScriptableObject Config** | Externalise vendor settings to your own asset |
| **E — Subclass Override** | Change vendor logic when you control the prefab |
| **F — RuntimeInitializeOnLoadMethod** | Hook startup without editing any file |
| **G — Facade / Wrapper** | Shield project code from vendor API changes |

### Vendor file truly must be edited? Asks first, then documents it

- Explains to you why no new script can solve it
- Makes the smallest possible change
- Adds a `// CUSTOM` header with date, what changed, why, and what to re-apply after update
- Records the file in `CLAUDE.md` so every future AI session knows it is intentionally modified

### Clean architecture rules on every new script
- `GetComponent` cached in `Awake` — never in `Update`
- Events subscribed in `OnEnable`, unsubscribed in `OnDisable`
- `RemoveListener` before `AddListener` (no duplicate subscriptions)
- No allocations inside `Update` (no `new`, no closures, no string concat)
- `[SerializeField] private` — never public fields
- Warns on serialized field renames (`[FormerlySerializedAs]` required)
- Warns on `async void`, `using System.Diagnostics`, raw `Path` concat, hardcoded keys
- No `.meta` deletions, no file moves inside `Plugins/`

### Performance audit (on request)
Reports file + line for every hit, then fixes highest-impact items first:
`GetComponent in Update` · `FindObjectOfType at runtime` · `new allocations in Update` · `Camera.main in Update` · `Canvas.ForceUpdateCanvases per element` · `Raycast without LayerMask` · `PlayerPrefs for gameplay state` · static events not unsubscribed · and more.

---

## Project-specific overlay

The generic `/unity-safe` scans your project on first use. For faster results, create a project overlay that pre-fills your stack so no scanning is needed:

```bash
# Copy the template into your Unity project
cp examples/project-overlay.md /path/to/your/unity/project/.claude/commands/unity.md
```

Edit the file to describe your folders, save system, UI framework, and any already-modified vendor files. Then use `/unity` inside that project instead of `/unity-safe`.

---

## Update

Re-run the same install command. The script backs up the previous version before overwriting.

---

## Uninstall

```bash
# macOS / Linux / WSL — global
rm ~/.claude/commands/unity-safe.md

# Windows PowerShell — global
Remove-Item "$env:USERPROFILE\.claude\commands\unity-safe.md"
```

---

## Files

```
commands/
  unity-safe.md          ← the skill file
examples/
  project-overlay.md     ← template for per-project context overlay
install.sh               ← installer for macOS / Linux / WSL
install.ps1              ← installer for Windows PowerShell
README.md
```

---

## License

MIT
