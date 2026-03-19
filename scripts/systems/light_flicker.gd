extends Node3D
## light_flicker.gd
## Responsibility: Provides subtle, high-tension flickering effects to a light.
## Can be triggered globally or via anomaly_manager.

# ─── Configuration ────────────────────────────────────────────────────────────

@export var flicker_intensity_min: float = 0.5
@export var flicker_intensity_max: float = 1.0
@export var flicker_speed: float = 0.1 ## Time between flickers (s)

@export var is_flickering: bool = false ## Controlled by anomaly_manager

# ─── Private State ────────────────────────────────────────────────────────────

@onready var _light: Light3D = self as Light3D
var _original_energy: float = 1.0
var _timer: float = 0.0

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	if _light:
		_original_energy = _light.light_energy


func _process(delta: float) -> void:
	if not is_flickering or not _light:
		if _light and _light.light_energy != _original_energy:
			_light.light_energy = _original_energy
		return
	
	_timer += delta
	if _timer >= flicker_speed:
		_timer = 0.0
		_apply_flicker()


func _apply_flicker() -> void:
	_light.light_energy = randf_range(flicker_intensity_min, flicker_intensity_max)
	# Occasionally drop to near zero for tension
	if randf() < 0.1:
		_light.light_energy = 0.1


func set_flicker_enabled(enabled: bool) -> void:
	is_flickering = enabled
