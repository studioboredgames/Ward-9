extends CharacterBody3D
## patient.gd
## Responsibility: Authority for rendered truth of the patient (visuals).
## Implements: Subtle horizontal noise (jitter) and unreliable resets.

var is_anomalous: bool = false
var anomaly_type: String = ""
var is_player_focusing: bool = false # Updated via GameManager

@onready var mesh: Node3D = get_node_or_null("MeshInstance3D")

# ─── Base Transform Safety ────────────────────────────────────────────────────
var _base_position: Vector3
var _base_rotation: Vector3
var _base_scale: Vector3

var _breath_tween: Tween
var _jitter_timer: float = 0.0
var _jitter_cooldown: float = 0.0

# ─── Memory Violation Buffer ──────────────────────────────────────────────────
var _state_history: Array = []
const HISTORY_LIMIT := 5

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("patient")
	collision_layer = 4 # Interaction Layer (3)
	
	if mesh:
		_base_position = mesh.position
		_base_rotation = mesh.rotation
		_base_scale = mesh.scale
	
	_jitter_cooldown = randf_range(3.0, 6.0)


func _process(delta: float) -> void:
	_process_micro_jitter(delta)


# ─── Anomaly Control ──────────────────────────────────────────────────────────

func apply_anomaly(type: String, intensity_mult: float = 1.0) -> void:
	clear_anomaly() # Fresh start
	
	is_anomalous = true
	anomaly_type = type

	if not mesh: return

	# Tuning: Horror Heuristics (Subtle doubt)
	match type:
		"tilt":
			# Correct: 8-12 degrees, scaled by intensity
			mesh.rotation_degrees.z = _base_rotation.z + (randf_range(8.0, 12.0) * intensity_mult)
		"breath":
			_start_breathing(intensity_mult)
		"shift":
			# Correct: 0.04 - 0.12 units, scaled by intensity
			mesh.position.x = _base_position.x + (randf_range(0.04, 0.12) * intensity_mult)
	
	_record_state()


func clear_anomaly(is_unreliable: bool = false) -> void:
	is_anomalous = false
	anomaly_type = ""

	if _breath_tween:
		_breath_tween.kill()
		_breath_tween = null

	if mesh:
		if is_unreliable:
			# Unreliable Reset: Don't fully return to base (leave 30% distortion)
			mesh.position = lerp(mesh.position, _base_position, 0.7)
			mesh.rotation = lerp(mesh.rotation, _base_rotation, 0.7)
			mesh.scale = lerp(mesh.scale, _base_scale, 0.7)
		else:
			mesh.position = _base_position
			mesh.rotation = _base_rotation
			mesh.scale = _base_scale
			
	_record_state()


# ─── Internal Animations ──────────────────────────────────────────────────────

func _process_micro_jitter(delta: float) -> void:
	# Psychological Jitter: only when NOT looking, on a cooldown
	if is_player_focusing:
		return
		
	_jitter_timer += delta
	if _jitter_timer >= _jitter_cooldown:
		_jitter_timer = 0.0
		_jitter_cooldown = randf_range(3.0, 6.0)
		
		# Only 5% chance per cooldown window to jitter
		if randf() < 0.05:
			_apply_micro_jitter()


func _apply_micro_jitter() -> void:
	if not mesh: return
	var jitter = randf_range(-0.015, 0.015)
	var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(mesh, "position:x", mesh.position.x + jitter, 0.1)
	tween.tween_property(mesh, "position:x", mesh.position.x, 0.1)


func _start_breathing(intensity_mult: float = 1.0) -> void:
	if not mesh: return
	if _breath_tween: _breath_tween.kill()
		
	_breath_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	# Tuning: 1.02-1.04 (Almost imperceptible), scaled by intensity
	var breath_intensity = 1.0 + ((randf_range(1.02, 1.04) - 1.0) * intensity_mult)
	var breath_speed = randf_range(1.4, 2.0)
	
	_breath_tween.tween_property(mesh, "scale", _base_scale * breath_intensity, breath_speed)
	_breath_tween.tween_property(mesh, "scale", _base_scale, breath_speed)


func has_visible_anomaly() -> bool:
	return is_anomalous


func restore_previous_state() -> void:
	if _state_history.size() < 2:
		return
	
	# Memory Violation: Revert to a random historical state, NOT the base
	var state = _state_history.pick_random()
	if not mesh: return
	
	mesh.position = state.position
	mesh.rotation = state.rotation
	mesh.scale = state.scale
	print("[Patient] Memory Violation: Restored historical state for ", name)


func _record_state() -> void:
	if not mesh: return
	
	var state = {
		"position": mesh.position,
		"rotation": mesh.rotation,
		"scale": mesh.scale
	}
	
	_state_history.append(state)
	if _state_history.size() > HISTORY_LIMIT:
		_state_history.pop_front()
