extends Node
## truth_instability.gd (Phase 7)
## Occasionally inverts the evaluation of player performance.

var inversion_chance := 0.15
var active_this_cycle := false

func _ready() -> void:
	add_to_group("truth_instability")


func evaluate(actual: bool) -> bool:
	if active_this_cycle:
		active_this_cycle = false
		print("[TruthInstability] DELAYED CONSEQUENCE: Inverting result.")
		return not actual
		
	if randf() < inversion_chance:
		print("[TruthInstability] INVERTING result.")
		return not actual
	
	return actual
