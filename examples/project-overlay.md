# Unity Workflow — [Your Project Name]

Loads the `/unity-safe` protocol with this project's context pre-filled.
No re-scanning needed — use the facts below directly.

---

## FOLDER MAP

| Folder | Classification | Notes |
|--------|---------------|-------|
| `Assets/[ProjectName]/Scripts/` | **Safe** | Primary project code |
| `Assets/Plugins/[VendorA]/` | **Vendor — never edit** | e.g. save system, UI kit |
| `Assets/Plugins/[VendorB]/` | **Vendor — never edit** | |
| `Assets/[AssetStoreName]/` | **Vendor — never edit** | |

## TECH STACK

- Unity version: [e.g. 2022.3 LTS]
- Render pipeline: [URP / HDRP / Built-in]
- Save system: [describe briefly — PlayerPrefs / file / cloud]
- UI system: [UGUI / UI Toolkit / third-party name]
- Localization: [none / I2 / Unity Localization / other]
- Scripting backend: [Mono / IL2CPP]
- Version control: [Git / PlasticSCM / Perforce]
- New script namespace: `[YourNamespace]`
- New script location: `Assets/[ProjectName]/Scripts/`

## MODIFIED VENDOR FILES

Files already intentionally edited. Re-apply changes after the listed update.

| File | Changed | Re-apply after |
|------|---------|----------------|
| _(none)_ | | |

## KEY EXISTING SCRIPTS

Scripts that already exist — check these before creating something new.

| Script | Path | Does |
|--------|------|------|
| | | |

## PROJECT CONVENTIONS

<!-- Examples:
- All scene transitions go through SceneLoader.cs — never call SceneManager directly
- Audio played through AudioManager.Play() — never AudioSource.PlayClipAtPoint
- Quest flags stored in QuestData ScriptableObject, not PlayerPrefs
- Singletons use SingletonBase<T> from Assets/[Project]/Scripts/Core/
-->

## EXTENSION POINTS

<!-- If the project uses a framework with official extension folders, list them:
- GameCreator Hub: Assets/Plugins/GameCreator/Hub/   (safe — updater skips it)
- Custom instructions: Assets/[Project]/Scripts/Instructions/
-->

---

Apply all 9 steps of `/unity-safe` with this context active.
