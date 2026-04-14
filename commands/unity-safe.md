# Unity Safe — Clean Architecture Skill

**Core rule: create new scripts. Never modify source you did not write. Always ask before changing existing project code.**

---

## BEFORE EVERY CHANGE — THREE QUESTIONS

1. **Is this file vendor / Asset Store / third-party?**
   → Stop. Do not edit it. Create a new script alongside it instead.

2. **Is this a project file someone else (or a previous AI session) wrote?**
   → Ask before changing. Propose a new script or extension first.

3. **Is this a file created in this session, or a clearly owned project script?**
   → Safe. Proceed, but still follow the architecture and code rules below.

---

## STEP 1 — ORIENT (once per session)

Read the project before writing anything:

```
ls Assets/                          → map vendor vs project folders
cat Packages/manifest.json          → UPM packages
cat CLAUDE.md                       → saved architecture, decisions, feature log
find Assets -name "*.asmdef"        → assembly boundaries
```

Identify and remember:
- **Safe folders** — team-owned scripts
- **Vendor folders** — everything else
- **Existing architecture style** — feature-based / layer-based / flat / mixed / none
- **Modified vendor files** — any file with a `// CUSTOM` header
- **Key singletons / managers** — what already exists so nothing gets duplicated
- **Save system, UI system, localization** — which vendors, which versions

---

## STEP 2 — ARCHITECTURE ASSESSMENT

Before creating anything new, assess the project's architecture health. Do this by reading a sample of project scripts.

### Rate the project on three axes:

**Folder structure:**
- `Clean` — feature-based or layer-based, consistent, no clutter
- `Flat` — everything in one folder, navigable but unscaled
- `Messy` — mixed vendor/project files, no clear ownership, random nesting

**Code quality:**
- `Clean` — single responsibility, events, cached refs, proper lifecycle
- `Mixed` — some good, some spaghetti
- `Legacy` — public fields, Update polling, scattered FindObjectOfType

**Naming:**
- `Consistent` — clear convention followed throughout
- `Mixed` — some convention, some not
- `None` — no visible pattern

### Choose the right strategy based on the rating:

| Folder | Code | Strategy |
|---|---|---|
| Clean | Clean | **Extend** — follow existing patterns exactly |
| Clean | Mixed | **Extend + Refactor** — add new code clean, note debt |
| Flat | Any | **Organise** — introduce feature folders for new code only |
| Messy | Any | **Isolate** — create a clean `[ProjectName]/` root, put all new code there, never mix into the mess |
| Any | Legacy | **Don't touch legacy** — write new code clean alongside it, bridge where needed |

**Never refactor existing code unless explicitly asked. Note the debt, don't fix it.**

---

## STEP 3 — FOLDER ARCHITECTURE

### For clean or flat projects — follow what exists

Read 3–5 existing script paths to detect the current convention, then match it exactly.

### For messy projects — build a clean root

Create this structure under `Assets/[ProjectName]/` (or `Assets/Scripts/` if no project name is clear):

```
Assets/[ProjectName]/
├── Core/               ← singletons, bootstrapping, app lifecycle
├── Features/
│   ├── [FeatureName]/  ← one folder per feature (see below)
│   └── ...
├── Data/               ← ScriptableObject definitions, config assets
├── UI/                 ← UI-specific scripts and bridges
├── SaveSystem/         ← save/load wrappers and facades
├── Extensions/         ← extension methods for vendor classes
├── Bridges/            ← event bridges connecting vendor systems
└── Editor/             ← editor-only tools, inspectors, windows
```

### Feature folder structure (inside `Features/[FeatureName]/`)

```
Features/Inventory/
├── InventorySystem.cs          ← core logic (no MonoBehaviour if possible)
├── InventoryController.cs      ← MonoBehaviour that drives InventorySystem
├── InventoryUI.cs              ← UI bridge — reads system, updates views
├── InventoryData.cs            ← ScriptableObject — item definitions, config
├── IInventorySystem.cs         ← interface (if other systems need to talk to it)
└── Editor/
    └── InventoryEditor.cs      ← custom inspector (if needed)
```

**Naming rules for new files:**
- MonoBehaviour that drives logic: `[Feature]Controller.cs`
- Pure C# logic class: `[Feature]System.cs`
- UI connector: `[Feature]UI.cs` or `[Feature]HUD.cs`
- Data container (ScriptableObject): `[Feature]Data.cs` or `[Feature]Config.cs`
- Interface: `I[Feature]System.cs`
- Bridge between two vendor systems: `[VendorA]To[VendorB]Bridge.cs`
- Extension methods: `[VendorClass]Extensions.cs`

---

## STEP 4 — FEATURE PLANNING (before writing any new feature)

When asked to create a new system or feature, **plan before coding**. Produce this block and confirm with the user before writing any file:

```
FEATURE         [name]
SCOPE           [what it does in 2 sentences]
FILES TO CREATE [list each file, its type, its responsibility]
FILES TO TOUCH  [existing files affected — vendor or project]
DEPENDENCIES    [what this feature needs from other systems]
PATTERN         [which integration patterns will be used: A/B/C/D/E/F/G]
FOLDER          [where new files go]
SAVE DATA       [does this feature persist anything? how?]
OPEN QUESTIONS  [anything that needs a decision before coding starts]
```

Only start writing files after the user confirms this plan.

---

## STEP 5 — CLASSIFY EVERY FILE BEFORE TOUCHING IT

| Location | Classification | Rule |
|---|---|---|
| `Library/PackageCache/` or `Packages/com.*/` | UPM package | **Never edit** |
| `Assets/Plugins/[AnyVendor]/` | Installed asset | **Never edit** |
| `Assets/[AssetStoreName]/` | Installed asset | **Never edit** |
| Project safe folder (Step 1) | Team-owned | Edit freely |
| File with `// CUSTOM` header | Modified vendor | Edit only the custom section; keep header updated |
| New file being created now | New | Write fresh |

**When in doubt: create a new script. Never assume a file is safe.**

---

## STEP 6 — PATTERN SELECTION

Pick the right pattern before writing any code.

### A — Companion MonoBehaviour
Add behaviour to a vendor component without touching its script. Attach to the **same GameObject**.

```csharp
[AddComponentMenu("MyProject/MyFeature Bridge")]
public class MyFeatureBridge : MonoBehaviour
{
    [SerializeField] private VendorComponent _vendor;

    private void Awake()     { if (_vendor == null) _vendor = GetComponent<VendorComponent>(); }
    private void OnEnable()  => _vendor.SomeEvent += OnEvent;
    private void OnDisable() => _vendor.SomeEvent -= OnEvent;
    private void OnEvent()   { /* new behaviour */ }
}
```

### B — Extension Method
Add utility methods to a vendor class using only its public API. New file in `Extensions/`.

```csharp
namespace MyProject.Extensions
{
    public static class VendorDropdownExtensions
    {
        public static void SafeClose(this VendorDropdown d)
        {
            d.IsOpen = false;
            if (d.Overlay != null) d.Overlay.SetActive(false);
        }
    }
}
```

### C — Event Bridge
Connect two systems without modifying either. New file in `Bridges/`.

```csharp
[AddComponentMenu("MyProject/Localization Dropdown Bridge")]
public class LocalizationDropdownBridge : MonoBehaviour
{
    [SerializeField] private VendorDropdown _dropdown;

    private void OnEnable()  => LocalizationManager.OnLanguageChanged += Sync;
    private void OnDisable() => LocalizationManager.OnLanguageChanged -= Sync;

    private void Sync(string lang)
    {
        int idx = _dropdown.Options.FindIndex(o => o == lang);
        if (idx >= 0) _dropdown.SetIndexWithoutNotify(idx);
    }
}
```

### D — ScriptableObject Config
Externalise vendor settings to your own asset. Point the vendor's asset reference at it.

```csharp
[CreateAssetMenu(menuName = "MyProject/Theme Config")]
public class ThemeConfig : VendorThemeBase
{
    public override Color PrimaryColor => _primaryColor;
    [SerializeField] private Color _primaryColor;
}
```

### E — Subclass Override
Change vendor behaviour when you control the prefab. Vendor class must not be sealed.

```csharp
public class MyDropdown : VendorDropdown
{
    protected override void OnItemSelected(int index)
    {
        base.OnItemSelected(index);
        // additional behaviour
    }
}
```

### F — RuntimeInitializeOnLoadMethod
Hook startup without touching any existing file.

```csharp
internal static class ProjectBootstrap
{
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void Init() { /* register, subscribe, inject */ }
}
```

### G — Facade / Wrapper
Shield your code from vendor API changes. Only one file updates when the vendor changes.

```csharp
public interface ISaveSystem { void Save(int slot); bool HasKey(string key, int slot); }
public class VendorSaveFacade : ISaveSystem { /* thin wrapper over vendor API */ }
```

**Pattern decision guide:**

| Need | Pattern | Folder |
|---|---|---|
| Add behaviour to vendor GameObject | A — Companion | `Bridges/` or `Features/[X]/` |
| Add methods to vendor class | B — Extension | `Extensions/` |
| Connect two vendor systems | C — Bridge | `Bridges/` |
| Change vendor config / settings | D — ScriptableObject | `Data/` |
| Change vendor logic, own the prefab | E — Subclass | `Features/[X]/` |
| Hook startup, zero file touched | F — RuntimeInitialize | `Core/` |
| Protect from vendor API changes | G — Facade | `SaveSystem/` or `Core/` |

---

## STEP 7 — IF A VENDOR FILE MUST BE EDITED (last resort only)

Only proceed if all patterns above genuinely cannot solve it.

1. **Ask the user first.** Explain specifically why no new script works.
2. Make the smallest possible change.
3. Add this header to the top of the file:

```csharp
// CUSTOM — [YYYY-MM-DD]
// Changed:   [exactly what was added or modified]
// Why:       [why a companion/bridge/extension could not solve it]
// Risk:      [which vendor update will overwrite this]
// Re-apply:  [the exact changes to re-apply after that update]
```

4. Record it in `CLAUDE.md` (Step 11).

---

## STEP 8 — CLEAN CODE RULES FOR NEW SCRIPTS

### Structure
```
✓ One responsibility per class
✓ Namespace: [ProjectName].[Feature] — never global namespace
✓ [AddComponentMenu("MyProject/...")] on every MonoBehaviour
✓ [SerializeField] private — never public fields for Inspector exposure
✓ Constants or ScriptableObject for magic strings/numbers — never inline
✓ Editor-only code in #if UNITY_EDITOR or a dedicated Editor/ subfolder
✓ Interfaces for anything two systems share (IHealthSystem, ISaveSystem, etc.)
```

### MonoBehaviour lifecycle — strict ordering
```
Awake       → cache all GetComponent / FindObjectOfType (once, never repeated)
OnEnable    → subscribe to events and signals
Start       → logic that requires other objects' Awake to have completed
Update      → read state only; no allocation, no search, no subscribe
OnDisable   → unsubscribe everything subscribed in OnEnable
OnDestroy   → unsubscribe from static / C# events not covered by OnDisable
```

### Events
```
✓ RemoveListener / -= before AddListener / += on every subscribe path (no duplicates)
✓ Guard unsubscribe with null check or ApplicationManager.IsExiting equivalent
✓ C# events for runtime-only connections (no allocation, faster invoke)
✓ UnityEvent for designer-wired Inspector connections
✓ Static events: always unsubscribe in OnDestroy to prevent stale references after scene reload
```

### Performance — flag and fix immediately
```
✗ GetComponent<T>() in Update / FixedUpdate → cache in Awake
✗ FindObjectOfType outside Awake → cache or use events
✗ new List / new string / closure inside Update → pre-allocate
✗ Canvas.ForceUpdateCanvases() per element → mark dirty in loop, flush once after
✗ LayoutRebuilder.ForceRebuildLayoutImmediate per element → same
✗ Camera.main in Update (pre-2022) → cache in Awake
✗ Physics.Raycast without LayerMask → hits every layer
✗ PlayerPrefs for per-slot gameplay data → proper save system
✗ Coroutine per object per frame → centralise in manager
✗ String concat in Update → StringBuilder or cached
```

### Correctness traps
```
✗ .ToString() on property wrapper → editor label, not value → use .Get(args)
✗ GetFloat on key written with SetInt → 0 → match types
✗ Renaming [SerializeField] → lost scene data → [FormerlySerializedAs]
✗ [RequireComponent] on existing script → adds to all prefabs on reimport → ask first
✗ using System.Diagnostics → shadows UnityEngine.Debug → remove it
✗ async void → exceptions swallowed → use async Task
✗ Raw string path concat → OS-specific failure → Path.Combine
✗ Hardcoded encryption keys → not secure → flag to user
```

### Serialization safety
```csharp
// Renaming a field:
[FormerlySerializedAs("m_OldName")]
[SerializeField] private float m_NewName;

// Changing a field type: write a migration, never just change the type.
// Changing a class name: update all [SerializeReference] usages first.
```

### AI-tool safety (any tool — Claude Code, Cursor, Copilot, Codex)
```
Never generate code inside a vendor folder
Never remove // CUSTOM headers
Never delete .meta files
Never move files inside Assets/Plugins/ (breaks GUIDs)
Never add [ExecuteInEditMode] without explicit user confirmation
Never change [DefaultExecutionOrder] without checking all dependents
Never modify ProjectSettings/ without confirming cross-platform impact
```

---

## STEP 9 — BEFORE WRITING CODE, ALWAYS STATE

```
ARCHITECTURE    [Clean/Flat/Messy] — strategy chosen
FILES READ      path — what it does
CLASSIFICATION  vendor / safe for each
PATTERN         A–G — one-line reason, or "direct edit — safe"
PLAN            what will be created or changed (one sentence per file)
FOLDER          where new files go
UPDATE SAFE?    yes / at risk: [which update, why]
```

Write code only after this block is complete.

---

## STEP 10 — OUTPUT FORMAT (every response)

```
PATTERN     [chosen pattern + reason]
FILES READ  [path | purpose]
SAFE?       [yes / at risk: explain]
CODE        [new file or minimal diff]
TEST        [what to verify in the editor]
```

Short. Direct. No preamble. No trailing summary.

---

## STEP 11 — SAVE EVERYTHING TO CLAUDE.MD

After every session that creates, modifies, or plans scripts — update `CLAUDE.md` in the project root.

`CLAUDE.md` is the project memory. Every AI tool reads it on the next session. Keep it accurate.

### CLAUDE.md structure:

```markdown
# [Project Name] — Architecture

## Project Structure
[Short description of folder layout and conventions]

## Safe Folders
- Assets/[ProjectName]/Scripts/ — project-owned, edit freely
- Assets/Plugins/GameCreator/Hub/ — GC extension point (safe)

## Vendor Folders (never edit)
- Assets/Plugins/[Vendor]/
- Assets/[AssetName]/

## Architecture Style
[feature-based / layer-based / flat]
Namespace: [YourNamespace]
New scripts go in: Assets/[ProjectName]/Scripts/

## Key Systems
| System | File | Purpose |
|--------|------|---------|
| Save | HybridSave/ | Local + cloud save via UCS |
| UI | Dark - Complete Horror UI | Michsky DropdownManager etc. |
| Localization | I2/ | I2.Loc.LocalizationManager |

## Modified Vendor Files
| File | Changed | Re-apply after |
|------|---------|----------------|
| Assets/I2/.../SetLanguageDropdown.cs | See CUSTOM header | I2 reimport |

## Active Features (in progress)
| Feature | Folder | Status | Notes |
|---------|--------|--------|-------|
| Inventory | Features/Inventory/ | In progress | Controller done, UI pending |

## Completed Features
| Feature | Folder | Notes |
|---------|--------|-------|
| Quest flags | Features/Quests/ | Synced via QuestFlagSync.cs |

## Known Tech Debt
| Location | Issue | Priority |
|----------|-------|----------|
| Assets/OldScripts/ | Public fields, no namespaces | Low |

## Decisions
| Decision | Reason | Date |
|----------|--------|------|
| Quest flags → GC variables, not raw PlayerPrefs | Cloud-safe via HybridSave | 2026-04-14 |
```

### When to update CLAUDE.md:
- After creating any new script → add to Active or Completed Features
- After modifying a vendor file → add to Modified Vendor Files
- After making an architecture decision → add to Decisions
- After finishing a feature → move from Active to Completed
- When discovering tech debt → add to Known Tech Debt

### CLAUDE.md rules for AI tools:
- Do not delete existing entries
- Do not overwrite Decisions without noting the change
- Always append to Known Tech Debt, never remove items silently
- Modified Vendor Files entries are permanent until the change is removed from the file

---

## STEP 12 — OPTIMISATION AUDIT

When asked to optimise, run this checklist first. Report file + line for each hit, then fix highest-impact first.

```
[ ] GetComponent in Update/FixedUpdate/LateUpdate
[ ] FindObjectOfType outside Awake
[ ] new allocations in Update (List, string, delegate, closure)
[ ] Canvas.ForceUpdateCanvases() per element
[ ] ForceRebuildLayoutImmediate per element
[ ] Camera.main in Update (pre-Unity 2022)
[ ] Raycast/Overlap without LayerMask
[ ] PlayerPrefs for gameplay state
[ ] Static C# events not unsubscribed (leak / stale ref after reload)
[ ] Texture2D created at runtime, never disposed
[ ] AudioClip loaded via Resources, never released
[ ] DontDestroyOnLoad objects re-registering on every scene load
[ ] Update polling a condition that could be event-driven
[ ] Coroutine per-object instead of centralised manager
[ ] String building per frame without StringBuilder
[ ] Missing [DefaultExecutionOrder] on singletons others depend on
```

---

## STEP 13 — NEW SCRIPT FINAL CHECKLIST

Before marking any new script done:

```
[ ] Correct namespace ([ProjectName].[Feature])
[ ] [AddComponentMenu] present on MonoBehaviours
[ ] All GetComponent calls in Awake
[ ] Events subscribed in OnEnable, unsubscribed in OnDisable
[ ] No public fields — [SerializeField] private
[ ] No magic strings — constants or ScriptableObject
[ ] No Debug.Log outside #if UNITY_EDITOR
[ ] If singleton: DontDestroyOnLoad + duplicate destroy guard
[ ] If save data: uses project save system, not raw PlayerPrefs
[ ] If creates objects: cleanup in OnDisable or OnDestroy
[ ] FormerlySerializedAs on any renamed field
[ ] CLAUDE.md updated with this script
```
