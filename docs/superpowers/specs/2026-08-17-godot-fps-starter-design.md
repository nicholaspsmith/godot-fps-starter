# Godot FPS Starter — Design Spec

**Date:** 2026-08-17
**Status:** Approved — ready for implementation planning
**Repo:** https://github.com/nicholaspsmith/godot-fps-starter
**Engine target:** Godot 4.6 (developed against 4.6.3.stable), Forward+ renderer, GDScript only

---

## 1. Purpose

Unreal ships a first-person template in the box. Godot does not, and the gap is real: a
newcomer who wants to build a shooter in Godot stitches together partial tutorials and ends
up with a monolithic `player.gd` they outgrow within a month.

This project is the thing that should already exist — a starter with genuine gunplay feel, a
real enemy, a complete UI shell, and an architecture that still holds up when the game gets
big. It is free, permissively licensed, and built so that a beginner can read it and a
professional can ship on it.

**Long-term goal:** publish to the Godot Asset Library and, if it earns it, propose it to the
Godot team as an official FPS starter — lowering the barrier for developers who want to make
modern shooters in Godot.

### Success criteria

1. A newcomer clones the repo, presses F5, and is playing a good-feeling FPS in under a minute.
2. Adding a hitscan weapon variant (a shotgun, an SMG, a marksman rifle) requires creating one
   `.tres` file and no code changes. A fundamentally new *behavior* — projectiles — requires one
   new fire strategy and still no controller changes.
3. Every system is documented well enough that a beginner can modify it without reading the
   whole codebase.
4. The framework is installable as an addon into an existing project, and the install has no
   manual post-steps.
5. Nothing in the repo carries a license obligation on downstream users beyond retaining the
   MIT notice.

### Explicit non-goals for v1.0

Multiplayer/networking. Save/load of game state (settings persistence is in scope; campaign
saves are not). A level editor or procedural generation. Console export configuration. A
weapon-attachment or inventory system. Vehicles. Multiple playable levels.

---

## 2. Prior art and positioning

| Project | License | What it has | Where we differ |
|---|---|---|---|
| [KenneyNL/Starter-Kit-FPS](https://github.com/KenneyNL/Starter-Kit-FPS) | MIT + CC0 | Godot 4.6; controller, weapon switching, basic enemies | Closest competitor and the bar to clear. It is deliberately minimal — no ADS, no recoil system, no UI shell, no perception AI, no settings/rebinding, no tests. |
| [bukkbeek/GodotFPS-Template](https://github.com/bukkbeek/GodotFPS-Template) | MIT code | Godot 4.6; hitscan + projectile via scene inheritance; first-class burst mode | We take the burst-mode and projectile ideas, not the scene-inheritance model. |
| [Jeh3no/Godot-simple-FPS-weapon-system](https://github.com/Jeh3no/Godot-simple-FPS-weapon-system) | MIT | Manager-per-behavior weapon decomposition | Our decomposition is the same shape; this validates it. |
| [ColormaticStudios/quality-godot-first-person](https://github.com/ColormaticStudios/quality-godot-first-person) | MIT | Motion smoothing, FOV smoothing, head-bob, in-air momentum | Feel benchmark for the controller. |
| [AxelReviron/Godot-FPS-Template](https://github.com/AxelReviron/Godot-FPS-Template) | MIT | Signal-driven state machine per movement mode | The architectural pattern we adopt. |
| [Liblast](https://codeberg.org/Liblast/Liblast) | **AGPL** | Full multiplayer FPS | **Learn-from-only. Never copy code or assets** — copyleft is incompatible with an MIT starter. |

Positioning in one line: **Kenney's kit gets you moving; this gets you shipping.**

---

## 3. Licensing

- **Code — MIT.** Matches the Godot engine's own license, so it is the ecosystem default and
  instantly familiar to reviewers.
- **Assets — CC0 / public domain.** Downstream users owe no attribution for art or audio.

Every third-party asset gets a row in `ASSETS.md` recording source URL, author, and license
*before* it is committed. **CC0 only.** No CC-BY (it would impose an attribution burden on
every downstream user, which is unacceptable for a starter), no Fab/marketplace EULAs (they
forbid redistributing the raw asset files, which is exactly what a public repo does), no
GPL/AGPL, no unverified-origin downloads. Assets provided by the project owner must be
confirmed CC0-compatible and get the same ledger row.

This is a hard-won constraint: the predecessor project, `backrooms-descent`, cannot
contribute any of its art because much of it is Fab-EULA or of unrecorded origin.

---

## 4. Architecture

### 4.1 Repository layout

```
godot-fps-starter/
├── project.godot                  # the demo game project
├── LICENSE                        # MIT — code
├── LICENSE-ASSETS                 # CC0 — art and audio
├── ASSETS.md                      # per-asset provenance ledger
├── README.md
├── addons/
│   ├── fps_starter/               # THE FRAMEWORK (reusable, distributable alone)
│   │   ├── plugin.cfg
│   │   ├── plugin.gd              # EditorPlugin: input actions + autoloads on enable
│   │   ├── player/
│   │   ├── weapons/
│   │   ├── combat/
│   │   ├── ai/
│   │   ├── ui/
│   │   └── util/
│   └── gut/                       # dev-only test framework (MIT); safe to delete
├── demo/                          # THE SAMPLE GAME (consumes the framework)
│   ├── levels/
│   ├── weapons/                   # WeaponData .tres definitions
│   ├── enemies/
│   └── ui/
├── assets/                        # CC0 art + audio, referenced from demo .tres files
├── docs/
├── tests/                         # headless-runnable unit tests
└── tools/                         # gdtest wrapper, CI helper scripts
```

### 4.2 The framework/demo boundary — the load-bearing rule

**`addons/fps_starter/` may never reference anything under `demo/` or `assets/`.**

This is enforced in CI by grepping the addon for `res://demo` and `res://assets`; a match
fails the build. It is not an honor-system convention.

The rule exists because the predecessor project demonstrates what happens without it:
`player.gd` reached 104KB and `weapon_controller.gd` accumulated eight distinct
responsibilities, at which point every change carried regression risk.

**Art crosses the boundary through data, not paths.** The framework consumes art via exported
resource slots — `WeaponData.viewmodel_scene`, `EnemyData.model_scene`,
`SurfaceSet.footstep_sounds` — never through hardcoded `res://` strings. The demo's `.tres`
files fill those slots. Consequences that matter:

- The demo ships real art and looks modern; the framework stays art-agnostic.
- Swapping in different art is a data change with **zero code changes** — which is precisely
  how the owner-supplied assets will land in a later phase.
- An empty slot degrades to a procedurally-built primitive rather than crashing, so the addon
  alone yields a playable grey-box FPS.

### 4.3 Distribution

One repo, two paths:

1. **Clone the whole thing** — you get the demo game as your starting project. This is the
   Asset Library "Templates" path and the primary experience.
2. **Install `addons/fps_starter/` alone** into an existing project. `plugin.gd` registers the
   default input actions and the `Settings` and event-bus autoloads on enable, and removes them
   on disable — so there are no manual post-install steps.

### 4.4 Style

GDScript only — no C#. C# halves the addressable audience, complicates export, and is not the
Godot default. Component-first assembly (small nodes composed in scenes) over inheritance
chains; the predecessor's weapon audit found the data-first composition approach beat both
MIT reference templates on testability.

Per the "teach + ship" decision, every tunable is `@export` with an explicit range and a
tooltip, every script carries a docstring header explaining *why* it exists, and every
component implements `_get_configuration_warnings()` so misconfiguration surfaces in the editor
tree with a suggested fix instead of as a runtime null-reference.

---

## 5. Systems

### 5.1 Player

`CharacterBody3D` coordinator, kept thin, delegating to a **signal-driven state machine**:
`Walk`, `Sprint`, `Crouch`, `Air` — one small script per state, transitions emitted as signals.
Yaw is applied to the body, pitch to the camera on a separate head node.

Feel layers are independent sibling nodes, each individually removable:

- **FOV smoothing** — widens on sprint, narrows on ADS, interpolated rather than snapped.
- **Head-bob** — curve-driven, amplitude scaled per movement state, suppressed during ADS,
  disableable in accessibility settings.
- **Coyote time** on jump.
- **Footsteps** — downward raycast resolves a surface type through a `SurfaceSet` resource and
  plays the matching CC0 sound.

### 5.2 Weapons

The fire pipeline:

```
Input → WeaponController → FireStrategy → DamageInfo → HitBox → HealthComponent → signals
```

`WeaponController` is a **thin coordinator (~120 lines target)**: input handling, fire-rate
gating, semi/auto/burst selection, and the timed-reload state machine. Nothing else. This is a
direct response to the predecessor's `weapon_controller.gd`, which grew to 360 lines doing
eight jobs; the extractions below are the ones its own audit recommended.

Off the same fire event, in parallel and each independently testable: `Viewmodel` (animation
states, sway, walk-bob, ADS blend), `Recoil` (camera kick, deterministic pattern with random
variation, recovery curve), `WeaponAudio`, `MuzzleFlash`, `ImpactFX` (decal + sparks),
`ShellCasings`.

**Data model**, ported from `backrooms-descent` where the audit rated it superior to both
reference templates:

- `WeaponData` — `Resource`, immutable per-weapon stats (damage, RPM, spread, recoil pattern,
  magazine size, reload time, ADS FOV and transform, fire mode, viewmodel scene, audio).
- `WeaponState` — `RefCounted`, mutable ammo over immutable data (`can_fire`, `consume`,
  `reload`, `add_reserve`). Pure logic, no engine coupling, fully unit-tested.

**Fire strategies** are swappable: `HitscanFire` ships in v1.0; `ProjectileFire` is a
deliberate seam so rockets and grenades need no controller changes.

**Specific fixes carried over** from the predecessor, each representing a bug already paid for
once: the WAV loop-region gapless full-auto audio fix, the ADS near-plane pull-back gating,
and the true iron-sights alignment work.

### 5.3 Combat components

Three components serve **both** the player and enemies — that shared use is the test that the
abstraction is real rather than decorative:

- `HealthComponent` — max/current, `damage(DamageInfo)`, `heal()`, optional regen after a
  delay, signals `health_changed` / `damaged` / `died`.
- `HitboxComponent` — `Area3D`, parented to a bone or body part, carries a
  `damage_multiplier` (headshot 2.0×), forwards hits to its `HealthComponent`.
- `DamageInfo` — amount, source, world position, direction, hit normal, headshot flag.

Physics layers are fixed, documented in `docs/physics-layers.md`, and named in
`project.godot`: 1 world, 2 player, 3 enemy, 4 hitbox, 5 interactable.

### 5.4 Enemy AI

`NavigationAgent3D` plus the same state-machine base as the player:
`Idle/Patrol → Investigate → Chase → Attack → Dead`.

`PerceptionComponent` handles:

- **Sight** — cone angle + range + line-of-sight raycast, gated by a *time-to-notice*
  accumulator so detection ramps rather than snapping. Detection level is exposed as a signal
  so the HUD or audio can react to being spotted.
- **Hearing** — gunshots and sprinting emit noise events with a radius through the event bus.

`Investigate` walks to the last known position, looks around, then gives up and returns to
patrol. That single behavior is most of what makes an enemy read as thinking rather than as a
homing capsule, and it is the main thing missing from competing starters.

### 5.5 UI and settings

- **HUD** — health bar, ammo counter, crosshair driven by *actual current spread*, hitmarker
  (~70ms, distinct headshot and kill variants), damage-direction indicator, low-health vignette.
- **Menus** — main, pause, settings.
- **Settings** — Video (resolution, fullscreen, vsync, quality preset), Audio (master/music/SFX
  buses), Controls (full rebinding, mouse sensitivity, invert Y), Accessibility (camera-shake
  scale to zero, head-bob toggle, FOV slider). Persisted to `user://settings.cfg`.
- **Gamepad parity** throughout, including menu navigation.

Default bindings: WASD, Shift sprint, Ctrl crouch, Space jump, LMB fire, RMB ADS, R reload,
Esc pause.

### 5.6 Game feel

The differentiator, specified concretely:

- **Recoil** — hybrid: a deterministic per-weapon pattern plus bounded random variation, with a
  recovery curve returning partway toward center. Learnable but not trivial.
- **Camera shake** — trauma-based with squared falloff, per-event magnitude, multiplied by an
  accessibility slider that reaches zero.
- **Hit feedback** — ~70ms hitmarker; distinct headshot and kill confirms.
- **Impact** — decals plus sparks at the hit point, oriented to the surface normal; pooled
  shell casings.

### 5.7 Lighting and rendering

Forward+. `DirectionalLight3D` on `SHADOW_PARALLEL_4_SPLITS` (the correct split count for an
FPS's near-camera shadow needs). `WorldEnvironment` with AgX tonemapping, SSAO, and glow. SDFGI
is wired but **off by default** — it is Forward+-only and expensive.

Three quality presets (Low/Medium/High) move shadow resolution, SSAO, SDFGI, MSAA, and 3D
render scale together as one setting. Repeated opaque geometry is authored to share one mesh and
one opaque material so Forward+ automatic instancing collapses the draw calls at no
configuration cost; occlusion culling is on.

Performance target: 1080p/60 on mid-range hardware at the Medium preset.

### 5.8 Sample map

One compact combat space, authored to the blockout metrics established in the predecessor's
research (1.8m player, 2–3m hall width, 3–4m ceilings, 4m walls, 10–30cm wall thickness).

It deliberately demonstrates three named encounter patterns from Hullett & Whitehead's
taxonomy — a **choke point**, a **flanking route**, and a small **arena** — so the map teaches
level design rather than merely hosting a shooting range.

Both versions stay in the repo: the CSG blockout (what people copy when starting their own
level) and the art-passed final. The blockout is built first; the art pass lands with the
owner-supplied assets in a later phase.

---

## 6. Assets

The demo ships real art and audio so it looks and sounds modern, held to a strict budget:

- 1K textures, VRAM-compressed.
- Ogg Vorbis for anything longer than a second; WAV only for short SFX needing sample-accurate
  loop points (the full-auto gunshot loop being the specific case).
- **Whole-repo asset footprint under ~50 MB.**

**Phasing.** Implementation proceeds with small CC0 stand-ins so every system is playable and
testable end to end from the start. Owner-supplied assets swap in later purely through the
`.tres` resource slots. No code changes at swap time — this is the whole reason for the
data-slot design in §4.2.

Minimum set: one weapon model with an animation set (idle/fire/reload/equip/ADS), one rigged
enemy with locomotion and attack animations, a small modular environment kit, a PBR texture
set, and an SFX set (gunshot, reload, footsteps per surface, enemy vocalizations, UI clicks).

---

## 7. Testing and CI

**Unit tests** (GUT, MIT, committed under `addons/gut/`, documented as dev-only and safe to
delete) cover the pure-logic layers where tests actually pay: ammo math, health and damage
multipliers, state-machine transitions, perception geometry, and settings serialization. Chosen
over a bespoke runner because contributors already know GUT, and contribution friction is a real
cost for a project whose goal is community adoption.

**`tools/gdtest`** wraps every headless run in a hard timeout. This is not optional ceremony:
in the predecessor project, hung headless Godot processes orphaned to launchd and burned CPU for
two days before anyone noticed.

**CI** (GitHub Actions) runs on every push and PR:

1. Headless unit tests.
2. Project imports cleanly with no errors.
3. `gdlint` over all GDScript.
4. **The boundary check** — grep `addons/fps_starter/` for `res://demo` or `res://assets`; any
   match fails the build.

Check 4 is what keeps §4.2 true once contributors are writing commits.

---

## 8. Documentation

| File | Purpose |
|---|---|
| `README.md` | Hero GIF, one-minute quickstart, feature list, license summary |
| `docs/architecture.md` | System map and the framework/demo boundary rationale |
| `docs/adding-a-weapon.md` | The one-`.tres` path, end to end |
| `docs/adding-an-enemy.md` | Components, states, perception tuning |
| `docs/building-a-level.md` | Blockout metrics, encounter patterns, navmesh setup |
| `docs/input-and-settings.md` | Action names, rebinding, settings persistence |
| `docs/physics-layers.md` | The fixed layer assignments |
| `ASSETS.md` | Per-asset provenance ledger |
| `CONTRIBUTING.md` | Setup, style, PR expectations |
| `CODE_OF_CONDUCT.md` | Table stakes for a project seeking official adoption |

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| Scope creep into a game rather than a starter | The §1 non-goals list is binding; new features need a version after 1.0. |
| The addon boundary erodes | CI check, not convention (§7). |
| Feel is subjective and hard to verify in CI | Human playtest gate before release; benchmark against Colormatic's controller for movement and against real shooters for gunplay. |
| An asset with unclear provenance slips in | CC0-only rule plus a mandatory `ASSETS.md` row before commit. This is the exact failure that makes the predecessor's art unusable here. |
| Reimplementing bugs already fixed once | Port the specific hardened fixes named in §5.2 rather than rewriting those code paths from scratch. |
| Godot 4.7 breaks the project | Pin and document 4.6; revisit after 4.7 stabilizes. |

---

## 10. Decisions made during design

| Decision | Choice | Rationale |
|---|---|---|
| Art assets | CC0-only third-party, plus owner-supplied later | No attribution burden downstream; predecessor's art is unusable due to Fab EULA and unverified origin |
| v1.0 scope | Core + game feel + full UI shell + real enemy AI | Clears Kenney's kit meaningfully; multiple weapon archetypes deferred to v1.1 |
| Audience/code style | Teach **and** ship | Beginner-readable, professional-quality; exports with tooltips, configuration warnings, docs |
| Code reuse | Port the good, rewrite the rest | Keep the `WeaponData`/`WeaponState` split and hardened fixes; rewrite the god-objects |
| Architecture | Framework addon + demo game in one repo | Dual distribution; enforceable boundary; upgrade path for users already building |
| Language | GDScript only | Audience reach and export simplicity |
| License | MIT code + CC0 assets | Godot's own license; zero downstream obligation |
| Repo name | `godot-fps-starter` | Discoverability over branding |
| Test framework | GUT | Community standard lowers contribution friction |
