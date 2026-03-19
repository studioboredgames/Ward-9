extends Node
## player_model.gd (Phase 9)
## Responsibility: Model player behavioral traits for better psychological targeting.

var avg_speed := 0.0

func _ready() -> void:
	add_to_group("player_model")


func update_traits(profile: Dictionary) -> void:
	avg_speed = profile.get("avg_decision_time", 0.0)
	print("[PlayerModel] Characteristics Updated: Avg Speed = ", avg_speed)
