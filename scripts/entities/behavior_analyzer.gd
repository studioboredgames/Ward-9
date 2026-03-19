extends Node
## behavior_analyzer.gd (Phase 6)
## Tracks focus patterns and recent targets to identify unobserved patients.

var focus_counts := {}
var last_targets := []

func _ready() -> void:
	add_to_group("behavior_analyzer")


func record_focus(patient: Node) -> void:
	focus_counts[patient] = focus_counts.get(patient, 0) + 1
	last_targets.append(patient)
	if last_targets.size() > 5:
		last_targets.pop_front()


func get_least_observed(patients: Array) -> Node:
	var min_val = INF
	var target = null
	
	for p in patients:
		var v = focus_counts.get(p, 0)
		if v < min_val:
			min_val = v
			target = p
	
	return target
