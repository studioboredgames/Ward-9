extends Node
## evaluation_manager.gd
## Responsibility: Judges player behavior and produces evaluation states.
## Emits evaluation_updated signal to drive horror scaling in event_manager.

# ─── Signals ──────────────────────────────────────────────────────────────────

## Emitted when evaluation state changes.
## Direct subscriber: event_manager (allowed reactive exception).
signal evaluation_updated(state: String, cycle_id: int)

# ─── Configuration ────────────────────────────────────────────────────────────

@export var suspicion_threshold: int = 2
@export var failure_threshold: int = 4

# ─── Public State ─────────────────────────────────────────────────────────────

enum State { STABLE, SUSPICIOUS, FAILED }
var current_state: State = State.STABLE

# ─── Private State ────────────────────────────────────────────────────────────

var _mistakes_made: int = 0
var _player_behavior_log: Array[Dictionary] = []

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("evaluation_manager")

# ─── Public API ───────────────────────────────────────────────────────────────

## Called by game_manager after cycle_end + delay (now context-rich).
func log_decision(decision: String, cycle_id: int, patient: Node = null) -> void:
	# Cross-reference decision with actual anomaly state
	var is_correct = _verify_correctness(decision, patient)
	
	var entries = {
		"cycle_id": cycle_id,
		"decision": decision,
		"correct": is_correct,
		"timestamp": Time.get_ticks_msec()
	}
	_player_behavior_log.append(entries)
	
	if not is_correct:
		_mistakes_made += 1
		_update_state(cycle_id)
	else:
		# Even if correct, patterns like high speed or hesitation 
		# can be evaluated here to shift state to SUSPICIOUS.
		pass


func get_state_string() -> String:
	match current_state:
		State.STABLE: return "stable"
		State.SUSPICIOUS: return "suspicious"
		State.FAILED: return "failed"
	return "stable"

# ─── Internal ─────────────────────────────────────────────────────────────────

func _verify_correctness(decision: String, _target_patient: Node) -> bool:
	# Check for ANY anomaly in the ward
	var patients = get_tree().get_nodes_in_group("patient")
	var ward_anomalous = false
	for p in patients:
		if p.is_anomalous():
			ward_anomalous = true
			break
	
	# Logic:
	# "All Normal" is ONLY correct if ZERO patients are anomalous.
	if decision == "all_normal":
		return not ward_anomalous
		
	# "Something Wrong" is correct if ANYONE is anomalous,
	# but we can optionally check if the player was focused on THE anomaly.
	if decision == "something_wrong":
		# For harder evaluation: check if target_patient == anomaly
		return ward_anomalous
		
	return false


func _update_state(cycle_id: int) -> void:
	var prev_state = current_state
	
	if _mistakes_made >= failure_threshold:
		current_state = State.FAILED
	elif _mistakes_made >= suspicion_threshold:
		current_state = State.SUSPICIOUS
	else:
		current_state = State.STABLE
		
	if current_state != prev_state:
		emit_signal("evaluation_updated", get_state_string(), cycle_id)
