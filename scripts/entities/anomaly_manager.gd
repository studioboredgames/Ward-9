extends Node
## anomaly_manager.gd
## Responsibility: Assign observable anomalies to patients per cycle.
## Phase-driven, deterministic selection with light variation.

# ─── Configuration ────────────────────────────────────────────────────────────

@export var patients: Array[Node] = []

# phase → max anomalies
var _phase_budget := {
	"shift_start": 1,
	"midnight": 2,
	"pre_dawn": 3
}

var _current_phase: String = "shift_start"
var _rng := RandomNumberGenerator.new()

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_rng.randomize()
	# Defer patient lookup if not assigned
	if patients.is_empty():
		call_deferred("_populate_patients")


func _populate_patients() -> void:
	var nodes = get_tree().get_nodes_in_group("patient")
	for n in nodes:
		patients.append(n)

# ─── Hooks from game_manager ──────────────────────────────────────────────────

func handle_phase_shift(phase_name: String) -> void:
	_current_phase = phase_name


func prepare_cycle(cycle_id: int) -> void:
	_clear_all()
	var budget : int = _phase_budget.get(_current_phase, 1)

	# Deterministic shuffle per cycle using cycle ID as seed component
	_rng.seed = hash(str(cycle_id) + _current_phase)
	var pool := patients.duplicate()
	pool.shuffle()

	for i in range(min(budget, pool.size())):
		_apply_anomaly(pool[i], cycle_id, i)


func cleanup_cycle(_cycle_id: int) -> void:
	# Optional: decay transient effects or close horror gates
	pass

# ─── Internal ─────────────────────────────────────────────────────────────────

func _clear_all() -> void:
	for p in patients:
		if p.has_method("clear_anomaly"):
			p.clear_anomaly()


func _apply_anomaly(patient: Node, cycle_id: int, slot: int) -> void:
	if not patient.has_method("set_anomaly_state"):
		return

	# Deterministic variant selection based on cycle and slot
	var variant := int(abs(hash(str(cycle_id) + str(slot))) % 3)

	var data := {
		"type": "visual",
		"variant": variant,
		"intensity": _phase_intensity()
	}

	patient.set_anomaly_state(data)


func _phase_intensity() -> float:
	match _current_phase:
		"shift_start": return 0.3
		"midnight": return 0.6
		"pre_dawn": return 1.0
	return 0.3
