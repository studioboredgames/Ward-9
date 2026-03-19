extends Node
## reality_distorter.gd (Phase 8)
## Responsibility: Environmental reality bleed effects (time-scale glitches, audio).

func _ready() -> void:
	add_to_group("reality_distorter")


func trigger_visual_glitch() -> void:
	if randf() < 0.1:
		print("[RealityDistorter] Visual Glitch: Time Dilation.")
		Engine.time_scale = 0.95
		await get_tree().create_timer(0.1).timeout
		Engine.time_scale = 1.0


func trigger_audio_event() -> void:
	if randf() < 0.1:
		print("[RealityDistorter] Distant sound triggered.")
		# Note: Audio integration would happen via EventManager/AudioStreamPlayer3D
