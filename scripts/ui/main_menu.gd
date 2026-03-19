extends Control
## main_menu.gd
## Responsibility: Provide a clinical, minimal entry point to the game.

signal play_pressed

@onready var play_btn: Button = $VBoxContainer/PlayButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton
@onready var exit_btn: Button = $VBoxContainer/ExitButton
@onready var discord_btn: Button = $VBoxContainer/DiscordButton

func _ready() -> void:
	add_to_group("main_menu")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	play_btn.pressed.connect(_on_play)
	settings_btn.pressed.connect(_on_settings)
	exit_btn.pressed.connect(_on_exit)
	discord_btn.pressed.connect(_on_discord)


func _on_settings() -> void:
	# Toggle Subtitles
	var sm = get_tree().get_first_node_in_group("subtitle_manager")
	if sm:
		sm.enabled = not sm.enabled
		settings_btn.text = "SUBTITLES: " + ("ON" if sm.enabled else "OFF")

func _on_play() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	emit_signal("play_pressed")
	hide()

func _on_discord() -> void:
	OS.shell_open("https://discord.gg/boredgamesstudio")

func _on_exit() -> void:
	get_tree().quit()
