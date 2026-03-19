extends Node
## input_distorter.gd (Phase 10)
## Responsibility: Simulated perceptual lag on player inputs.

func _ready() -> void:
	add_to_group("input_distorter")


func process_input_delay() -> void:
	if randf() < 0.1:
		var delay = randf_range(0.05, 0.15)
		print("[InputDistorter] Injecting input lag: ", delay, "s")
		await get_tree().create_timer(delay).timeout
