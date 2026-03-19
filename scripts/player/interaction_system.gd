extends Node
## interaction_system.gd
## Responsibility: Raycast-based patient focus detection and duration tracking.
## Signals focus-enter/exit events to drive behavior profiling.

# ─── Signals ──────────────────────────────────────────────────────────────────

signal patient_focus_entered(patient: Node)
signal patient_focus_exited(patient: Node)
signal focus_ended(patient: Node, duration: float)
signal decision_window_opened(patient: Node)
signal decision_window_closed

# ─── Configuration ────────────────────────────────────────────────────────────

@export_group("Raycast")
@export var ray_length: float = 3.2
@export_node_path("Camera3D") var camera_path: NodePath
@export_flags_3d_physics var patient_collision_mask: int = 0b100

@export_group("Dwell Timing")
@export var dwell_threshold_min: float = 0.5
@export var dwell_threshold_max: float = 0.8
@export var switch_grace_window: float = 0.2

@export_group("Visuals")
@export var crosshair_group: String = "crosshair"
@export var target_color: Color = Color(1, 0.2, 0.2, 0.8)
@export var normal_color: Color = Color(1, 1, 1, 0.5)

# ─── Internal State ───────────────────────────────────────────────────────────

var interaction_enabled: bool = false
var decision_window_active: bool = false

var _dwell_timer: float = 0.0
var _dwell_threshold: float = 0.7
var _current_target: Node = null
var _last_hit_patient: Node = null

var _camera: Camera3D
var _crosshair: ColorRect
var _lost_target_timer: float = 0.0

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	randomize()
	add_to_group("interaction_system")
	_setup_camera()
	_setup_crosshair()
	_reset_dwell()


func _input(event: InputEvent) -> void:
	if not interaction_enabled or decision_window_active: return
	
	# Manual "E" interaction fallback
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		var hit = _raycast()
		if hit:
			_current_target = hit
			_trigger_decision_window()


func _physics_process(delta: float) -> void:
	if not interaction_enabled or decision_window_active:
		_update_crosshair_visuals(false)
		_process_miss(delta) # Ensure focus-exit fires even when disabled
		return

	var hit_patient := _raycast()
	_handle_focus_signals(hit_patient)

	if hit_patient:
		_process_patient_hit(hit_patient, delta)
	else:
		_process_miss(delta)


# ─── Reactive API (Target for Router Signals) ─────────────────────────────────

func enable_interaction(_id: int = 0) -> void:
	interaction_enabled = true


func disable_interaction(_id: int = 0) -> void:
	interaction_enabled = false
	_reset_dwell()
	_handle_focus_signals(null)
	_update_crosshair_visuals(false)


func acknowledge_decision() -> void:
	decision_window_active = false
	_reset_dwell()
	_handle_focus_signals(null)
	emit_signal("decision_window_closed")

# ─── Internal ─────────────────────────────────────────────────────────────────

func _handle_focus_signals(new_hit: Node) -> void:
	if new_hit == _last_hit_patient:
		return
		
	if _last_hit_patient != null:
		if _last_hit_patient.has_meta("focus_start_time"):
			var duration = (Time.get_ticks_msec() - _last_hit_patient.get_meta("focus_start_time")) / 1000.0
			emit_signal("focus_ended", _last_hit_patient, duration)
		emit_signal("patient_focus_exited", _last_hit_patient)
	
	if new_hit != null:
		emit_signal("patient_focus_entered", new_hit)
		
	_last_hit_patient = new_hit


func _setup_camera() -> void:
	if camera_path and not camera_path.is_empty():
		_camera = get_node(camera_path)
	else:
		_camera = get_tree().get_first_node_in_group("player_camera")


func _setup_crosshair() -> void:
	_crosshair = get_tree().get_first_node_in_group(crosshair_group) as ColorRect


func _raycast() -> Node:
	if not _camera: return null
	var space_state := _camera.get_world_3d().direct_space_state
	var origin := _camera.global_position
	var forward := -_camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * ray_length)
	query.collision_mask = patient_collision_mask
	var result := space_state.intersect_ray(query)
	
	if result.is_empty(): return null
	
	var collider = result.get("collider")
	if collider and collider.is_in_group("patient"):
		return collider
	return null


func _process_patient_hit(patient: Node, delta: float) -> void:
	_update_crosshair_visuals(true)
	
	if patient != _current_target:
		_lost_target_timer += delta
		if _lost_target_timer > switch_grace_window:
			_reset_dwell()
			_current_target = patient
			_lost_target_timer = 0.0
	else:
		_lost_target_timer = 0.0
		_dwell_timer += delta

	if _dwell_timer >= _dwell_threshold and not decision_window_active:
		_trigger_decision_window()


func _process_miss(delta: float) -> void:
	_update_crosshair_visuals(false)
	if _current_target != null:
		_lost_target_timer += delta
		if _lost_target_timer > switch_grace_window:
			_reset_dwell()


func _update_crosshair_visuals(is_targeting: bool) -> void:
	if not _crosshair: return
	_crosshair.color = target_color if is_targeting else normal_color
	_crosshair.scale = Vector2(1.5, 1.5) if is_targeting else Vector2(1.0, 1.0)
	_crosshair.pivot_offset = _crosshair.size / 2


func _trigger_decision_window() -> void:
	if _current_target == null: return
	decision_window_active = true
	_randomize_dwell_threshold()
	emit_signal("decision_window_opened", _current_target)


func _reset_dwell() -> void:
	_dwell_timer = 0.0
	_lost_target_timer = 0.0
	_current_target = null


func _randomize_dwell_threshold() -> void:
	_dwell_threshold = randf_range(dwell_threshold_min, dwell_threshold_max)
