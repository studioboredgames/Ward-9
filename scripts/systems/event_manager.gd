extends Node
## event_manager.gd
## Responsibility: Schedules horror events, scares, and environmental triggers.
## Reacts to phase shifts and player evaluation state.

# ─── Private State ────────────────────────────────────────────────────────────

@onready var _ambient_hum: AudioStreamPlayer = get_node_or_null("../AmbientPlayer")
var _current_evaluation: String = "stable"
var _current_phase: String = "shift_start"

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("event_manager")

# ─── Public API (Input Handlers) ──────────────────────────────────────────────

## Called by game_manager on phase transition.
func handle_phase_shift(phase_name: String) -> void:
	_current_phase = phase_name
	_trigger_atmospheric_change()


## Reactive signal receiver from evaluation_manager (one of the allowed direct paths).
func process_evaluation(state: String, _cycle_id: int) -> void:
	_current_evaluation = state
	_scale_horror_intensity()

# ─── Event Logic ──────────────────────────────────────────────────────────────

func _trigger_atmospheric_change() -> void:
	# Logic to dim lights, change ambient sounds, or swap textures
	match _current_phase:
		"midnight":
			# Dim the Ward lights by 30%
			pass
		"pre_dawn":
			# Heavy fog or static noise audio ramp-up
			pass


func _scale_horror_intensity() -> void:
	# Scale complexity of environmental glitches based on how "suspicious" the player is
	match _current_evaluation:
		"stable":
			if _ambient_hum:
				_ambient_hum.pitch_scale = 1.0
				_ambient_hum.volume_db = -15.0
		"suspicious":
			# Flickering lights, distant footsteps
			if _ambient_hum:
				_ambient_hum.pitch_scale = 0.9 # Deeper, more unsettling
				_ambient_hum.volume_db = -10.0
		"failed":
			# High-intensity auditory hallucinations, patient model distortions
			if _ambient_hum:
				_ambient_hum.pitch_scale = 0.8
				_ambient_hum.volume_db = -5.0
			_schedule_climax_event()


func _schedule_climax_event() -> void:
	# Trigger the definitive "You are the anomaly" reveal sequence
	pass
