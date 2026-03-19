extends CharacterBody3D
## player_controller.gd
## Responsibility: First-person movement and camera.
## Does NOT handle interaction, decisions, or game state.
## Signals upward to game_manager via input only.

# ─── Configuration ────────────────────────────────────────────────────────────

@export var move_speed: float = 3.0          ## Walking speed (m/s)
@export var mouse_sensitivity: float = 0.002 ## Radians per pixel

# ─── Node References ──────────────────────────────────────────────────────────

@onready var camera: Camera3D = $Camera3D

# ─── Private State ────────────────────────────────────────────────────────────

var _movement_enabled: bool = true
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("player")
	camera.add_to_group("player_camera")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	# Escape toggles mouse capture — essential for editor/debug sessions.
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _movement_enabled:
		# Only rotate when captured; ignore mouse movement while free.
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		# Horizontal look — rotate the whole body.
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical look — rotate only the camera, clamped.
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(
			camera.rotation.x,
			deg_to_rad(-75.0),
			deg_to_rad(75.0)
		)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	if _movement_enabled:
		_apply_movement()
	move_and_slide()

# ─── Public API ───────────────────────────────────────────────────────────────

## Called by phase_manager to lock/unlock player movement during transitions.
func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	if not enabled:
		velocity.x = 0.0
		velocity.z = 0.0


func trigger_ending_pose() -> void:
	_movement_enabled = false
	print("[Player] Transitioning to ENDING POSE")
	
	# Perspective Shift: Player has the red wristband
	# We'll create a simple visual on the camera's viewport
	var wristband = ColorRect.new()
	wristband.color = Color.RED
	wristband.custom_minimum_size = Vector2(100, 20)
	wristband.position = Vector2(50, 400) # Bottom left-ish
	wristband.rotation_degrees = 45
	get_tree().get_first_node_in_group("decision_ui").get_parent().add_child(wristband)

	# Look down at the wristband
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "rotation:x", deg_to_rad(-60), 2.0)
	tween.tween_property(camera, "position:y", 1.0, 2.0) # Laying down
	
	# Final Abrupt Statement
	await get_tree().create_timer(3.0).timeout
	print("[SYSTEM] ENDING: PATIENT ID #000 - ATTENDANT_01")

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0


func _apply_movement() -> void:
	var input_dir := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	# Input.get_vector() already returns a normalized vector for diagonal input.
	# Applying .normalized() again after basis transform is redundant and can
	# produce subtle floating-point drift on diagonal movement.
	var direction := transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	if direction.length_squared() > 0.0:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
