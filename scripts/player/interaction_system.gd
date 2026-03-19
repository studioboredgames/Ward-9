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

@export var raycast_distance: float = 3.0  ## Max patient detection range (m)
@export var dwell_min: float = 0.6         ## Minimum dwell threshold (s)
@export var dwell_max: float = 0.9         ## Maximum dwell threshold (s)
## NodePath to Camera3D set in the inspector — avoids fragile group lookup.
@export var camera_path: NodePath
## Collision layer mask for patient physics bodies.
## Patients must be assigned to the matching layer in the Godot inspector.
## Default: layer 3 (bit index 2). Change here if your setup differs.
@export_flags_3d_physics var patient_collision_mask: int = 0b100

# ─── Public State (read-only outside this node) ───────────────────────────────

var interaction_enabled: bool = false  ## Set exclusively by phase_manager
var decision_window_active: bool = false

# ─── Private State ────────────────────────────────────────────────────────────

var _dwell_timer: float = 0.0
var _dwell_threshold: float = 0.75  ## Randomized each trigger
var _current_target: Node = null
var _camera: Camera3D = null
## Grace window: brief period after losing sight before dwell fully resets.
var _lost_target_timer: float = 0.0
var _lost_target_grace: float = 0.2

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	randomize()  # Ensure non-deterministic dwell sequence every run.
	_randomize_dwell_threshold()
	# Resolve camera from exported NodePath if set; fall back to group search.
	if camera_path and not camera_path.is_empty():
		_camera = get_node(camera_path)
	else:
		call_deferred("_find_camera")


func _physics_process(delta: float) -> void:
	if not interaction_enabled or decision_window_active:
		return

	var hit := _raycast()

	if hit != null and hit.is_in_group("patient"):
		if hit == _current_target:
			# On-target: reset grace timer; accumulate dwell.
			_lost_target_timer = 0.0
			_dwell_timer += delta
		else:
			# Different patient: use grace window before switching.
			_lost_target_timer += delta
			if _lost_target_timer > _lost_target_grace:
				_reset_dwell()
				_current_target = hit
				_lost_target_timer = 0.0

		# Defensive double-check: guard against same-frame desync.
		if _dwell_timer >= _dwell_threshold and not decision_window_active:
			_trigger_decision_window()
	else:
		# Off all patients: accumulate grace before full reset.
		_lost_target_timer += delta
		if _lost_target_timer > _lost_target_grace:
			_reset_dwell()

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

func _find_camera() -> void:
	var cameras := get_tree().get_nodes_in_group("player_camera")
	if cameras.size() > 0:
		_camera = cameras[0]
		if cameras.size() > 1:
			push_warning("interaction_system: multiple nodes in 'player_camera' — using first. Set camera_path export instead.")
	else:
		push_error("interaction_system: no node in group 'player_camera' found. Set the camera_path export property.")


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
