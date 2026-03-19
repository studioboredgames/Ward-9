extends CanvasLayer
## subtitle_manager.gd
## Responsibility: Display stylized subtitles with a typewriter effect.
## inspired by "Fears to Fathom"

@onready var label: RichTextLabel = $SubtitleLabel
var enabled: bool = true

func _ready() -> void:
	add_to_group("subtitle_manager")
	if label: label.text = ""

func display_text(text: String, duration: float = 3.0) -> void:
	if not label or not enabled: return
	
	label.text = "[center]" + text + "[/center]"
	label.visible_ratio = 0.0
	
	var tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, 0.5) # Fast typewriter
	
	await get_tree().create_timer(duration).timeout
	
	var fade = create_tween()
	fade.tween_property(label, "modulate:a", 0.0, 0.5)
	await fade.finished
	label.text = ""
	label.modulate.a = 1.0
