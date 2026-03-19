extends Node
## interaction_system.gd
## Responsibility: Raycast-based patient focus detection.
## Manages dwell timer, target-switch guard, and decision window gate.
## Reports only upward → game_manager via signal.
## interaction_enabled is controlled exclusively by phase_manager.

# ─── Signals ──────────────────────────────────────────────────────────────────

## Emitted when the player has dwelled on a patient long enough to decide.
## Listener: game_manager → shows decision_ui.
signal decision_window_opened(patient: Node)

# ─── Configuration ────────────────────────────────────────────────────────────

@export_group("Raycast")
@export var ray_length: float = 3.0
@export_node_path("Camera3D") var camera_path: NodePath
## Collision layer mask for patient physics bodies.
## Patients must be assigned to the matching layer in the Godot inspector.
## Default: layer 3 (bit index 2). Change here if your setup differs.
@export_flags_3d_physics var patient_collision_mask: int = 0b100

@export_group("Dwell Timing")
@export var dwell_threshold_min: float = 0.6
@export var dwell_threshold_max: float = 0.9
@export var switch_grace_window: float = 0.2

@export_group("Visuals")
@export var crosshair_group: String = "crosshair"
@export var target_color: Color = Color(1, 0.2, 0.2, 0.8) # Subtle red when targeting
@export var normal_color: Color = Color(1, 1, 1, 0.5)

# ─── Public State (read-only outside this node) ───────────────────────────────

var interaction_enabled: bool = false  ## Set exclusively by phase_manager
var decision_window_active: bool = false

# ─── Private State ────────────────────────────────────────────────────────────

var _dwell_timer: float = 0.0
var _dwell_threshold: float = 0.75  ## Randomized each trigger
var _current_target: Node = null
var _camera: Camera3D
var _crosshair: ColorRect
## Grace window: brief period after losing sight before dwell fully resets.
var _lost_target_timer: float = 0.0


# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	randomize()
	add_to_group("interaction_system")
	_setup_camera()
	_setup_crosshair()
	_reset_dwell()


func _physics_process(delta: float) -> void:
	if not interaction_enabled or decision_window_active:
		return

	var hit_patient := _raycast()

	if hit_patient:
		_process_patient_hit(hit_patient, delta)
	else:
		_process_miss()

# ─── Public API (called by phase_manager) ─────────────────────────────────────

## Enable interaction at cycle_start.
func enable() -> void:
	interaction_enabled = true


## Disable interaction at cycle_end or during transitions.
## Does not close the UI — phase_manager calls force_close() for that.
func disable() -> void:
	interaction_enabled = false
	_reset_dwell()


## Called by phase_manager at cycle_end to guarantee the window is closed.
## The UI node itself does not decide when to hide.
func force_close_decision_window() -> void:
	decision_window_active = false
	_reset_dwell()


## Called by decision_ui (via game_manager) after the player has submitted
## their choice, to unlock the system for the next cycle.
func acknowledge_decision() -> void:
	decision_window_active = false
	_reset_dwell()

# ─── Internal ─────────────────────────────────────────────────────────────────

func _setup_camera() -> void:
	# Resolve camera from exported NodePath if set; fall back to group search.
	if camera_path and not camera_path.is_empty():
		_camera = get_node(camera_path)
	else:
		var cameras := get_tree().get_nodes_in_group("player_camera")
		if cameras.size() > 0:
			_camera = cameras[0]
			if cameras.size() > 1:
				push_warning("interaction_system: multiple nodes in 'player_camera' — using first. Set camera_path export instead.")
		else:
			push_error("interaction_system: no node in group 'player_camera' found. Set the camera_path export property.")


func _setup_crosshair() -> void:
	_crosshair = get_tree().get_first_node_in_group(crosshair_group) as ColorRect


func _raycast() -> Node:
	if _camera == null:
		return null

	var space_state := _camera.get_world_3d().direct_space_state
	var origin := _camera.global_position
	var forward := -_camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + forward * raycast_distance
	)
	# Only test against the patient collision layer.
	# Walls, beds, and props on other layers are ignored,
	# preventing the ray from triggering on geometry in front of a patient.
	query.collision_mask = patient_collision_mask

	# Exclude the player's own collision body.
	var player_nodes := get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		query.exclude = [player_nodes[0].get_rid()]

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("collider")


func _trigger_decision_window() -> void:
	# Null guard: if desync has cleared the target, abort silently.
	if _current_target == null:
		return
	decision_window_active = true
	_randomize_dwell_threshold()  # Re-randomize for next trigger
	emit_signal("decision_window_opened", _current_target)


func _reset_dwell() -> void:
	_dwell_timer = 0.0
	_lost_target_timer = 0.0
	_current_target = null


func _randomize_dwell_threshold() -> void:
	_dwell_threshold = randf_range(dwell_min, dwell_max)
