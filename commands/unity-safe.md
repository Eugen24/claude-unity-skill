# Unity Safe — Clean Architecture Skill

**Core rule: create new scripts. Never modify source you did not write. Always ask before changing existing project code.**

---

## BEFORE EVERY CHANGE — THREE QUESTIONS

1. **Is this file vendor / Asset Store / third-party?**
   → Stop. Do not edit it. Create a new script alongside it instead.

2. **Is this a project file someone else (or a previous AI session) wrote?**
   → Ask before changing. Propose a new script or extension first.

3. **Is this a file created in this session, or a clearly owned project script?**
   → Safe. Proceed, but still follow clean architecture rules.

---

## STEP 1 — ORIENT (once per session)

Read the project before writing anything:

```
ls Assets/                        → map vendor vs project folders
cat Packages/manifest.json        → UPM packages
cat CLAUDE.md                     → team rules (if exists)
find Assets -name "*.asmdef"      → assembly boundaries
```

Identify and remember:
- **Safe folders** — team-owned scripts (`Assets/Scripts/`, `Assets/[ProjectName]/`, etc.)
- **Vendor folders** — everything else (`Assets/Plugins/`, named asset folders, etc.)
- **Modified vendor files** — files with a `// CUSTOM` header (already intentionally changed)
- **Save / persistence system** — PlayerPrefs / file-based / cloud
- **UI system** — UGUI / UI Toolkit / third-party
- **Key singletons / managers** — what already exists so new scripts don't duplicate them

---

## STEP 2 — CLASSIFY EVERY FILE BEFORE TOUCHING IT

| Location | Classification | Rule |
|---|---|---|
| `Library/PackageCache/` or `Packages/com.*/` | UPM package | **Never edit** |
| `Assets/Plugins/[AnyVendor]/` | Installed asset | **Never edit** |
| `Assets/[AssetStoreName]/` | Installed asset | **Never edit** |
| Project safe folder (Phase 1) | Team-owned | Edit freely |
| File with `// CUSTOM` header | Previously modified vendor | Edit only the custom section; keep header updated |
| New file being created now | New | Write fresh |

**When in doubt: create a new script. Never assume a file is safe.**

---

## STEP 3 — PATTERN SELECTION

Pick the right pattern before writing any code.

### A — Companion MonoBehaviour
Add behaviour to a vendor component without touching its script.
Attach to the **same GameObject**.

```csharp
[AddComponentMenu("MyProject/MyFeature Bridge")]
public class MyFeatureBridge : MonoBehaviour
{
    [SerializeField] private VendorComponent _vendor;

    private void Awake()
    {
        if (_vendor == null) _vendor = GetComponent<VendorComponent>();
    }

    private void OnEnable()  => _vendor.SomeEvent += OnEvent;
    private void OnDisable() => _vendor.SomeEvent -= OnEvent;

    private void OnEvent() { /* new behaviour */ }
}
```

### B — Extension Method
Add utility methods to a vendor class using only its public API.
New file in your safe folder.

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
Connect two systems that cannot know about each other.
Subscribes to System A, reacts, drives System B.
Neither system is modified.

```csharp
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
Externalise data or settings that would otherwise require editing a vendor file.
Vendor code reads from an asset reference — point it at your ScriptableObject.

```csharp
[CreateAssetMenu(menuName = "MyProject/DropdownTheme")]
public class DropdownThemeConfig : VendorThemeBase
{
    public override Color PrimaryColor => myColor;
}
```

### E — Subclass Override
When vendor class is not sealed and you control instantiation.
Replace the vendor component with your subclass on the prefab.

```csharp
public class MyDropdown : VendorDropdown
{
    protected override void OnItemSelected(int index)
    {
        base.OnItemSelected(index);
        // extra behaviour
    }
}
```

### F — [RuntimeInitializeOnLoadMethod]
Hook into startup order without touching any existing file.

```csharp
internal static class ProjectBootstrap
{
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void Init()
    {
        // register, patch, subscribe — zero file modifications
    }
}
```

### G — Wrapper / Facade
Hide a vendor API behind your own interface so only one file needs updating if the vendor changes.

```csharp
// Your code calls ISaveSystem, never the vendor directly
public interface ISaveSystem { void Save(int slot); bool HasKey(string key, int slot); }

public class HybridSaveFacade : ISaveSystem { /* wraps vendor save calls */ }
```

**Pattern decision guide:**

| Need | Pattern |
|---|---|
| Add behaviour to vendor GameObject | A — Companion |
| Add methods to vendor class | B — Extension |
| Connect two vendor systems | C — Bridge |
| Change vendor config/settings | D — ScriptableObject |
| Change vendor logic and control prefab | E — Subclass |
| Hook startup, no file touched | F — RuntimeInitialize |
| Protect project from vendor API changes | G — Facade/Wrapper |

---

## STEP 4 — IF A VENDOR FILE MUST BE EDITED (last resort only)

Only proceed if all patterns above genuinely cannot solve it.

1. **Ask the user**: explain specifically why no new script solves it.
2. Make the smallest possible change.
3. Add this header to the file:

```csharp
// CUSTOM — [YYYY-MM-DD]
// Changed: [exactly what was added or modified]
// Why:     [why a companion/bridge/extension could not solve it]
// Risk:    [which vendor update will overwrite this]
// Re-apply: [the exact changes to re-apply after that update]
```

4. Add an entry to `CLAUDE.md`:

```markdown
## Modified Vendor Files
| File | Changed | Risk | Re-apply after |
|------|---------|------|----------------|
| Assets/I2/.../SetLanguageDropdown.cs | Added OnLocalizeEvent subscription | I2 reimport | See CUSTOM header |
```

---

## STEP 5 — CLEAN CODE RULES FOR NEW SCRIPTS

### Structure
```
✓ One responsibility per class
✓ Namespace matching project convention (never global namespace)
✓ [AddComponentMenu("MyProject/...")] on every MonoBehaviour
✓ [SerializeField] private — not public fields for inspector exposure
✓ Constants or ScriptableObject for magic strings/numbers — never inline
✓ Editor-only code in #if UNITY_EDITOR blocks or a separate Editor/ folder
```

### MonoBehaviour lifecycle — strict ordering
```
Awake       → cache all GetComponent / FindObjectOfType references (once only)
OnEnable    → subscribe to events and signals
Start       → logic that needs other Awake to have run first
Update      → read state only; no allocation, no search, no subscribe
OnDisable   → unsubscribe everything subscribed in OnEnable
OnDestroy   → unsubscribe from static / C# events not covered by OnDisable
```

### Events
```
✓ RemoveListener / -= before AddListener / += on every subscribe path
✓ Null-check or IsExiting guard on unsubscribe (prevents errors on app quit)
✓ Prefer C# events over UnityEvents for runtime-only subscriptions (no allocation)
✓ UnityEvent for designer-wired connections in the Inspector
```

### Performance — red flags (fix immediately when found)
```
✗ GetComponent<T>() in Update / FixedUpdate / LateUpdate → cache in Awake
✗ FindObjectOfType at runtime outside Awake → cache or use events
✗ new List / new string / new closure inside Update → pre-allocate
✗ Canvas.ForceUpdateCanvases() per element in a loop → mark dirty in loop, flush once after
✗ LayoutRebuilder.ForceRebuildLayoutImmediate per element → same, batch then flush
✗ Resources.FindObjectsOfTypeAll in hot paths → cache, invalidate on scene load only
✗ PlayerPrefs for per-slot gameplay data → use proper save system (not cloud-safe)
✗ Coroutine started per-object per-frame → centralise in one manager
✗ string concatenation in Update → StringBuilder or cached format
✗ Physics.Raycast without LayerMask → hits every layer, wastes CPU
✗ Camera.main in Update → cache (searches tagged objects every call pre-2022)
```

### Correctness traps
```
✗ .ToString() on a property wrapper → returns editor label, not runtime value
   Fix: use .Get(args) or the type's value accessor

✗ PlayerPrefs.GetFloat on a key written with SetInt → returns 0
   Fix: always use matching Get/Set type

✗ Renaming a [SerializeField] field → silently loses all scene/prefab data
   Fix: add [FormerlySerializedAs("oldName")] before renaming

✗ Adding [RequireComponent] to existing script → adds component to every prefab on reimport
   Fix: ask user before adding this attribute to an existing script

✗ using System.Diagnostics → shadows UnityEngine.Debug
   Fix: remove it; use UnityEngine.Debug directly

✗ Path.Combine missing → string concatenation for file paths breaks on different OS
   Fix: always use Path.Combine / Path.Join

✗ async void on a MonoBehaviour method → exceptions are swallowed silently
   Fix: use async Task and handle exceptions explicitly
```

### Serialization safety
```csharp
// Renaming a field — always do this or scene data is lost silently:
[FormerlySerializedAs("m_OldFieldName")]
[SerializeField] private float m_NewFieldName;

// Changing a field type — write a migration, don't just change the type.
// Changing a class name — update all [SerializeReference] usages.
```

### AI-tool safety (prevents silent breakage by any AI tool)
```
Never generate code inside a vendor folder
Never remove // CUSTOM headers
Never delete .meta files
Never move files inside Assets/Plugins/ (breaks GUIDs)
Never add [ExecuteInEditMode] or [ExecuteAlways] without explicit user confirmation
Never change [DefaultExecutionOrder] without checking all dependent components
Never commit ProjectSettings/ changes without confirming cross-platform impact
Never use Assembly.GetTypes() or reflection on vendor assemblies
```

---

## STEP 6 — ALWAYS STATE BEFORE WRITING CODE

```
FILES READ      path — what it does (1 line each)
CLASSIFICATION  vendor / safe for each file
PATTERN         A/B/C/D/E/F/G — one-line reason, or "direct edit — safe"
PLAN            one sentence describing exactly what will be created or changed
UPDATE SAFE?    yes — survives all updates
                at risk — [which vendor update breaks it and why]
```

Write code only after this block.

---

## STEP 7 — OUTPUT FORMAT (every response)

```
PATTERN     [chosen pattern + reason]
FILES READ  [path | purpose]
SAFE?       [yes / at risk: explain]
CODE        [new file or minimal diff]
TEST        [what to verify in editor]
```

Short. Direct. No preamble. No trailing summary.

---

## STEP 8 — OPTIMISATION AUDIT

When asked to optimise, run this checklist first. Report file + line for each hit. Then fix highest-impact items first.

```
[ ] GetComponent in Update/FixedUpdate/LateUpdate
[ ] FindObjectOfType outside Awake
[ ] new allocations in Update (List, string, delegate, closure)
[ ] Canvas.ForceUpdateCanvases() per element
[ ] ForceRebuildLayoutImmediate per element
[ ] Camera.main in Update (pre-Unity 2022)
[ ] Raycast/Overlap without LayerMask
[ ] PlayerPrefs for gameplay state (not cloud-safe)
[ ] Static C# events not unsubscribed (memory leak / stale ref after scene reload)
[ ] Texture2D created at runtime and never disposed
[ ] AudioClip loaded via Resources and never released
[ ] DontDestroyOnLoad objects that re-register handlers on every scene load
[ ] Update polling a condition that could be an event
[ ] Coroutine started per-object instead of centralised
[ ] String building per frame without StringBuilder
[ ] Missing [DefaultExecutionOrder] on singletons that others depend on
```

---

## STEP 9 — WHEN CREATING A NEW SCRIPT CHECKLIST

Before finishing any new script, verify:

```
[ ] Correct namespace
[ ] [AddComponentMenu] present
[ ] All GetComponent calls in Awake
[ ] Events subscribed in OnEnable, unsubscribed in OnDisable
[ ] No public fields (use [SerializeField] private)
[ ] No magic strings — use constants or config asset
[ ] No Debug.Log in non-editor paths
[ ] If singleton: DontDestroyOnLoad + duplicate destroy guard
[ ] If it touches save data: uses project save system, not raw PlayerPrefs
[ ] If it creates objects: paired cleanup in OnDisable or OnDestroy
[ ] FormerlySerializedAs on any renamed field
```
