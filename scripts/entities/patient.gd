extends CharacterBody3D
## patient.gd
## Responsibility: Authority for rendered truth of the patient (visuals).
## Subtle, uncomfortable cues using safe transform resets.

var is_anomalous: bool = false
var anomaly_type: String = ""

@onready var mesh: Node3D = get_node_or_null("MeshInstance3D")

# ─── Base Transform Safety ────────────────────────────────────────────────────
var _base_position: Vector3
var _base_rotation: Vector3
var _base_scale: Vector3

var _breath_tween: Tween

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("patient")
	collision_layer = 4 # Interaction Layer (3)
	
	if mesh:
		_base_position = mesh.position
		_base_rotation = mesh.rotation
		_base_scale = mesh.scale


# ─── Anomaly Control ──────────────────────────────────────────────────────────

func apply_anomaly(type: String) -> void:
	# Defensive: Always clear before applying to prevent stacking
	clear_anomaly()
	
	is_anomalous = true
	anomaly_type = type

	if not mesh: return

	# Tuning: Horror Heuristics (Subtle > Obvious)
	match type:
		"tilt":
			# Correct: 8-12 degrees (Subtle doubt)
			mesh.rotation_degrees.z = _base_rotation.z + 10.0
		"breath":
			_start_breathing()
		"shift":
			# Correct: 0.05-0.12 units
			mesh.position.x = _base_position.x + 0.08


func clear_anomaly() -> void:
	is_anomalous = false
	anomaly_type = ""

	if _breath_tween:
		_breath_tween.kill()
		_breath_tween = null

	if mesh:
		# Structural Fix: Reset to authoritative base, not 0,0,0
		mesh.position = _base_position
		mesh.rotation = _base_rotation
		mesh.scale = _base_scale


# ─── Internal Animations ──────────────────────────────────────────────────────

func _start_breathing() -> void:
	if not mesh: return
	
	# Defensive: Kill existing tween to prevent scale stacking
	if _breath_tween:
		_breath_tween.kill()
		
	_breath_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	# Tuning: 1.02-1.04 (Almost imperceptible)
	var target_scale = _base_scale * 1.03
	_breath_tween.tween_property(mesh, "scale", target_scale, 1.5)
	_breath_tween.tween_property(mesh, "scale", _base_scale, 1.5)


# ─── Contract for Evaluation ──────────────────────────────────────────────────

func has_visible_anomaly() -> bool:
	return is_anomalous
