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
