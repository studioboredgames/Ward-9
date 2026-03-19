extends Node
## event_manager.gd
## Responsibility: Manage delayed consequences and subconscious feedback.
## Decouples player actions from immediate system response.

# ─── Configuration ────────────────────────────────────────────────────────────

@export var tension_smoothing: float = 0.05
@export var base_pitch: float = 1.0

# ─── Private State ────────────────────────────────────────────────────────────

@onready var ambient_player: AudioStreamPlayer = get_tree().get_first_node_in_group("ambient_audio")
@onready var light_system: Node = get_node_or_null("../Ward") # Simplified lookup

var _current_tension: float = 0.1
var _target_tension: float = 0.1
var _mistakes: int = 0

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("event_manager")
	# Hook into evaluation for lagged feedback
	var evm = get_tree().get_first_node_in_group("evaluation_manager")
	if evm:
		evm.decision_resolved.connect(_on_decision_resolved)


func _process(_delta: float) -> void:
	_current_tension = lerp(_current_tension, _target_tension, tension_smoothing)
	_apply_tension_effects()


# ─── Hooks ────────────────────────────────────────────────────────────────────

func handle_phase_shift(_phase_name: String) -> void:
	pass


func on_cycle_started(_id: int) -> void:
	pass


func process_evaluation(state: String, _cycle_id: int) -> void:
	# General tension based on overall performance
	match state:
		"stable": _target_tension = 0.1
		"unstable": _target_tension = 0.4
		"failed": _target_tension = 0.8


func _on_decision_resolved(correct: bool) -> void:
	if correct:
		return # Correct is silent
	
	_mistakes += 1
	
	# Subconscious Feedback (Immediate but very subtle)
	_trigger_subconscious_hit()
	
	# Lagged Punishment (The "Teeth")
	# Consequence is decoupled from cause (5 - 15s delay)
	var delay = randf_range(5.0, 15.0)
	get_tree().create_timer(delay).timeout.connect(_trigger_delayed_consequence)

# ─── Internal Effects ─────────────────────────────────────────────────────────

func _trigger_subconscious_hit() -> void:
	# Subtle 0.1s light dip and hum spike
	if ambient_player:
		ambient_player.pitch_scale += 0.05
	
	# Light dip: temporarily drop energy on all BedLights
	var lights = get_tree().get_nodes_in_group("bed_light")
	for l in lights:
		if l.has_method("set_flicker_enabled"):
			l.is_flickering = true # Brief flicker
	
	await get_tree().create_timer(0.2).timeout
	
	for l in lights:
		# Only keep flickering if it wasn't a global anomaly
		l.is_flickering = false 


func _trigger_delayed_consequence() -> void:
	# This is where mistakes actually manifest
	if _mistakes >= 2:
		_trigger_environmental_event()


func _trigger_environmental_event() -> void:
	# Sudden flickering, strange sound, or fake anomaly spike
	print("Event Manager: Delayed Punishment triggering.")
	_target_tension += 0.2
	
	# Future: pick from an actual Event Pool (flicker, whisper, door bang)
	var lights = get_tree().get_nodes_in_group("bed_light")
	for l in lights:
		if l.has_method("set_flicker_enabled"):
			l.set_flicker_enabled(true)
	
	await get_tree().create_timer(3.0).timeout
	
	for l in lights:
		if l.has_method("set_flicker_enabled"):
			l.set_flicker_enabled(false)


func _apply_tension_effects() -> void:
	if ambient_player:
		ambient_player.pitch_scale = base_pitch + (_current_tension * 0.3)
		ambient_player.volume_db = -18.0 + (_current_tension * 12.0)
