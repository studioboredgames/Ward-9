extends Node
## truth_instability.gd (Phase 7)
## Occasionally inverts the evaluation of player performance.

var inversion_chance := 0.15

func _ready() -> void:
	add_to_group("truth_instability")


func evaluate(actual: bool) -> bool:
	if randf() < inversion_chance:
		print("[TruthInstability] INVERTING result.")
		return not actual
	
	return actual
