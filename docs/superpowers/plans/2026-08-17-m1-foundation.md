# Godot FPS Starter — Milestone 1: Foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the Godot 4.7 project with the framework/demo boundary mechanically enforced by CI, and the runtime bootstrap (input actions, audio buses, settings persistence) working and unit-tested — before there is any gameplay code to erode the architecture.

**Architecture:** A Godot 4.7 project whose reusable framework lives in `addons/fps_starter/` and whose demo game lives in `demo/`. The framework never references `res://demo` or `res://assets`; CI proves it two ways (a uid-aware dependency walk, and a functional test that loads the addon alone in a scratch project). Everything the framework needs from the host project — input actions, audio buses — it creates itself at runtime, idempotently, rather than writing to the user's `project.godot`.

**Tech Stack:** Godot 4.7.1 (GDScript only, Forward+), GUT for unit tests, gdtoolkit 4.5.0 pinned for linting, GitHub Actions for CI.

**Spec:** [`docs/superpowers/specs/2026-08-17-godot-fps-starter-design.md`](../specs/2026-08-17-godot-fps-starter-design.md)

## Global Constraints

Every task's requirements implicitly include this section. Values are copied verbatim from the spec.

- **Engine:** Godot 4.7, developed against **4.7.1**. Forward+ renderer. GDScript only — no C#.
- **Boundary:** `addons/fps_starter/` may never reference anything under `demo/` or `assets/`. (Spec §4.2)
- **Global naming:** every `class_name` under `addons/fps_starter/` is prefixed `Fps`; autoloads are `FpsSettings` and `FpsEvents`. (Spec §4.4)
- **File size:** no script exceeds ~300 lines. (Spec §4.4)
- **Docs:** every `class_name` script carries `##` doc comments — they feed Godot's F1 help and become `@export` tooltips. (Spec §4.4)
- **`@tool` is surgical**, not universal; every `@tool` script guards runtime logic with `if Engine.is_editor_hint(): return`. (Spec §4.4)
- **Licences:** code MIT, assets **CC0 only**. Every file under `assets/` needs a row in `ASSETS.md` with source URL, author, licence, and retrieval date. (Spec §3)
- **Commit `*.uid` sidecars; keep `.godot/` ignored.** (Spec §7)
- **Linting:** `gdtoolkit==4.5.0` pinned. `gdlint` is a merge gate; `gdformat --check` is **not**. (Spec §7)
- **No Git LFS.** (Spec §6)

## Prerequisites (human, before Task 1)

- [ ] Install **Godot 4.7.1** from https://godotengine.org/download/archive/. Keep 4.6.3 installed alongside it — `backrooms-descent` is pinned to 4.6.
- [ ] Export `GODOT` for the shell used to run tasks, e.g.
  `export GODOT="/Applications/Godot4.7.app/Contents/MacOS/Godot"`. Every command below uses `$GODOT`.
- [ ] Verify: `"$GODOT" --version` prints `4.7.1.stable.official.*`.

## A note on engine-version uncertainty

Godot 4.7 postdates parts of the author's knowledge, and several settings below were verified against 4.6.3 rather than 4.7.1. Where that is true, the task contains an explicit **discovery step** that prints the real value before you set it. **Do not skip those steps and do not guess the value** — record what the engine actually reports.

---

### Task 1: Godot 4.7 project scaffold that runs

**Files:**
- Create: `project.godot`
- Create: `demo/main.tscn`
- Create: `demo/levels/blockout/blockout.tscn`
- Create: `icon.svg`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: a runnable project whose main scene is `res://demo/main.tscn`; directory layout `addons/fps_starter/`, `demo/`, `assets/`, `tests/`, `tools/` that every later task depends on.

- [ ] **Step 1: Create the directory skeleton**

```bash
mkdir -p addons/fps_starter/{player,weapons,combat,ai,ui,util} \
         demo/{levels/blockout,weapons,enemies,ui} \
         assets tests/unit tools/ci .github/workflows

# Git does not track empty directories, and CI's asset-ledger check needs
# assets/ to exist. .gitkeep is explicitly skipped by that check.
touch assets/.gitkeep
```

- [ ] **Step 2: Write `icon.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect width="128" height="128" rx="16" fill="#1f2937"/>
  <circle cx="64" cy="64" r="34" fill="none" stroke="#f59e0b" stroke-width="6"/>
  <path d="M64 18v20M64 90v20M18 64h20M90 64h20" stroke="#f59e0b" stroke-width="6" stroke-linecap="round"/>
</svg>
```

- [ ] **Step 3: Write `project.godot`**

Note `config/features` declares 4.7 — this is what makes the editor treat the project as 4.7 rather than offering to convert it. Input actions are committed here **for editor discoverability only**; the framework re-registers them at runtime (Task 3) and never depends on their presence here.

```ini
; Engine configuration file.
; Edited by hand and by the editor. See docs/superpowers/specs/ for the design.

config_version=5

[application]

config/name="Godot FPS Starter"
config/version="0.1.0"
run/main_scene="res://demo/main.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")
config/icon="res://icon.svg"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080

[layer_names]

3d_physics/layer_1="world"
3d_physics/layer_2="player"
3d_physics/layer_3="enemy"
3d_physics/layer_4="hurtbox"
3d_physics/layer_5="interactable"

[rendering]

renderer/rendering_method="forward_plus"
anti_aliasing/quality/msaa_3d=2
textures/default_filters/anisotropic_filtering_level=2
```

- [ ] **Step 4: Create the blockout and main scenes in the editor**

Open the project once so Godot generates `.godot/` and imports the icon:

```bash
"$GODOT" --path . --editor --quit
```

Then create `demo/levels/blockout/blockout.tscn` — a `Node3D` root named `Blockout` containing:
- `CSGBox3D` named `Floor`, size `(20, 0.5, 20)`, position `(0, -0.25, 0)`, **Use Collision on**
- `DirectionalLight3D` named `Sun`, rotation `(-45, -35, 0)`, **Shadow enabled**
- `WorldEnvironment` named `Env` with a new `Environment`: Background mode **Sky**, a new `ProceduralSkyMaterial`, Tonemap mode **AgX**, SSAO **on**

And `demo/main.tscn` — a `Node3D` root named `Main` with the blockout instanced as a child.

> **If you are hand-writing these `.tscn` files** (an agent cannot drive the editor GUI), you must
> supply the uids the editor would have written — verified necessary on 4.7.1, where neither
> `--import` nor a programmatic `ResourceSaver.save()` round-trip assigns one:
>
> 1. Generate ids with `ResourceUID.create_id()` / `ResourceUID.id_to_text()` in a throwaway
>    `SceneTree` script. Never invent uid strings by hand.
> 2. Put `uid="uid://…"` in each `[gd_scene …]` header line.
> 3. Give `main.tscn`'s `ext_resource` **both** `uid=` and `path=` — that is what the editor emits.
>    `uid=` *without* `path=` is a hard parse error; `path=` alone merely loses the identity.
> 4. Run `--headless --import` afterwards, then assert `ResourceUID.has_id()` and
>    `ResourceUID.get_id_path()` resolve for both scenes.
>
> This is load-bearing: **Task 7 Step 3 greps a uid out of `blockout.tscn`** to plant its
> boundary-check violation. With no uid the grep yields an empty string and that check passes
> while testing nothing.

- [ ] **Step 5: Verify the project runs**

```bash
"$GODOT" --path . demo/main.tscn --quit-after 120
```

Expected: a window opens showing a lit grey platform against a sky, then closes. No errors on stdout.

- [ ] **Step 6: Update `.gitignore` with the rationale comment**

```gitignore
# Godot 4+ specific ignores
.godot/
/android/

# NOTE: do NOT ignore *.uid files. Godot 4.4+ generates them for scripts and
# shaders, they are the stable identity of each file across renames, and the CI
# boundary check in tools/ci/check_boundary.gd resolves uid:// references
# through them. Ignoring them breaks that check silently.

# macOS
.DS_Store

# Godot export output
/build/
*.tmp

# Editor / tooling
.idea/
.vscode/
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: Godot 4.7 project scaffold with runnable blockout scene"
```

---

### Task 2: GUT and the timeout-wrapped test runner

**Files:**
- Create: `addons/gut/` (vendored, via download)
- Create: `tools/gdtest`
- Modify: `project.godot` (GUT's editor plugin entry)

**Interfaces:**
- Consumes: the project scaffold from Task 1.
- Produces: `tools/gdtest` — a drop-in `godot` wrapper enforcing a hard timeout, used by **every** later task and by CI. The canonical test invocation:
  `tools/gdtest --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`

> This task comes before the code tasks deliberately. Tests cannot be written test-first if the test runner does not exist yet, and a task that reports "tests written but not run" cannot be reviewed.

- [ ] **Step 1: Vendor GUT at the release matching the engine minor**

GUT pins to engine minors. Confirm the current 4.7-compatible tag before downloading — **do not assume a version number**:

```bash
git ls-remote --tags --refs https://github.com/bitwes/Gut.git | tail -15
```

Pick the highest tag documented as supporting Godot 4.7, then:

```bash
TAG=<the tag you chose>
curl -fsSL "https://github.com/bitwes/Gut/archive/refs/tags/${TAG}.tar.gz" -o /tmp/gut.tar.gz
mkdir -p /tmp/gut && tar -xzf /tmp/gut.tar.gz -C /tmp/gut --strip-components=1
cp -R /tmp/gut/addons/gut addons/gut
ls addons/gut/gut_cmdln.gd addons/gut/LICENSE.md
```

**Write down the tag you chose** — Task 7 Step 1 records it in `ASSETS.md` under "Dev tooling". GUT is MIT with its own copyright notice, which spec §1 criterion 5 commits to preserving.

- [ ] **Step 2: Write `tools/gdtest`**

```bash
#!/usr/bin/env bash
#
# Runs Godot under a HARD timeout. Always use this instead of calling the Godot
# binary directly for headless work.
#
# Why: in the predecessor project, hung headless Godot processes orphaned to
# launchd (PPID 1) and burned CPU for two days before anyone noticed. The
# timeout is the safety net; scripts should still terminate themselves.
#
#   GODOT=/path/to/Godot tools/gdtest --path . --headless -s addons/gut/gut_cmdln.gd -gexit
#   GDTEST_TIMEOUT=600 tools/gdtest ...
set -euo pipefail

: "${GODOT:=godot}"
: "${GDTEST_TIMEOUT:=180}"

# GNU coreutils is 'timeout' on Linux/CI and 'gtimeout' on macOS via Homebrew.
if command -v timeout >/dev/null 2>&1; then
	TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
	TIMEOUT_BIN="gtimeout"
else
	echo "gdtest: need 'timeout' (Linux) or 'gtimeout' (macOS: brew install coreutils)" >&2
	exit 127
fi

if ! command -v "$GODOT" >/dev/null 2>&1 && [[ ! -x "$GODOT" ]]; then
	echo "gdtest: GODOT is not set to an executable Godot binary (got: $GODOT)" >&2
	exit 127
fi

exec "$TIMEOUT_BIN" -k 10 "$GDTEST_TIMEOUT" "$GODOT" "$@"
```

```bash
chmod +x tools/gdtest
```

- [ ] **Step 3: Import the project so GUT's files are recognised**

```bash
GDTEST_TIMEOUT=600 tools/gdtest --path . --headless --import
```

- [ ] **Step 4: Prove the runner works with a throwaway test**

```bash
mkdir -p tests/unit
cat > tests/unit/test_smoke.gd <<'EOF'
extends GutTest


func test_the_runner_runs() -> void:
	assert_eq(2 + 2, 4)
EOF

tools/gdtest --path . --headless \
	-s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
echo "exit=$?"
```

Expected: 1 passing test, exit=0.

Now prove the runner reports failure correctly — a green-only check does not prove a test runner works:

```bash
cat > tests/unit/test_smoke.gd <<'EOF'
extends GutTest


func test_the_runner_runs() -> void:
	assert_eq(2 + 2, 5)
EOF

tools/gdtest --path . --headless \
	-s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
echo "exit=$?"
```

Expected: 1 failing test, **exit non-zero**. If it exits 0 on a failing test, CI would be blind — stop and fix the invocation before continuing.

```bash
rm tests/unit/test_smoke.gd
```

- [ ] **Step 5: Verify the timeout actually fires**

```bash
cat > /tmp/hang.gd <<'EOF'
extends SceneTree
func _init() -> void:
	while true:
		OS.delay_msec(100)
EOF
cp /tmp/hang.gd tools/hang_probe.gd
GDTEST_TIMEOUT=5 tools/gdtest --path . --headless --script res://tools/hang_probe.gd; echo "exit=$?"
rm tools/hang_probe.gd
```

Expected: terminates after ~5s with a non-zero exit (124 from `timeout`). If it hangs, `tools/gdtest` is not doing its one job.

- [ ] **Step 6: Commit**

```bash
git add addons/gut tools/gdtest project.godot
git commit -m "test: vendor GUT and add timeout-wrapped headless test runner"
```

---

### Task 3: Addon skeleton and the `FpsSettings` autoload registration

**Files:**
- Create: `addons/fps_starter/plugin.cfg`
- Create: `addons/fps_starter/plugin.gd`
- Modify: `project.godot` (autoload section, written by the editor)

**Interfaces:**
- Consumes: the directory layout from Task 1.
- Produces: an enableable plugin named `FPS Starter`; the autoload `FpsSettings` pointing at `res://addons/fps_starter/util/fps_settings.gd` (the script itself arrives in Task 5).

- [ ] **Step 1: Write `addons/fps_starter/plugin.cfg`**

```ini
[plugin]

name="FPS Starter"
description="A modern first-person shooter foundation: player controller, weapons, combat, AI, and UI shell."
author="Nicholas Smith"
version="0.1.0"
script="plugin.gd"
```

- [ ] **Step 2: Write `addons/fps_starter/plugin.gd`**

The guard on `has_setting` matters: `_enter_tree()` runs on **every editor start**, and `add_autoload_singleton()` writes to `project.godot`. Without the guard, every launch dirties the user's VCS.

```gdscript
@tool
extends EditorPlugin

## Editor-side installation for the FPS Starter framework.
##
## Deliberately minimal. It registers ONE autoload and nothing else.
## In particular it does NOT write Input Map actions into project.godot:
## ProjectSettings.save() rewrites the consumer's entire project file, and
## actions written that way do not reach InputMap until the editor restarts.
## Input actions and audio buses are instead created at runtime and
## idempotently by FpsSettings — see FpsInputBootstrap and FpsAudioBuses.

const AUTOLOAD_NAME := "FpsSettings"
const AUTOLOAD_PATH := "res://addons/fps_starter/util/fps_settings.gd"


func _enter_tree() -> void:
	# _enter_tree runs on every editor start; only write project.godot if the
	# autoload is genuinely absent, otherwise we churn the user's VCS.
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _exit_tree() -> void:
	# Removing our OWN autoload on disable is correct and reversible.
	# Note the asymmetry with input actions, which we never remove: those hold
	# the user's rebinds, and destroying them on a plugin toggle loses data.
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)
```

- [ ] **Step 3: Create the placeholder autoload script so the plugin can enable**

`add_autoload_singleton` fails if the target script does not exist. Create `addons/fps_starter/util/fps_settings.gd` with a stub that Task 5 replaces:

```gdscript
extends Node

## Autoload owning user settings and the runtime bootstrap.
## Stub — implemented in Task 5.
```

- [ ] **Step 4: Enable the plugin and verify the autoload appears**

Open the editor, go to **Project → Project Settings → Plugins**, and enable **FPS Starter**. Then verify:

```bash
grep -A2 '^\[autoload\]' project.godot
```

Expected: a line `FpsSettings="*res://addons/fps_starter/util/fps_settings.gd"`.

- [ ] **Step 5: Re-enable GDScript warnings for the framework (spec §4.1)**

**Godot excludes `res://addons` from GDScript warnings by default.** Left alone, our
architecture silently turns the editor's warnings off for ~90% of the codebase — untenable for a
project whose standard is production quality, and in direct conflict with the Asset Store
guideline *"fix or suppress all script warnings."*

This was verified against Godot **4.6** source, and the setting's value encoding may differ in
4.7. **Discover the real value; do not guess it:**

```bash
cat > /tmp/probe_warnings.gd <<'EOF'
extends SceneTree
func _init() -> void:
	var key := "debug/gdscript/warnings/directory_rules"
	print("value: ", ProjectSettings.get_setting(key))
	for info in ProjectSettings.get_property_list():
		if info["name"] == key:
			print("info:  ", info)
	quit()
EOF
cp /tmp/probe_warnings.gd tools/ci/probe_warnings.gd
tools/gdtest --path . --headless --script res://tools/ci/probe_warnings.gd
rm tools/ci/probe_warnings.gd
```

Record what it prints. It should be a Dictionary mapping a path to a decision enum — expected
shape `{ "res://addons": <EXCLUDE> }`. Then set the rule so our framework is **included**, using
the enum values the probe actually reported, via **Project Settings → GDScript → Warnings →
Directory Rules** (turn on Advanced Settings to see it). Keep the existing `res://addons` rule so
third-party addons such as GUT stay excluded — we only want *our* directory linted:

```ini
[debug]

gdscript/warnings/directory_rules={
"res://addons": <the EXCLUDE value the probe printed>,
"res://addons/fps_starter": <the INCLUDE value the probe printed>
}
```

Verify by adding an unused variable to `plugin.gd` and confirming the editor now warns on it,
then remove it. If the setting does not exist in 4.7 under this name, note that in the commit
message and open a follow-up — do not silently skip the requirement.

- [ ] **Step 6: Commit**

```bash
git add addons/fps_starter/plugin.cfg addons/fps_starter/plugin.gd \
        addons/fps_starter/util/fps_settings.gd project.godot
git commit -m "feat: addon skeleton with guarded FpsSettings autoload registration"
```

---

### Task 4: Idempotent input-action bootstrap

**Files:**
- Create: `addons/fps_starter/util/fps_input_bootstrap.gd`
- Test: `tests/unit/test_fps_input_bootstrap.gd`

**Interfaces:**
- Consumes: nothing beyond the engine.
- Produces: `FpsInputBootstrap.ensure_actions() -> void`, a static method registering every default action. Action names later tasks use: `fps_move_forward`, `fps_move_back`, `fps_move_left`, `fps_move_right`, `fps_jump`, `fps_sprint`, `fps_crouch`, `fps_fire`, `fps_aim`, `fps_reload`, `fps_weapon_next`, `fps_interact`, `fps_pause`. Also `FpsInputBootstrap.ACTIONS: PackedStringArray` listing all of them.

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest

## FpsInputBootstrap must be safe to call repeatedly: it runs on every game
## start, and in the demo the actions ALSO exist in project.godot already.

var _created: Array[String] = []


func before_each() -> void:
	# Track which actions we had to create so after_each can restore the
	# project's real InputMap — these tests mutate global engine state.
	_created.clear()
	for action in FpsInputBootstrap.ACTIONS:
		if not InputMap.has_action(action):
			_created.append(action)


func after_each() -> void:
	for action in _created:
		if InputMap.has_action(action):
			InputMap.erase_action(action)


func test_ensure_actions_creates_every_declared_action() -> void:
	FpsInputBootstrap.ensure_actions()
	for action in FpsInputBootstrap.ACTIONS:
		assert_true(InputMap.has_action(action), "missing action: %s" % action)


func test_ensure_actions_is_idempotent() -> void:
	FpsInputBootstrap.ensure_actions()
	var counts := {}
	for action in FpsInputBootstrap.ACTIONS:
		counts[action] = InputMap.action_get_events(action).size()

	FpsInputBootstrap.ensure_actions()

	for action in FpsInputBootstrap.ACTIONS:
		assert_eq(
			InputMap.action_get_events(action).size(),
			counts[action],
			"duplicate events added for: %s" % action
		)


func test_move_forward_is_bound_to_physical_w() -> void:
	FpsInputBootstrap.ensure_actions()
	var has_w := false
	for event in InputMap.action_get_events(&"fps_move_forward"):
		if event is InputEventKey and event.physical_keycode == KEY_W:
			has_w = true
	assert_true(has_w, "fps_move_forward should be bound to physical W")


func test_crouch_is_bound_to_both_ctrl_and_c() -> void:
	# 'C' is a deliberate alternate: binding bare Ctrl is unreliable on macOS.
	FpsInputBootstrap.ensure_actions()
	var keys: Array[int] = []
	for event in InputMap.action_get_events(&"fps_crouch"):
		if event is InputEventKey:
			keys.append(event.physical_keycode)
	assert_has(keys, KEY_CTRL)
	assert_has(keys, KEY_C)
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tools/gdtest --path . --headless \
	-s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_fps_input_bootstrap.gd -gexit
```

Expected: FAIL with an identifier-not-declared error for `FpsInputBootstrap`.

- [ ] **Step 3: Write the implementation**

```gdscript
## Registers the starter's default Input Map actions at RUNTIME, idempotently.
##
## Why runtime rather than project.godot? An addon cannot ship an Input Map.
## Writing actions via ProjectSettings does not populate InputMap until the
## editor restarts, and ProjectSettings.save() rewrites the consumer's entire
## project file. Registering here works in exported builds, survives the plugin
## being disabled, and never mutates the consumer's project.
##
## The demo ALSO commits these actions to project.godot so they are visible in
## the editor's Input Map panel — beginners look there first. That is why every
## method below is idempotent: in the demo, the actions already exist.
class_name FpsInputBootstrap
extends RefCounted

const DEADZONE := 0.5

## Every action this framework reads. Consumers may rebind them freely.
const ACTIONS: PackedStringArray = [
	"fps_move_forward",
	"fps_move_back",
	"fps_move_left",
	"fps_move_right",
	"fps_jump",
	"fps_sprint",
	"fps_crouch",
	"fps_fire",
	"fps_aim",
	"fps_reload",
	"fps_weapon_next",
	"fps_interact",
	"fps_pause",
]


## Creates any missing action and any missing default binding.
## Safe to call on every start; never duplicates an existing binding.
static func ensure_actions() -> void:
	_key(&"fps_move_forward", KEY_W)
	_key(&"fps_move_back", KEY_S)
	_key(&"fps_move_left", KEY_A)
	_key(&"fps_move_right", KEY_D)

	_key(&"fps_jump", KEY_SPACE)
	_joy_button(&"fps_jump", JOY_BUTTON_A)

	_key(&"fps_sprint", KEY_SHIFT)
	_joy_button(&"fps_sprint", JOY_BUTTON_LEFT_STICK)

	# Ctrl AND C: binding bare Ctrl is unreliable on macOS, so C is a first
	# class alternate rather than a fallback.
	_key(&"fps_crouch", KEY_CTRL)
	_key(&"fps_crouch", KEY_C)
	_joy_button(&"fps_crouch", JOY_BUTTON_B)

	_mouse(&"fps_fire", MOUSE_BUTTON_LEFT)
	_joy_axis(&"fps_fire", JOY_AXIS_TRIGGER_RIGHT, 1.0)

	_mouse(&"fps_aim", MOUSE_BUTTON_RIGHT)
	_joy_axis(&"fps_aim", JOY_AXIS_TRIGGER_LEFT, 1.0)

	_key(&"fps_reload", KEY_R)
	_joy_button(&"fps_reload", JOY_BUTTON_X)

	_key(&"fps_weapon_next", KEY_E)
	_mouse(&"fps_weapon_next", MOUSE_BUTTON_MIDDLE)
	_joy_button(&"fps_weapon_next", JOY_BUTTON_Y)

	_key(&"fps_interact", KEY_F)
	_joy_button(&"fps_interact", JOY_BUTTON_A)

	_key(&"fps_pause", KEY_ESCAPE)
	_joy_button(&"fps_pause", JOY_BUTTON_START)


static func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)


static func _add_if_absent(action: StringName, event: InputEvent) -> void:
	_ensure_action(action)
	for existing in InputMap.action_get_events(action):
		if existing.is_match(event, false):
			return
	InputMap.action_add_event(action, event)


## Binds a PHYSICAL key, so the layout follows the keycap position rather than
## the character — WASD stays WASD on AZERTY and Dvorak.
static func _key(action: StringName, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	_add_if_absent(action, event)


static func _mouse(action: StringName, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	_add_if_absent(action, event)


static func _joy_button(action: StringName, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	_add_if_absent(action, event)


static func _joy_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	_add_if_absent(action, event)
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
tools/gdtest --path . --headless \
	-s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Expected: PASS, exit=0.

- [ ] **Step 5: Commit**

```bash
git add addons/fps_starter/util/fps_input_bootstrap.gd tests/unit/test_fps_input_bootstrap.gd
git commit -m "feat: idempotent runtime input-action bootstrap"
```

---

### Task 5: Audio bus bootstrap

**Files:**
- Create: `addons/fps_starter/util/fps_audio_buses.gd`
- Test: `tests/unit/test_fps_audio_buses.gd`

**Interfaces:**
- Consumes: nothing beyond the engine.
- Produces: `FpsAudioBuses.ensure_buses() -> void`; constants `FpsAudioBuses.MUSIC: StringName` (`&"Music"`) and `FpsAudioBuses.SFX: StringName` (`&"SFX"`); `FpsAudioBuses.set_bus_volume(bus: StringName, linear: float) -> void`.

> A default Godot project has exactly **one** audio bus, `Master`. The spec's Master/Music/SFX split does not exist until something creates it.

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest

## A default project ships exactly one bus (Master). These buses must therefore
## be created at runtime, and creation must be safe to repeat.

func after_each() -> void:
	# Remove buses we added, highest index first so indices stay valid.
	for bus_name in [FpsAudioBuses.SFX, FpsAudioBuses.MUSIC]:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx > 0:
			AudioServer.remove_bus(idx)


func test_creates_music_and_sfx_buses() -> void:
	FpsAudioBuses.ensure_buses()
	assert_gt(AudioServer.get_bus_index(FpsAudioBuses.MUSIC), 0, "Music bus missing")
	assert_gt(AudioServer.get_bus_index(FpsAudioBuses.SFX), 0, "SFX bus missing")


func test_ensure_buses_is_idempotent() -> void:
	FpsAudioBuses.ensure_buses()
	var count := AudioServer.bus_count
	FpsAudioBuses.ensure_buses()
	assert_eq(AudioServer.bus_count, count, "duplicate buses created")


func test_created_buses_route_to_master() -> void:
	FpsAudioBuses.ensure_buses()
	var idx := AudioServer.get_bus_index(FpsAudioBuses.SFX)
	assert_eq(str(AudioServer.get_bus_send(idx)), "Master")


func test_set_bus_volume_converts_linear_to_db() -> void:
	FpsAudioBuses.ensure_buses()
	FpsAudioBuses.set_bus_volume(FpsAudioBuses.SFX, 0.5)
	var idx := AudioServer.get_bus_index(FpsAudioBuses.SFX)
	assert_almost_eq(AudioServer.get_bus_volume_db(idx), linear_to_db(0.5), 0.01)


func test_set_bus_volume_mutes_at_zero() -> void:
	FpsAudioBuses.ensure_buses()
	FpsAudioBuses.set_bus_volume(FpsAudioBuses.SFX, 0.0)
	var idx := AudioServer.get_bus_index(FpsAudioBuses.SFX)
	assert_true(AudioServer.is_bus_mute(idx), "zero volume should mute rather than -inf dB")
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tools/gdtest --path . --headless \
	-s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_fps_audio_buses.gd -gexit
```

Expected: FAIL, `FpsAudioBuses` not declared.

- [ ] **Step 3: Write the implementation**

```gdscript
## Creates the framework's audio buses at runtime, idempotently.
##
## A default Godot project has exactly ONE bus (Master), so an addon that
## assumes a Music/SFX split will silently route everything to Master — or
## crash on a bad bus name. This creates them if absent and leaves them alone
## if the consumer already defined their own.
class_name FpsAudioBuses
extends RefCounted

const MASTER := &"Master"
const MUSIC := &"Music"
const SFX := &"SFX"


## Creates any missing bus, routed to Master. Safe to call repeatedly.
static func ensure_buses() -> void:
	_ensure(MUSIC)
	_ensure(SFX)


## Sets a bus volume from a 0..1 linear value, as a volume slider produces.
## Zero mutes rather than setting -inf dB, which some drivers handle poorly.
static func set_bus_volume(bus: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		push_warning("FpsAudioBuses: unknown bus '%s'" % bus)
		return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, is_zero_approx(linear))
	if not is_zero_approx(linear):
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


static func _ensure(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, MASTER)
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
tools/gdtest --path . --headless \
	-s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Expected: PASS, exit=0.

- [ ] **Step 5: Commit**

```bash
git add addons/fps_starter/util/fps_audio_buses.gd tests/unit/test_fps_audio_buses.gd
git commit -m "feat: runtime audio bus bootstrap with linear volume helper"
```

---

### Task 6: Settings data, persistence, and the `FpsSettings` autoload

**Files:**
- Create: `addons/fps_starter/util/fps_settings_data.gd`
- Modify: `addons/fps_starter/util/fps_settings.gd` (replaces the Task 2 stub)
- Test: `tests/unit/test_fps_settings_data.gd`

**Interfaces:**
- Consumes: `FpsInputBootstrap.ensure_actions()`, `FpsAudioBuses.ensure_buses()`, `FpsAudioBuses.set_bus_volume()`.
- Produces:
  - `FpsSettingsData` (RefCounted) with properties `mouse_sensitivity: float`, `invert_y: bool`, `aim_assist: float`, `hold_to_aim: bool`, `hold_to_crouch: bool`, `hold_to_sprint: bool`, `master_volume: float`, `music_volume: float`, `sfx_volume: float`, `quality_preset: int`, `fullscreen: bool`, `fov: float`, `camera_shake_scale: float`, `head_bob_enabled: bool`; methods `to_config(cfg: ConfigFile) -> void`, `from_config(cfg: ConfigFile) -> void`.
  - Autoload `FpsSettings` with `data: FpsSettingsData`, `signal changed`, `load_from_disk() -> void`, `save_to_disk() -> void`, `apply() -> void`.

> The data/persistence split mirrors the spec's `FpsWeaponData`/`FpsWeaponState` pattern: pure logic in a RefCounted that unit-tests headlessly, engine wiring in the Node.

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest

## FpsSettingsData is deliberately engine-free so it can be tested without a
## SceneTree, a display, or touching user://.

func test_round_trips_every_field_through_configfile() -> void:
	var original := FpsSettingsData.new()
	original.mouse_sensitivity = 0.42
	original.invert_y = true
	original.aim_assist = 0.3
	original.hold_to_aim = false
	original.hold_to_crouch = false
	original.hold_to_sprint = false
	original.master_volume = 0.6
	original.music_volume = 0.1
	original.sfx_volume = 0.9
	original.quality_preset = 1
	original.fullscreen = true
	original.fov = 103.0
	original.camera_shake_scale = 0.0
	original.head_bob_enabled = false

	var cfg := ConfigFile.new()
	original.to_config(cfg)

	var restored := FpsSettingsData.new()
	restored.from_config(cfg)

	assert_almost_eq(restored.mouse_sensitivity, 0.42, 0.0001)
	assert_true(restored.invert_y)
	assert_almost_eq(restored.aim_assist, 0.3, 0.0001)
	assert_false(restored.hold_to_aim)
	assert_false(restored.hold_to_crouch)
	assert_false(restored.hold_to_sprint)
	assert_almost_eq(restored.master_volume, 0.6, 0.0001)
	assert_almost_eq(restored.music_volume, 0.1, 0.0001)
	assert_almost_eq(restored.sfx_volume, 0.9, 0.0001)
	assert_eq(restored.quality_preset, 1)
	assert_true(restored.fullscreen)
	assert_almost_eq(restored.fov, 103.0, 0.0001)
	assert_almost_eq(restored.camera_shake_scale, 0.0, 0.0001)
	assert_false(restored.head_bob_enabled)


func test_missing_keys_keep_defaults() -> void:
	# A settings file written by an older version must not wipe new fields.
	var defaults := FpsSettingsData.new()
	var restored := FpsSettingsData.new()
	restored.from_config(ConfigFile.new())
	assert_almost_eq(restored.fov, defaults.fov, 0.0001)
	assert_almost_eq(restored.mouse_sensitivity, defaults.mouse_sensitivity, 0.0001)
	assert_eq(restored.head_bob_enabled, defaults.head_bob_enabled)


func test_out_of_range_values_are_clamped_on_load() -> void:
	# A hand-edited settings file must not be able to produce an unusable game.
	var cfg := ConfigFile.new()
	cfg.set_value("video", "fov", 500.0)
	cfg.set_value("audio", "master_volume", 12.0)
	cfg.set_value("controls", "mouse_sensitivity", -3.0)

	var restored := FpsSettingsData.new()
	restored.from_config(cfg)

	assert_between(restored.fov, 60.0, 120.0)
	assert_between(restored.master_volume, 0.0, 1.0)
	assert_gt(restored.mouse_sensitivity, 0.0)
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tools/gdtest --path . --headless \
	-s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_fps_settings_data.gd -gexit
```

Expected: FAIL, `FpsSettingsData` not declared.

- [ ] **Step 3: Write `fps_settings_data.gd`**

```gdscript
## Every user-facing setting, plus ConfigFile serialisation.
##
## Engine-free by design (RefCounted, no nodes, no file IO) so it unit-tests
## headlessly. FpsSettings is the autoload that owns one of these and applies
## it to the running game.
class_name FpsSettingsData
extends RefCounted

const SECTION_CONTROLS := "controls"
const SECTION_AUDIO := "audio"
const SECTION_VIDEO := "video"
const SECTION_ACCESSIBILITY := "accessibility"

const FOV_MIN := 60.0
const FOV_MAX := 120.0

## Radians of camera rotation per pixel of mouse movement, before the
## resolution-independence correction applied by the camera rig.
var mouse_sensitivity: float = 0.25
var invert_y: bool = false
## Gamepad-only bullet magnetism, 0 = off, 1 = strongest.
var aim_assist: float = 0.65
var hold_to_aim: bool = true
var hold_to_crouch: bool = true
var hold_to_sprint: bool = true

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

## 0 = Balanced, 1 = High.
var quality_preset: int = 0
var fullscreen: bool = false
var fov: float = 75.0

## Multiplies all camera shake. Reaches exactly 0 for players who need it off.
var camera_shake_scale: float = 1.0
var head_bob_enabled: bool = true


func to_config(cfg: ConfigFile) -> void:
	cfg.set_value(SECTION_CONTROLS, "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value(SECTION_CONTROLS, "invert_y", invert_y)
	cfg.set_value(SECTION_CONTROLS, "aim_assist", aim_assist)
	cfg.set_value(SECTION_CONTROLS, "hold_to_aim", hold_to_aim)
	cfg.set_value(SECTION_CONTROLS, "hold_to_crouch", hold_to_crouch)
	cfg.set_value(SECTION_CONTROLS, "hold_to_sprint", hold_to_sprint)

	cfg.set_value(SECTION_AUDIO, "master_volume", master_volume)
	cfg.set_value(SECTION_AUDIO, "music_volume", music_volume)
	cfg.set_value(SECTION_AUDIO, "sfx_volume", sfx_volume)

	cfg.set_value(SECTION_VIDEO, "quality_preset", quality_preset)
	cfg.set_value(SECTION_VIDEO, "fullscreen", fullscreen)
	cfg.set_value(SECTION_VIDEO, "fov", fov)

	cfg.set_value(SECTION_ACCESSIBILITY, "camera_shake_scale", camera_shake_scale)
	cfg.set_value(SECTION_ACCESSIBILITY, "head_bob_enabled", head_bob_enabled)


## Reads values, falling back to the CURRENT value for any missing key — so a
## settings file written by an older build never wipes newly added fields.
## Everything numeric is clamped: a hand-edited file must not be able to
## produce an unplayable game.
func from_config(cfg: ConfigFile) -> void:
	mouse_sensitivity = clampf(
		cfg.get_value(SECTION_CONTROLS, "mouse_sensitivity", mouse_sensitivity), 0.01, 5.0
	)
	invert_y = cfg.get_value(SECTION_CONTROLS, "invert_y", invert_y)
	aim_assist = clampf(cfg.get_value(SECTION_CONTROLS, "aim_assist", aim_assist), 0.0, 1.0)
	hold_to_aim = cfg.get_value(SECTION_CONTROLS, "hold_to_aim", hold_to_aim)
	hold_to_crouch = cfg.get_value(SECTION_CONTROLS, "hold_to_crouch", hold_to_crouch)
	hold_to_sprint = cfg.get_value(SECTION_CONTROLS, "hold_to_sprint", hold_to_sprint)

	master_volume = clampf(cfg.get_value(SECTION_AUDIO, "master_volume", master_volume), 0.0, 1.0)
	music_volume = clampf(cfg.get_value(SECTION_AUDIO, "music_volume", music_volume), 0.0, 1.0)
	sfx_volume = clampf(cfg.get_value(SECTION_AUDIO, "sfx_volume", sfx_volume), 0.0, 1.0)

	quality_preset = clampi(cfg.get_value(SECTION_VIDEO, "quality_preset", quality_preset), 0, 1)
	fullscreen = cfg.get_value(SECTION_VIDEO, "fullscreen", fullscreen)
	fov = clampf(cfg.get_value(SECTION_VIDEO, "fov", fov), FOV_MIN, FOV_MAX)

	camera_shake_scale = clampf(
		cfg.get_value(SECTION_ACCESSIBILITY, "camera_shake_scale", camera_shake_scale), 0.0, 2.0
	)
	head_bob_enabled = cfg.get_value(SECTION_ACCESSIBILITY, "head_bob_enabled", head_bob_enabled)
```

- [ ] **Step 4: Write `fps_settings.gd`, replacing the Task 2 stub**

```gdscript
extends Node

## Autoload owning user settings and the framework's runtime bootstrap.
##
## Registered by plugin.gd as the autoload "FpsSettings". Framework code must
## reach it through a null-tolerant lookup rather than a bare global, because
## the plugin may be INSTALLED but not ENABLED, in which case this autoload
## does not exist. See FpsSettingsAccess in a later milestone.

const SETTINGS_PATH := "user://settings.cfg"

signal changed

var data := FpsSettingsData.new()


func _ready() -> void:
	# Bootstrap before anything else can read input or play a sound.
	FpsInputBootstrap.ensure_actions()
	FpsAudioBuses.ensure_buses()
	load_from_disk()


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err == OK:
		data.from_config(cfg)
	elif err != ERR_FILE_NOT_FOUND:
		# A corrupt file is not fatal: fall back to defaults and say so.
		push_warning("FpsSettings: could not read %s (error %d); using defaults." % [SETTINGS_PATH, err])
	apply()


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	data.to_config(cfg)
	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_error("FpsSettings: could not write %s (error %d)." % [SETTINGS_PATH, err])


## Pushes the current data into the engine. Call after mutating `data`.
func apply() -> void:
	FpsAudioBuses.set_bus_volume(FpsAudioBuses.MASTER, data.master_volume)
	FpsAudioBuses.set_bus_volume(FpsAudioBuses.MUSIC, data.music_volume)
	FpsAudioBuses.set_bus_volume(FpsAudioBuses.SFX, data.sfx_volume)

	var mode := (
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if data.fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)

	changed.emit()
```

- [ ] **Step 5: Run the tests to verify they pass**

```bash
tools/gdtest --path . --headless \
	-s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Expected: PASS, exit=0.

- [ ] **Step 6: Commit**

```bash
git add addons/fps_starter/util/fps_settings_data.gd \
        addons/fps_starter/util/fps_settings.gd \
        tests/unit/test_fps_settings_data.gd
git commit -m "feat: settings data with clamped ConfigFile persistence"
```
### Task 7: CI — the boundary check and the full gate

**Files:**
- Create: `tools/ci/check_boundary.gd`
- Create: `tools/ci/check_conventions.sh`
- Create: `.github/workflows/ci.yml`
- Create: `ASSETS.md`

**Interfaces:**
- Consumes: the whole repo layout.
- Produces: `tools/ci/check_boundary.gd` (a `SceneTree` script exiting non-zero on violation) and `tools/ci/check_conventions.sh` (class-name prefix + asset-ledger checks).

> A naive `grep` for `res://demo` is **insufficient**: `preload("uid://…")` resolves to a real asset with no `res://` substring anywhere in the file, and the editor emits uid literals on drag-and-drop by default. The checker therefore resolves uids through `ResourceUID`.

- [ ] **Step 1: Write `ASSETS.md`**

```markdown
# Asset Provenance Ledger

Every file under `assets/` must have a row here before it is committed — CI enforces this.
Assets are **CC0 only**; see `LICENSE-ASSETS` for the policy and the rejected-licence list.

The **Retrieved** column is the point of this file. Licences on user-upload sites are
self-declared and terms change; the retrieval date is what lets us re-verify later.

## Art and audio

| Path | Source URL | Author | Licence | Retrieved |
|---|---|---|---|---|
| _(none yet — first assets land in Milestone 6)_ | | | | |

## Dev tooling (not shipped in an exported game)

| Component | Source | Licence | Notes |
|---|---|---|---|
| `addons/gut/` (tag `<the tag chosen in Task 2 Step 1>`) | https://github.com/bitwes/Gut | MIT | Test framework. Retains its own `LICENSE.md`. Safe to delete from a game built on this starter. GUT pins to engine minors — bump this alongside any Godot upgrade. |
```

- [ ] **Step 2: Write `tools/ci/check_boundary.gd`**

```gdscript
extends SceneTree

## CI gate: proves addons/fps_starter/ never depends on demo/ or assets/.
##
## Run with:
##   godot --path . --headless --script res://tools/ci/check_boundary.gd
##
## Why this is not a grep. Godot 4.4+ references resources by UID, and the
## editor setting that emits `preload("uid://...")` on drag-and-drop defaults
## to ON. Such a line resolves to a real file while containing no "res://"
## substring at all, so a grep reports a clean boundary that does not exist.
## Conversely a stale `path=` alongside a valid `uid=` resolves via the uid, so
## grep can be wrong in both directions. We resolve uids for real instead.

const FRAMEWORK_ROOT := "res://addons/fps_starter"
const FORBIDDEN_PREFIXES := ["res://demo", "res://assets"]
const UID_PATTERN := "uid://[a-z0-9]+"

var _violations: Array[String] = []


func _init() -> void:
	var files := _walk(FRAMEWORK_ROOT)
	print("check_boundary: scanning %d files under %s" % [files.size(), FRAMEWORK_ROOT])

	for path in files:
		if path.ends_with(".gd"):
			_check_script(path)
		elif path.ends_with(".tscn") or path.ends_with(".tres"):
			_check_resource(path)

	if _violations.is_empty():
		print("check_boundary: OK — framework has no dependency on demo/ or assets/")
		quit(0)
		return

	printerr("check_boundary: FAILED — the framework may not reference demo/ or assets/")
	printerr("  (spec section 4.2; art must cross the boundary via exported resource slots)")
	for violation in _violations:
		printerr("  " + violation)
	quit(1)


func _walk(root: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		printerr("check_boundary: cannot open %s" % root)
		quit(2)
		return out

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full := root.path_join(name)
		if dir.current_is_dir():
			out.append_array(_walk(full))
		else:
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
	return out


## Resource dependencies arrive as "uid://x::Type::res://path" or
## "res://path::Type". Examine every "::"-separated token: resolve uids through
## ResourceUID and take res:// paths directly.
func _check_resource(path: String) -> void:
	for dep in ResourceLoader.get_dependencies(path):
		for token in String(dep).split("::"):
			var resolved := _resolve(token)
			if resolved != "":
				_record(path, token, resolved)


## Scripts return [] from get_dependencies, so scan their source for both
## literal res:// paths and uid:// literals.
func _check_script(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return

	var uid_re := RegEx.new()
	uid_re.compile(UID_PATTERN)
	for m in uid_re.search_all(text):
		var resolved := _resolve(m.get_string())
		if resolved != "":
			_record(path, m.get_string(), resolved)

	for prefix in FORBIDDEN_PREFIXES:
		if text.contains(prefix):
			_violations.append("%s references %s directly" % [path, prefix])


## Returns the offending real path, or "" if this token is fine.
func _resolve(token: String) -> String:
	token = token.strip_edges()
	if token.begins_with("uid://"):
		var id := ResourceUID.text_to_id(token)
		if id == ResourceUID.INVALID_ID or not ResourceUID.has_id(id):
			return ""
		return _flag(ResourceUID.get_id_path(id))
	if token.begins_with("res://"):
		return _flag(token)
	return ""


func _flag(real_path: String) -> String:
	for prefix in FORBIDDEN_PREFIXES:
		if real_path.begins_with(prefix):
			return real_path
	return ""


func _record(source: String, token: String, resolved: String) -> void:
	if token == resolved:
		_violations.append("%s -> %s" % [source, resolved])
	else:
		_violations.append("%s -> %s (via %s)" % [source, resolved, token])
```

- [ ] **Step 3: Verify the checker catches a real violation**

This is the important step: a checker that never fails is worthless.

```bash
# Plant a violation using the uid form a grep would MISS.
UID=$(grep -o 'uid://[a-z0-9]*' demo/levels/blockout/blockout.tscn | head -1)
echo "const LEAK = preload(\"$UID\")" > addons/fps_starter/util/leak_probe.gd

tools/gdtest --path . --headless --script res://tools/ci/check_boundary.gd; echo "exit=$?"
```

Expected: exit=1, with a line naming `leak_probe.gd` and the resolved `res://demo/...` path.

```bash
# Confirm a plain grep would NOT have caught it, then clean up.
grep -r "res://demo" addons/fps_starter/ || echo "grep found nothing — this is why we resolve uids"
rm addons/fps_starter/util/leak_probe.gd

tools/gdtest --path . --headless --script res://tools/ci/check_boundary.gd; echo "exit=$?"
```

Expected: exit=0.

- [ ] **Step 4: Write `tools/ci/check_conventions.sh`**

```bash
#!/usr/bin/env bash
#
# CI gate: naming and asset-ledger conventions that need no engine.
set -uo pipefail

fail=0

# --- 1. Every class_name in the framework is Fps-prefixed ------------------
# GDScript has no namespaces: class_name is ONE global registry shared with the
# consumer's own code. Generic names like "HealthComponent" WILL collide.
while IFS= read -r line; do
	file="${line%%:*}"
	name="$(sed -E 's/.*class_name[[:space:]]+([A-Za-z0-9_]+).*/\1/' <<<"$line")"
	if [[ ! "$name" =~ ^Fps ]]; then
		echo "FAIL: $file declares '$name'; framework classes must be Fps-prefixed" >&2
		fail=1
	fi
done < <(grep -rn '^\s*class_name' addons/fps_starter/ --include='*.gd' || true)

# --- 2. Every file under assets/ has a row in ASSETS.md -------------------
if [[ -d assets ]]; then
	while IFS= read -r asset; do
		rel="${asset#./}"
		if ! grep -qF "$rel" ASSETS.md; then
			echo "FAIL: $rel has no row in ASSETS.md (see LICENSE-ASSETS)" >&2
			fail=1
		fi
	done < <(find assets -type f ! -name '*.import' ! -name '.gitkeep' 2>/dev/null || true)
fi

# --- 3. No Git LFS ---------------------------------------------------------
# Asset Store downloads are repo archives, and GitHub source archives do not
# resolve LFS pointers — assets would arrive as text stubs.
if [[ -f .gitattributes ]] && grep -q 'filter=lfs' .gitattributes; then
	echo "FAIL: Git LFS is configured; see spec section 6" >&2
	fail=1
fi

if [[ $fail -eq 0 ]]; then
	echo "check_conventions: OK"
fi
exit $fail
```

```bash
chmod +x tools/ci/check_conventions.sh
./tools/ci/check_conventions.sh; echo "exit=$?"
```

Expected: `check_conventions: OK`, exit=0.

- [ ] **Step 5: Write `.github/workflows/ci.yml`**

The import step is wrapped in a timeout because `--headless --import` has an open hang bug on HDRI import, and this project ships a sky.

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

env:
  GODOT_VERSION: 4.7.1

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Godot ${{ env.GODOT_VERSION }}
        run: |
          set -euo pipefail
          BASE="https://github.com/godotengine/godot-builds/releases/download"
          FILE="Godot_v${GODOT_VERSION}-stable_linux.x86_64"
          curl -fsSL "${BASE}/${GODOT_VERSION}-stable/${FILE}.zip" -o godot.zip
          unzip -q godot.zip
          chmod +x "${FILE}"
          sudo mv "${FILE}" /usr/local/bin/godot
          godot --version

      - name: Install gdtoolkit (pinned)
        # Pinned: 4.5.0 predates 4.7 and has open bugs where gdformat emits
        # code Godot cannot parse. gdlint gates; gdformat deliberately does not.
        run: pipx install "gdtoolkit==4.5.0"

      - name: Import project
        run: GDTEST_TIMEOUT=600 tools/gdtest --path . --headless --import

      - name: Lint
        run: gdlint addons/fps_starter tests tools

      - name: Conventions (Fps prefix, asset ledger, no LFS)
        run: ./tools/ci/check_conventions.sh

      - name: Framework/demo boundary
        run: tools/gdtest --path . --headless --script res://tools/ci/check_boundary.gd

      - name: Unit tests
        run: |
          tools/gdtest --path . --headless \
            -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit

      - name: Framework loads standalone
        # The check that cannot be gamed: build a project containing ONLY the
        # addon and load every one of its resources. Proves the boundary
        # functionally, not just textually.
        run: |
          set -euo pipefail
          mkdir -p /tmp/scratch/addons
          cp -R addons/fps_starter /tmp/scratch/addons/
          cat > /tmp/scratch/project.godot <<'EOF'
          config_version=5

          [application]
          config/name="boundary-scratch"
          config/features=PackedStringArray("4.7", "Forward Plus")
          EOF
          cp tools/ci/load_all.gd /tmp/scratch/load_all.gd
          GDTEST_TIMEOUT=600 tools/gdtest --path /tmp/scratch --headless --import
          tools/gdtest --path /tmp/scratch --headless --script res://load_all.gd
```

- [ ] **Step 6: Write `tools/ci/load_all.gd`, used by the standalone check**

```gdscript
extends SceneTree

## Loads every resource in a project that contains ONLY addons/fps_starter/.
## Any load error means the framework has a dependency it cannot satisfy alone,
## which is exactly the failure the path-based boundary check cannot see.

const ROOT := "res://addons/fps_starter"

var _failures: Array[String] = []


func _init() -> void:
	var count := _load_dir(ROOT)
	if _failures.is_empty():
		print("load_all: OK — %d resources loaded standalone" % count)
		quit(0)
		return
	printerr("load_all: FAILED — the framework cannot load without the demo:")
	for failure in _failures:
		printerr("  " + failure)
	quit(1)


func _load_dir(path: String) -> int:
	var loaded := 0
	var dir := DirAccess.open(path)
	if dir == null:
		printerr("load_all: cannot open %s" % path)
		quit(2)
		return 0

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full := path.path_join(name)
		if dir.current_is_dir():
			loaded += _load_dir(full)
		elif full.ends_with(".tscn") or full.ends_with(".tres") or full.ends_with(".gd"):
			if ResourceLoader.load(full) == null:
				_failures.append(full)
			else:
				loaded += 1
		name = dir.get_next()
	dir.list_dir_end()
	return loaded
```

- [ ] **Step 7: Run the whole gate locally before pushing**

```bash
gdlint addons/fps_starter tests tools
./tools/ci/check_conventions.sh
tools/gdtest --path . --headless --script res://tools/ci/check_boundary.gd
tools/gdtest --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Expected: all four exit 0. (Install gdtoolkit locally first: `pipx install "gdtoolkit==4.5.0"`.)

- [ ] **Step 8: Commit and confirm CI is green**

```bash
git add tools/ci .github/workflows/ci.yml ASSETS.md
git commit -m "ci: uid-aware boundary check, conventions gate, standalone load test"
git push origin main
gh run watch
```

---

## Milestone 1 exit criteria

- [ ] `"$GODOT" --path . demo/main.tscn` opens a lit scene with no errors.
- [ ] All unit tests pass headlessly through `tools/gdtest`.
- [ ] The boundary checker demonstrably **fails** on a planted uid-form violation and passes when clean.
- [ ] The standalone load test passes — the framework loads with no demo present.
- [ ] CI is green on `main`.

---

## Roadmap — remaining milestones

Each gets its own plan document, written when we reach it, so it can be informed by what the previous milestone actually taught us. Each produces working, testable software on its own.

### M2 — Player controller
Signal-driven movement state machine (`Walk`/`Sprint`/`Crouch`/`Air`), camera rig with resolution-independent look (`screen_relative`), `Input.set_use_accumulated_input(false)`, physics interpolation enabled, stair step-up/step-down, FOV smoothing, head-bob, coyote time, material-aware footsteps.
**Exit:** walk, sprint, crouch, jump and climb a 20cm step around the blockout; state transitions unit-tested.

### M3 — Weapons
`FpsWeaponData`/`FpsWeaponState`, thin `FpsWeaponController`, `HitscanFire` strategy, viewmodel with idle/fire/reload/equip/ADS as AnimationPlayer transform tracks over the Kenney Blaster Kit mesh, recoil, muzzle flash, `AudioStreamPolyphonic` gunfire, impact FX, two weapons plus switching.
**Exit:** fire, reload, ADS and switch between two weapons; ammo math and fire-rate gating unit-tested; adding a third weapon proven to be one `.tres`.

### M4 — Combat and AI
`FpsHealthComponent`, `FpsHurtBox`, `FpsDamageInfo`, correct hitscan-vs-Area3D layer setup, enemy with `NavigationAgent3D` and `Idle/Patrol → Investigate → Chase → Attack → Dead`, sight perception with a time-to-notice ramp.
**Exit:** you can kill an enemy and it can kill you; headshots register at 2×; perception geometry and damage math unit-tested.

### M5 — UI shell and game loop
HUD (health, ammo, spread-driven crosshair, hitmarker), main/pause/settings/death menus, full key rebinding with gamepad parity, death → respawn, a win condition, interaction and pickups.
**Exit:** a complete play session — start, fight, die or win, restart — without touching the editor.

### M6 — Level, art pass, and release
Art-passed level demonstrating choke point / flanking route / arena, blockout retained for teaching, CC0 asset sourcing against the §6 allowlist, export presets for Windows/Linux/macOS, the five docs, `CHANGELOG.md`, and the Asset Store listing.
**Exit:** a downloadable build, docs that pass the three-newcomer test from spec §1 criterion 3, and a published Asset Store Template.
