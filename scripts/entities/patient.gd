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
var _is_lingering: bool = false
var _is_eye_lagging: bool = false

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
	if _is_eye_lagging:
		_process_eye_lag()
	_process_breathing(delta)


# ─── Anomaly Control ──────────────────────────────────────────────────────────

func apply_anomaly(type: String, intensity: float = 1.0) -> void:
	clear_anomaly() # Fresh start
	
	is_anomalous = true
	anomaly_type = type
	current_anomaly = type
	_anomaly_intensity = intensity

	if not mesh: return

	# Tuning: Horror Heuristics (Subtle doubt)
	match type:
		"tilt":
			if mesh: mesh.rotation_degrees.z = 15.0 * intensity
		"breath":
			# Handled in _process
			pass
		"shift":
			if mesh: mesh.position.x += 0.05 * intensity
		"eye_lag":
			_is_eye_lagging = true
		"posture":
			if mesh: mesh.scale.y = 0.9 * intensity
			mesh.rotation_degrees.z = _base_rotation.z + (randf_range(8.0, 12.0) * intensity) # Corrected intensity_mult to intensity
	
	_record_state()


func clear_anomaly(is_unreliable: bool = false) -> void:
	if _is_lingering:
		_is_lingering = false
		print("[Patient] Anomaly lingering (Hallucination active). Skipping clear.")
		return
		
	is_anomalous = false
	anomaly_type = ""
	current_anomaly = "" # Clear current anomaly type
	_is_eye_lagging = false # Clear eye lag

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
	# This function is now deprecated as breathing is handled in _process_breathing
	# Keeping it for now in case it's still called elsewhere, but it won't do anything.
	pass


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


func _process_breathing(delta: float) -> void:
	if not mesh: return
	
	var speed = 2.0
	if current_anomaly == "breath":
		speed = 8.0 * _anomaly_intensity # Unnatural breathing desync
	
	_breath_time += delta * speed
	mesh.scale.y = 1.0 + (sin(_breath_time) * 0.01)

func _process_eye_lag() -> void:
	# Subtle eye/head lag: looks at player but with huge smoothing
	var player = get_tree().get_first_node_in_group("player")
	if player and mesh:
		var target_rot = mesh.global_transform.looking_at(player.global_position).basis.get_euler()
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_rot.y, 0.01)

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
