extends Node
## event_manager.gd
## Responsibility: Manage ambient horror effects based on evaluation state.
## Reactive to tension levels and player performance.

# ─── Configuration ────────────────────────────────────────────────────────────

@export var tension_smoothing: float = 0.05
@export var base_pitch: float = 1.0
@export var max_pitch_shift: float = 0.4

# ─── Private State ────────────────────────────────────────────────────────────

@onready var ambient_player: AudioStreamPlayer = get_tree().get_first_node_in_group("ambient_audio")

var _target_tension: float = 0.1
var _current_tension: float = 0.1

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("event_manager")
	
	# Explicitly hook into evaluation_manager's resolution signal for feedback
	var evm = get_tree().get_first_node_in_group("evaluation_manager") # Wait, I should add this group to evm
	if evm:
		evm.decision_resolved.connect(_on_decision_resolved)


func _process(_delta: float) -> void:
	# Smooth tension transitions
	_current_tension = lerp(_current_tension, _target_tension, tension_smoothing)
	_apply_tension_effects()


# ─── Hooks from game_manager ──────────────────────────────────────────────────

func handle_phase_shift(_phase_name: String) -> void:
	# Future: Phase-specific ambient shifts
	pass


func on_cycle_started(_id: int) -> void:
	# Subtle reset or uptick on cycle start
	pass


func process_evaluation(state: String, _cycle_id: int) -> void:
	match state:
		"stable":
			_target_tension = 0.1
		"suspicious":
			_target_tension = 0.4
		"failed":
			_target_tension = 0.9


func _on_decision_resolved(correct: bool) -> void:
	if not correct:
		# Immediate "discomfort" cue: sudden pitch dip or volume uptick
		_flash_discomfort()
	else:
		# Soft confirmation: subtle chime or relief in audio
		pass

# ─── Internal Effects ─────────────────────────────────────────────────────────

func _apply_tension_effects() -> void:
	if ambient_player:
		# Pitch rises with tension
		ambient_player.pitch_scale = base_pitch + (_current_tension * max_pitch_shift)
		# Volume climbs slightly
		ambient_player.volume_db = -20.0 + (_current_tension * 15.0)


func _flash_discomfort() -> void:
	if ambient_player:
		var original_pitch = ambient_player.pitch_scale
		ambient_player.pitch_scale = 0.5 # Sickening dip
		await get_tree().create_timer(0.2).timeout
		ambient_player.pitch_scale = original_pitch
