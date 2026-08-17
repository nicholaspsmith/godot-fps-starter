# Godot FPS Starter — Design Spec

**Date:** 2026-08-17 (revised same day after adversarial review)
**Status:** Approved — ready for implementation planning
**Repo:** https://github.com/nicholaspsmith/godot-fps-starter
**Engine target:** Godot 4.7 (develop against 4.7.1), Forward+ renderer, GDScript only

> **Revision note.** v1 of this spec was reviewed adversarially, with claims tested empirically
> against a local Godot install. Five premises were wrong: a stale engine target, a deprecated
> distribution channel, a long-term goal that has been declined upstream since 2021, an internal
> contradiction about whether v1.0 ships art, and an addon install story that was false in four
> demonstrable ways. All are corrected below. Findings marked **[V]** were verified firsthand
> (empirical test or direct source fetch); **[A]** were reported with a cited source but not
> independently confirmed.

---

## 1. Purpose

Unreal ships a first-person template in the box. Godot does not, and the gap is real: a
newcomer who wants to build a shooter in Godot stitches together partial tutorials and ends up
with a monolithic `player.gd` they outgrow within a month.

This project is the thing that should already exist — a starter with genuine gunplay feel, a
real enemy, a complete UI shell, and an architecture that still holds up when the game gets
big. It is free, permissively licensed, and built so that a beginner can read it and a
professional can ship on it.

### Long-term goals

1. **Publish a Template on the Godot Asset Store**, competing on exactly the axes the Godot
   team has publicly said existing templates fail: *maintenance*, and *conformance to the
   official GDScript and project-organization style guides*.
2. **Stay maintained across engine minors** — the single most-cited failing of existing
   templates, and the cheapest way to be the best one available.

**Explicitly not a goal: becoming an "official" Godot starter.** This was v1's stated ambition
and it is aimed at a door that has been closed since 2021. In the canonical proposal
([godot-proposals#3029](https://github.com/godotengine/godot-proposals/issues/3029), still open),
Calinou wrote **[V]**: *"Developing project templates officially is also not a viable option due
to the low amount of people who could dedicate enough time to doing so"* and *"If we officially
promote templates in the project manager, people will expect a high level of polish for all the
templates promoted."* The position is current — a fresh proposal ([#14119](https://github.com/godotengine/godot-proposals/issues/14119),
2026-01-31) was closed into #3029 the next day. In Godot's terminology, "official" is a term of
art meaning *hosted in the Godot GitHub organization* (reduz,
[#8114](https://github.com/godotengine/godot-proposals/issues/8114)) **[V]**.

Note also that Godot's [contribution policy of 2026-06-30](https://godotengine.org/article/contribution-policy-2026/)
states **[V]**: *"No use of AI to generate substantial pieces of code. We require all code to be
human authored,"* and *"No autonomous AI agent use or vibe coding."* This codebase is
AI-authored with human direction and review. That is **no barrier to the Asset Store**, which is
a third-party listing rather than a contribution to Godot's repositories — but it is
disqualifying for in-repo adoption, and it is why goal 1 above is the plan. See §9 for the
disclosure commitment.

### Success criteria

1. A newcomer clones the repo and is playing within two minutes of the editor finishing its
   first import — measured on a mid-range machine, counting the import. (Note: the run shortcut
   is **F5 on Windows/Linux, Cmd+B on macOS** **[V]**; docs must say both.)
2. Adding a hitscan weapon variant (a shotgun, an SMG, a marksman rifle) requires creating one
   `.tres` file and no code changes. A fundamentally new *behavior* — projectiles — requires one
   new fire strategy and still no controller changes.
3. **Measured, not asserted:** before release, three people unfamiliar with the codebase each
   complete "add a shotgun" and "make the enemy notice you faster" from the docs alone, in under
   30 minutes each.
4. Installing the framework into an existing project requires **exactly one manual step** —
   enabling the plugin in Project Settings. Everything else (input actions, audio buses)
   self-bootstraps at runtime and is idempotent. See §4.3; "zero manual steps" is not achievable
   and v1 of this spec was wrong to claim it.
5. All first-party code is MIT and all bundled assets are CC0 or CC-BY with attribution shipped
   in `CREDITS.md`. Bundled third-party dev tooling (GUT) retains its own notice and is not
   required at runtime.

### Explicit non-goals for v1.0

Multiplayer/networking. Save/load of game state (settings persistence is in scope; campaign
saves are not). A level editor or procedural generation. Console export configuration. A weapon
attachment or inventory system. Vehicles. Multiple playable levels.

**Web export is out of scope for v1.0.** Godot 4.7's web target is Compatibility / WebGL 2.0
only — Forward+ and Mobile are unsupported and WebGPU is not implemented
([4.7 export docs](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html)) **[V]**.
The demo commits to Forward+, so a browser build would need a separate degraded render profile.
Recorded as a deliberate v1.1 candidate, not an oversight — a playable browser demo is the
highest-leverage adoption artifact there is.

---

## 2. Prior art and positioning

| Project | License | What it has | Where we differ |
|---|---|---|---|
| **[COGITO](https://github.com/Phazorknight/Cogito)** | MIT | *"Fully-featured Immersive First Person Template Project for Godot 4"* — the **#1 asset on the Godot Asset Store** **[A]** | **The actual incumbent.** Immersive-sim focused (inventory, interaction, systemic objects). We are narrower and deeper: gunplay feel, tested logic, and documentation. |
| [KenneyNL/Starter-Kit-FPS](https://github.com/KenneyNL/Starter-Kit-FPS) | MIT + CC0 | Controller, **weapon switching**, basic enemies | Deliberately minimal — no ADS, recoil, UI shell, perception AI, settings/rebinding, or tests. Note it *does* have weapon switching, which is why §5.2 now ships it. |
| [bukkbeek/GodotFPS-Template](https://github.com/bukkbeek/GodotFPS-Template) | MIT code | Hitscan + projectile; first-class burst mode | We take burst mode and the projectile idea, not the scene-inheritance model. |
| [Jeh3no/Godot-simple-FPS-weapon-system](https://github.com/Jeh3no/Godot-simple-FPS-weapon-system) | MIT | Manager-per-behavior weapon decomposition | Same shape as ours; validates the approach. |
| [ColormaticStudios/quality-godot-first-person](https://github.com/ColormaticStudios/quality-godot-first-person) | MIT | Motion/FOV smoothing, head-bob, in-air momentum | Feel benchmark for the controller. |
| [AxelReviron/Godot-FPS-Template](https://github.com/AxelReviron/Godot-FPS-Template) | MIT | Signal-driven state machine per movement mode | The architectural pattern we adopt. |
| [Liblast](https://codeberg.org/Liblast/Liblast) | **AGPL** | Full multiplayer FPS | **Learn-from-only. Never copy code or assets** — copyleft is incompatible with an MIT starter. |

**Positioning:** *the best-feeling, best-documented, best-maintained FPS foundation on the Asset
Store.* Not "gets you shipping" — §1's non-goals (no saves, no inventory, no campaign) make that
overclaim indefensible, and COGITO already owns the batteries-included end of the market.

---

## 3. Licensing

- **Code — MIT.** Matches the Godot engine's own license; the ecosystem default.
- **Assets — CC0 preferred, CC-BY acceptable.**

The CC0-only rule from v1 of this spec was relaxed deliberately. It was blocking the single
hardest asset to source (§6), and it is stricter than the ecosystem's own bar —
`godot-demo-projects` accepts CC BY and CC BY-SA **[A]**. **Rejected outright:** CC BY-NC,
CC BY-ND, GPL/AGPL, marketplace EULAs (Fab, Unity, Unreal), anything with a
no-redistribution-in-collections clause, and anything of unverified origin.

To keep the attribution burden near zero for downstream users, every CC-BY asset's required
credit line is pre-written into a copy-pasteable block in `CREDITS.md`. Shipping a game built on
this starter means pasting one block, not doing research.

**Provenance is the real defense, not license text.** On user-upload sites (Freesound,
OpenGameArt) the license is self-declared and can be wrong. `ASSETS.md` therefore records, for
every file: source URL, uploader/author, license, and **retrieval date** — that last field is
what matters when a source's terms change underneath you.

This discipline is hard-won: the predecessor project, `backrooms-descent`, cannot contribute any
of its art, because much of it is Fab-EULA (no standalone redistribution) or of unrecorded
origin **[V]**.

---

## 4. Architecture

### 4.1 Repository layout

```
godot-fps-starter/
├── project.godot                  # the demo game project
├── LICENSE                        # MIT — code
├── LICENSE-ASSETS                 # asset licensing policy
├── ASSETS.md                      # per-asset provenance ledger
├── CREDITS.md                     # copy-pasteable attribution block
├── CHANGELOG.md
├── README.md
├── addons/
│   ├── fps_starter/               # THE FRAMEWORK (reusable, distributable alone)
│   │   ├── plugin.cfg / plugin.gd
│   │   ├── player/ weapons/ combat/ ai/ ui/ util/
│   └── gut/                       # dev-only test framework (MIT); safe to delete
├── demo/                          # THE SAMPLE GAME (consumes the framework)
│   ├── levels/  weapons/  enemies/  ui/
├── assets/                        # CC0/CC-BY art + audio, referenced from demo .tres
├── docs/
├── tests/
└── tools/
```

`project.godot` must set `debug/gdscript/warnings/directory_rules` to **Include**
`res://addons/fps_starter`. Verified in the Godot 4.6 source (`modules/gdscript/gdscript.cpp`)
**[V]**: `res://addons` is **excluded from GDScript warnings by default**. Left alone, our
architecture would silently disable the editor's warnings for ~90% of the codebase — untenable
for a project whose standard is production quality, and in direct conflict with the Asset Store
guideline *"fix or suppress all script warnings"* **[V]**.

### 4.2 The framework/demo boundary

**`addons/fps_starter/` may never reference anything under `demo/` or `assets/`.**

**Why** — so the framework can be *distributed and tested independently* of the demo's content.
(v1 of this spec justified this rule by citing `player.gd` reaching 104KB, which is a
non-sequitur: a path boundary does not prevent a god-object. Those are orthogonal failures, and
the second one needs its own rule — see §4.4.)

**Art crosses the boundary through data, not paths.** The framework consumes art via exported
resource slots — `WeaponData.viewmodel_scene`, `EnemyData.model_scene`,
`SurfaceSet.footstep_sounds` — never hardcoded `res://` strings. **Verified working [V]:** a
single `.tres` in `demo/` correctly references an addon script, an addon scene, and an asset at
once. The demo→addon direction is sound and the resource-slot injection design holds.

Consequences: the demo ships real art while the framework stays art-agnostic; swapping art is a
data change with **zero code changes**; and an empty slot degrades to a procedural primitive, so
the addon alone yields a playable grey-box FPS.

**What the boundary does *not* give you.** Path purity is necessary but nowhere near sufficient
for portability. Verified against a fresh 4.6.3 project **[V]**, the framework also carries a
hidden project-global dependency surface: 3D physics layer names are all empty by default,
`AudioServer.bus_count == 1` (so §5.5's Master/Music/SFX buses do not exist), and the default bus
layout resolves to a project-root path definitionally outside the addon. §4.3 and §5.3 handle
these at runtime rather than pretending they don't exist.

### 4.3 Distribution and installation

The Godot **Asset Library was replaced by the Asset Store in May 2026** and is being made
read-only ([announcement](https://godotengine.org/article/introducing-the-godot-asset-store/))
**[V]**. We target the Asset Store, which takes direct uploads with per-version min/max engine
ranges — which conveniently solves the two-paths problem: **publish two listings from one repo**,
a Template archive and an addon-only archive.

Store requirements to design for now, not discover later **[V]**: a 16:9 icon (not the legacy
1:1 128×128), *"remove unnecessary files (.gitignore, .DS_Store, .github folders)"*, *"fix or
suppress all script warnings"*, and *"follow official Godot style guides"*. The store's license
field takes a single value — declare **MIT** and put the asset carve-out in the description's
first line.

**Installation, corrected.** v1 of this spec claimed the EditorPlugin would register input
actions and autoloads on enable, with no manual post-steps. Empirical testing on 4.6.3 found
that false in four ways **[V]**:

1. **Installing does not enable.** The store copies files; the user must then enable the plugin.
   Unavoidable, so §1 criterion 4 now says "exactly one manual step."
2. **`_enable_plugin()` never fires on the clone path.** With the plugin already listed in
   `project.godot`, only `_enter_tree()`/`_exit_tree()` run. The "register on enable" mechanism
   therefore never runs for the *primary* user journey.
3. **Input actions written via `ProjectSettings` don't reach `InputMap` until restart** —
   `set_setting` + `save()` returns OK, but `InputMap.has_action()` is still false that session.
   Worse, `save()` rewrites and normalizes the user's entire `project.godot`, producing unrelated
   VCS churn on every plugin toggle.
4. **"Removes them on disable" is a documented anti-pattern** that destroys user rebinds. The
   predecessor's own vendored `debug_menu` addon, written by a Godot core contributor, says so in
   `_exit_tree()`: *"Don't remove the project setting's value and input map action, as the plugin
   may be re-enabled in the future."*

**The design instead: a runtime, idempotent bootstrap in an autoload** — which is what the
predecessor already did (`scripts/controls.gd`: *"registers the game's Input Map actions in code
so they aren't hand-serialized into project.godot"*) **[V]**. Concretely
`if not InputMap.has_action(a): InputMap.add_action(a)`, and the same shape for audio buses. This
works in exported builds, survives a disabled plugin, and never mutates the user's project.

Tradeoff to state in the docs: runtime-only registration leaves the editor's Input Map panel
empty and confusing, so the demo **also** commits its actions to `project.godot` for
discoverability. Framework code must never hard-depend on an autoload existing (the plugin may be
installed but not enabled) — use a lazy accessor, never a bare `FpsSettings.foo`.

### 4.4 Code style and global naming

GDScript only — no C#. Component-first assembly over inheritance chains.

**Every globally-registered symbol is prefixed.** GDScript has no namespaces; `class_name` is one
global registry, and generic names *will* collide with user code. This is a live ecosystem
problem: GUT v9.6.1 shipped a headline fix *"Renamed internal classes to make clashes with
autoloads and user classes far less likely"* **[V]**. So: `FpsWeaponData`, `FpsHealthComponent`,
`FpsDamageInfo`, `FpsHurtBox`; autoloads `FpsSettings` and `FpsEvents`. CI enforces that every
`class_name` under `addons/fps_starter/` matches `^Fps`.

**No script exceeds ~300 lines**, and the decomposition rules are named per subsystem, because
the predecessor shows where this actually fails **[V]**: `level.gd` 322 KB, `enemy.gd` 118 KB,
`player.gd` 104 KB, `weapon_controller.gd` 18 KB. v1 of this spec set a size target only for the
*smallest* of those. Therefore: enemy behavior decomposes into perception / navigation / states /
combat exactly as weapons do (§5.4), and **level content is authored in scenes, not generated by
a script** — `level.gd` at 322 KB is the real cautionary tale here.

**Documentation is a style rule.** Every `class_name` script carries `##` doc comments, which
feed Godot's built-in class reference (F1) *and* become `@export` tooltips, and support
`@tutorial:` / `@deprecated` / `@experimental` **[V]**. This is the cheapest possible win for the
"teach and ship" standard.

**`@tool` is used surgically, not everywhere.** `_get_configuration_warnings()` only runs for
`@tool` scripts — but making every component `@tool` runs its `_ready`/`_process` inside the
editor, where a beginner's edit can hang the editor. So: components whose configuration can be
*silently* wrong (missing required child, unset resource slot, mismatched physics layer) are
`@tool` and implement the warning, calling `update_configuration_warnings()` from setters, and
every `@tool` script guards runtime logic with `if Engine.is_editor_hint(): return`. Pure-logic
and runtime-only components are not `@tool`.

---

## 5. Systems

### 5.1 Player

`CharacterBody3D` coordinator delegating to a **signal-driven state machine**: `Walk`, `Sprint`,
`Crouch`, `Air` — one small script per state. Yaw on the body, pitch on the camera.

Feel layers as independent, individually-removable sibling nodes: FOV smoothing (sprint/ADS),
curve-driven head-bob suppressed during ADS, coyote-time jump, and material-aware footsteps
resolving a surface type through a `SurfaceSet` resource.

**Four frame-timing and input-fidelity items that separate a smooth Godot FPS from a juddery
one**, none of which v1 of this spec addressed:

- **Stair stepping.** `move_and_slide()` has no built-in step-up/step-down and treats a step as a
  wall; the engine proposal ([#2751](https://github.com/godotengine/godot-proposals/issues/2751))
  is still open **[V]**. A starter whose player can't walk up a 20cm step gets criticized on day
  one. Ships in 1.0.
- **Resolution-independent mouse look.** `InputEventMouseMotion.relative` is in pixels;
  `screen_relative` (4.3+) is not **[V]**. Since §5.5 ships both a resolution setting and a
  sensitivity slider, using `relative` means changing resolution silently changes aim.
- **`Input.set_use_accumulated_input(false)`** — input is accumulated per-frame by default,
  measurably degrading aim response **[V]**.
- **3D physics interpolation**, reworked into SceneTree in Godot 4.5 and **disabled by default**
  **[V]**. Enable and document it.

### 5.2 Weapons

```
Input → WeaponController → FireStrategy → DamageInfo → HurtBox → HealthComponent → signals
```

`WeaponController` is a **thin coordinator (~120 lines target)**: input, fire-rate gating,
semi/auto/burst, the timed-reload state machine, and **weapon switching**. Nothing else.

Off the same fire event, in parallel: `Viewmodel` (animation states, sway, walk-bob, ADS blend),
`Recoil` (camera kick, deterministic pattern + bounded variation, recovery curve), `WeaponAudio`,
`MuzzleFlash`, `ImpactFX`, `ShellCasings`.

**Data model**, ported from `backrooms-descent` where its own audit rated it superior to both MIT
reference templates: `FpsWeaponData` (Resource, immutable stats) + `FpsWeaponState` (RefCounted,
mutable ammo, pure logic, fully unit-tested).

**v1.0 ships two weapons and switching.** Without a second weapon, §1 criterion 2 is
unverifiable — there is nowhere to put the second `.tres` — and we would ship *below* Kenney's
kit, whose `project.godot` has a `weapon_toggle` action bound to E / pad-button-10 / mouse-3
**[V]**. The second weapon may reuse the first's model; the point is that the seam exists and is
exercised.

**Fire strategies** are swappable: `HitscanFire` in v1.0, `ProjectileFire` as a deliberate seam.

**Ported hardened fixes:** the ADS near-plane pull-back gating and the true iron-sights alignment
work. **Not ported: the WAV loop-region full-auto audio hack.** Godot 4.2+ ships
[`AudioStreamPolyphonic`](https://docs.godotengine.org/en/stable/classes/class_audiostreampolyphonic.html)
with `play_stream()`, the modern idiom for stacking gunshots **[V]** — baking a workaround into a
teaching artifact teaches the wrong thing.

### 5.3 Combat components

Three components serve **both** player and enemies:

- `FpsHealthComponent` — max/current, `damage(DamageInfo)`, `heal()`, optional regen after delay,
  signals `health_changed` / `damaged` / `died`.
- `FpsHurtBox` — `Area3D` parented to a bone, carrying a `damage_multiplier` (headshot 2.0×),
  forwarding to its health component. (Named *HurtBox* for the receiver, matching both the cited
  reference implementation and the predecessor's own `HurtBox3D`; v1 of this spec inverted the
  convention.)
- `FpsDamageInfo` — amount, source, position, direction, normal, headshot flag.

**Physics layers are exported, not assumed.** Suggested defaults — 1 world, 2 player, 3 enemy,
4 hurtbox, 5 interactable — are documented and set in the demo's `project.godot`, but the
framework exposes them as `@export_flags_3d_physics` slots with a startup assertion that logs a
clear error on mismatch. A fresh project has **all layer names empty** **[V]**; installing into a
project that already uses layers 1–5 differently would otherwise silently break every baked
`collision_layer` integer in the framework's scenes.

**Hitscan-vs-Area3D is the most common implementation error here, so the resolution is
specified:** raycasts **do not hit areas by default** — `collide_with_areas` must be enabled
**[V]**. Bullet rays mask layer 4 (hurtbox) only, with `collide_with_areas = true` and
`collide_with_bodies = false` for damage resolution, plus a separate layer-1 ray for impact FX
and range. Enemy bodies live on layer 3 and are deliberately not masked by bullet rays, so a body
collider can never occlude its own headshot hurtbox.

### 5.4 Enemy AI

`NavigationAgent3D` plus the same state-machine base: `Idle/Patrol → Investigate → Chase →
Attack → Dead`. Per §4.4, this decomposes into perception / navigation / states / combat as
separate scripts — `enemy.gd` in the predecessor reached 118 KB **[V]** and is the specific
failure being designed against.

`FpsPerceptionComponent` handles **sight** — cone angle + range + LOS raycast, gated by a
*time-to-notice* accumulator so detection ramps rather than snaps, exposed as a signal so HUD and
audio can react. **Hearing is deferred to v1.1** (see §5.9).

`Investigate` walks to the last known position, looks around, then gives up and returns to
patrol. That single behavior is most of what makes an enemy read as thinking rather than as a
homing capsule.

### 5.5 UI, settings, and game flow

- **HUD** — health, ammo, crosshair driven by *actual current spread*, hitmarker (~70ms, distinct
  headshot and kill variants).
- **Menus** — main, pause, settings, **death/results**.
- **Settings** — Video (resolution, fullscreen, vsync, quality preset), Audio (Master/Music/SFX),
  Controls (full rebinding, sensitivity, invert Y, **hold-vs-toggle for ADS / crouch / sprint**),
  Accessibility (camera-shake scale to zero, head-bob toggle, FOV). Persisted to
  `user://settings.cfg`.
- **Audio buses are created at runtime if absent** — a default project has exactly one bus,
  `Master` **[V]**.
- **Gamepad parity**, including menu navigation and **aim assist / bullet magnetism** with a
  user-facing strength setting. The predecessor shipped this (`settings.gd`, `aim_assist := 0.65`)
  and its audit rated it an area where it beat both reference templates **[V]**; claiming
  "parity" while dropping it would be a regression.

Default bindings: WASD, Shift sprint, **Ctrl *and* C** for crouch (the predecessor's
`controls.gd` notes *"'C' as a reliable alt (macOS can be flaky binding bare Ctrl)"* **[V]**),
Space jump, LMB fire, RMB ADS, R reload, E/mouse-3 weapon switch, F interact, Esc pause.

### 5.6 Game feel

- **Recoil** — deterministic per-weapon pattern plus bounded random variation, recovery curve
  returning partway toward center.
- **Camera shake** — trauma-based, squared falloff, multiplied by an accessibility slider that
  reaches zero.
- **Hit feedback** — ~70ms hitmarker; distinct headshot and kill confirms.
- **Impact** — decals plus sparks oriented to the surface normal.

### 5.7 Lighting and rendering

Forward+. `WorldEnvironment` with AgX tonemapping, SSAO, and glow.

**Directional shadows: measured, not assumed.** v1 of this spec called
`SHADOW_PARALLEL_4_SPLITS` *"the correct split count for an FPS"* — it is in fact the engine
**default**, and its own class reference calls it *"the slowest directional shadow mode"* **[V]**.
Indoors the sun contributes little and **positional shadow settings dominate**. So: 2 splits with
a tuned `directional_shadow_max_distance` for the indoor demo, measured; the quality presets move
`positional_shadow/atlas_size` and `soft_shadow_filter_quality`, which are what actually matter
here.

**Two quality presets** (Balanced/High), not three. SDFGI deferred to v1.1. Occlusion culling is
**off** — it defaults to `false`, requires baking `OccluderInstance3D` geometry, and must be
re-baked per level change **[V]**; for one small arena it is likely net-negative.

**Presets cross the boundary by registration, not lookup** (§4.2): the demo's `WorldEnvironment`
registers itself with `FpsSettings` on `_ready()`, and the framework mutates the Environment it
was handed. A missing registration degrades to viewport-only settings.

Performance target: 1080p/60 on mid-range hardware at Balanced.

### 5.8 Sample map

**One level, art-passed, shipping in v1.0** — resolving v1's contradiction between §6 ("ships
real art") and §5.8 ("art pass lands in a later phase"). The CSG blockout is retained at
`demo/levels/blockout/` as the teaching artifact people copy.

Authored to the blockout metrics from the predecessor's research (1.8m player, 2–3m halls, 3–4m
ceilings, 4m walls), demonstrating three named encounter patterns from Hullett & Whitehead —
a **choke point**, a **flanking route**, and a small **arena**.

**Navmesh baking ignores CSG** when `parsed_geometry_type` is Static Colliders
([godot#81027](https://github.com/godotengine/godot/issues/81027)) **[V]** — use Mesh Instances
or Both. This bites the blockout specifically.

### 5.9 Game loop

v1 of this spec had no death, no respawn, and no win condition — you shoot an enemy and nothing
happens, which reads as unfinished to exactly the audience being courted. v1.0 ships:

- Player death → death screen → restart.
- A win condition: clear the encounter → results screen → restart.
- A minimal **interaction and pickup system** (health, ammo) on the already-reserved layer 5.

---

## 6. Assets

**Art direction: coherent stylized low-poly, with photoreal PBR materials.** "Modern" here means
modern *rendering and game feel*, not modern *fidelity* — a distinction that makes the asset
sourcing tractable and the look intentional rather than apologetic.

Budget: 1K textures, VRAM-compressed; Ogg Vorbis over a second, WAV only for short SFX; **whole
repo under ~50 MB**. **No Git LFS** — Asset Store downloads are repo archives and GitHub source
archives don't resolve LFS pointers, so assets would arrive as text stubs **[A]**.

### Allowed sources

| Type | Sources |
|---|---|
| Textures | ambientCG, Poly Haven, [3dtextures.me](https://3dtextures.me/about/), cgbookcase (archive a copy of its license statement — it moved off a standing URL) |
| Models | Kenney, Quaternius, [WRAD ARMS](https://wriks.itch.io/wrad-arms) (CC0 rigged FPS arms) |
| Audio | Freesound (CC0 facet), Kenney, OpenGameArt (CC0 filter) |
| Fonts | Typodermic (~307 CC0 fonts) — note Kenney's own kit ships SIL OFL Lilita One **[V]**; fonts are the likeliest silent license violation, so audit them as their own pass |

ambientCG's license blesses this exact use verbatim **[A]**: *"even in situations that require
them to be redistributed as individual files (for example as part of an open source video game or
tool)."*

### Blocked sources — each advertises as free or CC0 and each fails

| Source | Why |
|---|---|
| **ShareTextures** | *"Custom CC0 … with specific restrictions"* then *"❌ No asset redistribution … as part of collections."* A starter kit is exactly a collection. "Custom CC0" is not CC0. |
| **GameSounds.xyz** | Not an independent library — a Sonniss mirror, inheriting Sonniss's terms |
| **Sonniss GDC bundles** | *"Licensee may not sell any of the sound effects as they come"*; copyright retained by dozens of studios, so no one party could grant an exception |
| **BBC Sound Effects** | RemArc licence — personal/educational/research only |
| **Mixkit** / **ZapSplat** free tier | No redistribution without significant modification / attribution required on the free tier |

**Two Freesound traps for the sourcing doc [A]:** there are **four** licenses, not three — the
retired *Sampling+ 1.0* persists on old accounts — and the "Free Cultural Works" filter admits
**CC-BY or CC0**, so use the literal facet `f=license%3A%22Creative+Commons+0%22`. Downloads
require an account, so a bare `curl` script won't work. On OpenGameArt: preview clips are **not**
covered by the asset license — download the payload, never the preview.

### The viewmodel decision

There is **no well-known CC0 animated first-person viewmodel** with idle/fire/reload/equip/ADS;
Mixamo cannot be relicensed. This is the exact wall that stalled the predecessor, so it is
resolved up front rather than discovered mid-build: **the art licence rule is relaxed to include
CC-BY specifically to unblock this**, with attribution shipped pre-written in `CREDITS.md`.

**This is a hard gate on the implementation plan: source the weapon viewmodel and its animation
set before any weapon code is written.** It is the item most likely to stall this project the way
it stalled the last one.

---

## 7. Testing and CI

**Unit tests** cover the pure-logic layers: ammo math, health and damage multipliers,
state-machine transitions, perception geometry, settings serialization.

**Framework choice — GUT, on familiarity, stated honestly.** GUT leads on stars (2,688 v 1,203)
with a six-year head start; GdUnit4 leads on issue backlog and ships a first-party CI action and
spans 4.5–4.7.1 in one version **[A]**. **No download telemetry exists for either**, so v1's
claim that GUT is "the community standard" asserted an unmeasurable fact. We pick GUT because
more contributors will have seen it — and note the coupling cost: **GUT pins to engine minors**
(v9.7.1 for 4.7.x) **[A]**, so every engine minor forces a test-framework bump.

**Pin `gdtoolkit==4.5.0`.** Latest is 4.5.0 from 2025-10-09 — predating both 4.6 and 4.7 **[V]**
— with five open bugs where `gdformat` emits code Godot refuses to parse, and `gdlint`'s AST
silently skipping `static func` **[A]** — which matters, because the ported `FpsWeaponData` is
built entirely from static factories **[V]**. **`gdlint` is a merge gate; `gdformat --check` is
not.**

**CI checks:**

1. Headless unit tests.
2. Project imports cleanly. `--import` is mandatory on a fresh clone. **Wrap the import step in
   the timeout too** — there is an open bug where `--headless --import` hangs on HDRI import
   ([#116084](https://github.com/godotengine/godot/issues/116084)) **[A]**, and §5.7 ships a sky.
3. `gdlint`, plus the `^Fps` prefix check from §4.4.
4. **Boundary check, uid-aware.** A naive grep is insufficient: `preload("uid://…")` resolves to
   a real asset with **no `res://` substring in the file** — verified **[V]** — and the editor
   setting that emits uid literals on drag-and-drop **defaults to true** **[A]**, meaning the
   normal way people write `preload` defeats the grep. So the check runs in-engine under
   `--headless --editor`: build a `uid → path` map via `ResourceLoader.get_resource_uid()`, walk
   `ResourceLoader.get_dependencies()` for each addon file resolving the *uid* half, and regex
   `uid://[a-z0-9]+` over addon `.gd` sources (scripts return `[]` from `get_dependencies`).
5. **Functional portability test** — the check that can't be gamed: CI builds a fresh scratch
   project containing *only* `addons/fps_starter/`, enables the plugin, and headlessly loads every
   scene and resource. Any load error fails. This doubles as the regression test for §4.2's
   "addon alone yields a playable grey-box FPS" claim.
6. **Every file under `assets/` has a row in `ASSETS.md`** — converting §3's most important rule
   from honor system to enforced.

**`tools/gdtest`** wraps every headless run in a hard timeout — in the predecessor, hung headless
Godot processes orphaned to launchd and burned CPU for two days **[V]**. Port it using `timeout`
rather than `gtimeout`, which GitHub runners don't have.

**Headless CI cannot verify anything visual** — the predecessor's own notes say so: *"Headless
Godot uses the null renderer → blank frames"* **[V]**. Since §9's mitigation for the biggest risk
is a human playtest gate, that gate is a written checklist in `CONTRIBUTING.md` plus a ported
`tools/capture` (real-GPU frame capture), not a promise.

**Commit `*.uid` sidecars; keep `.godot/` ignored.** Godot 4.4+ generates `.uid` files for
scripts and shaders and they must not be gitignored **[A]** — they're what makes check 4
deterministic. The current `.gitignore` is already correct on both counts **[V]**; it gets a
comment saying so, because someone will eventually "clean it up."

---

## 8. Documentation

Trimmed from ten files to five, plus release hygiene.

| File | Purpose |
|---|---|
| `README.md` | Hero GIF, quickstart (F5 / **Cmd+B on macOS**), feature list, license summary |
| `docs/architecture.md` | System map, the boundary rationale, physics layers |
| `docs/adding-a-weapon.md` | The one-`.tres` path, end to end |
| `docs/adding-an-enemy.md` | Components, states, perception tuning |
| `docs/input-and-settings.md` | Action names, rebinding, settings persistence |
| `docs/building-a-level.md` | Blockout metrics, encounter patterns, navmesh setup |
| `ASSETS.md` / `CREDITS.md` | Provenance ledger / copy-pasteable attribution |
| `CHANGELOG.md` | Semver, git tags, and the supported-engine-range policy per release |
| `CONTRIBUTING.md` | Setup, style, PR expectations, the manual playtest checklist |

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| **No CC0 animated FPS viewmodel exists** — the exact blocker that stalled the predecessor | Art licence relaxed to CC-BY (§3). **Hard gate: source the viewmodel + animation set before any weapon code.** |
| Engine minors ship every ~4–5 months and 4.x has no LTS | Target the current minor, float the patch, validate against each beta, and state the supported engine range per release in `CHANGELOG.md` |
| Silent 4.6→4.7 breakages (mouse/keyboard device IDs, typed-return inheritance) | Migrate deliberately; the silent ones need a targeted pass over device-aware input branching |
| Scope creep into a game rather than a starter | §1 non-goals are binding; new features need a version after 1.0 |
| The addon boundary erodes | CI checks 4 and 5 — the second is functional and can't be gamed |
| An asset with unclear provenance slips in | Allowlist/blocklist (§6), retrieval-date ledger (§3), CI check 6 |
| **AI-authorship disclosure** | The Asset Store and `godot-demo-projects` require disclosure of AI usage **[A]**. Disclose proactively in the listing and `CONTRIBUTING.md`; never misrepresent authorship. |
| Feel is subjective and unverifiable in CI | Human playtest gate — a written checklist plus `tools/capture`, not a promise |
| COGITO already occupies the template niche | Differentiate on gunplay feel, tested logic layers, and documentation quality — not on feature count |

---

## 10. Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Engine target | **Godot 4.7 (dev against 4.7.1)** | 4.7 shipped 2026-06-18 with two patches; 4.6 is unpatched for 89 days; no LTS exists |
| Long-term goal | **Asset Store, not official adoption** | Declined upstream since 2021 and reaffirmed 2026-02; "official" means in-repo; AI-authored code is barred there |
| Art licence | **CC0 preferred, CC-BY acceptable** | CC0-only blocked the viewmodel — the project's single hardest asset. Matches `godot-demo-projects`' own bar. Attribution pre-written in `CREDITS.md` |
| Art direction | Stylized low-poly + photoreal PBR materials | Makes sourcing tractable; "modern" = rendering and feel, not fidelity |
| v1.0 scope | Core + feel + UI shell + AI + **switching, death, win, pickups, exports** | A demo with no death and no win state reads as unfinished |
| Cut to v1.1 | SDFGI, occlusion culling, hearing perception, third quality preset, second level version, shell-casing pooling, damage-direction indicator, low-health vignette, web export | Keeps 1.0 shippable |
| Install model | **Runtime idempotent bootstrap**, not plugin-writes-project.godot | Empirically verified: `_enable_plugin()` never fires on the clone path; `InputMap` needs a restart |
| Global naming | `Fps` prefix on every `class_name` and autoload | GDScript has one global registry; GUT shipped a fix for exactly this collision class |
| Test framework | GUT, on familiarity, with the coupling cost stated | No telemetry exists to call either one "the standard" |
| Formatter | `gdtoolkit==4.5.0` pinned; `gdlint` gates, `gdformat` doesn't | Five open bugs emit unparseable code; `gdlint` skips `static func` |
| Architecture | Framework addon + demo in one repo | Dual distribution; verified working; two Asset Store listings from one repo |
| Language / code licence | GDScript only / MIT | Audience reach; Godot's own licence |
