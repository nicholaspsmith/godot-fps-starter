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
##
## Why _enable_plugin/_disable_plugin and NOT _enter_tree/_exit_tree:
## _enter_tree and _exit_tree run on every editor start and shutdown, so
## removing the autoload from _exit_tree deletes it again on every quit —
## verified on 4.7.1, where the entry never survived to disk. The
## _enable_plugin/_disable_plugin pair fires only on the explicit toggle in
## the Plugins tab, which is the actual install/uninstall event.
##
## Note this means a CLONED project never runs _enable_plugin at all — the
## autoload is already committed in project.godot, which is the correct and
## expected state for the demo.

const AUTOLOAD_NAME := "FpsSettings"
const AUTOLOAD_PATH := "res://addons/fps_starter/util/fps_settings.gd"


func _enable_plugin() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _disable_plugin() -> void:
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)
