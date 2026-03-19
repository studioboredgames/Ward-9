extends Control
## main_menu.gd
## Responsibility: Provide a clinical, minimal entry point with tabbed settings.

signal play_pressed

@onready var main_container: VBoxContainer = $VBoxContainer
@onready var settings_container: VBoxContainer = $SettingsContainer
@onready var play_btn: Button = $VBoxContainer/PlayButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton

# Settings Buttons
@onready var video_btn: Button = $SettingsContainer/VideoButton
@onready var audio_btn: Button = $SettingsContainer/AudioButton
@onready var subtitle_btn: Button = $SettingsContainer/SubtitleButton
@onready var back_btn: Button = $SettingsContainer/BackButton

func _ready() -> void:
	add_to_group("main_menu")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	settings_container.hide()
	
	play_btn.pressed.connect(_on_play)
	settings_btn.pressed.connect(_on_toggle_settings.bind(true))
	back_btn.pressed.connect(_on_toggle_settings.bind(false))
	
	video_btn.pressed.connect(_on_video_pressed)
	audio_btn.pressed.connect(_on_audio_pressed)
	subtitle_btn.pressed.connect(_on_subtitle_pressed)
	
	$VBoxContainer/DiscordButton.pressed.connect(func(): OS.shell_open("https://discord.gg/boredgamesstudio"))
	$VBoxContainer/ExitButton.pressed.connect(func(): get_tree().quit())

func _on_play() -> void:
	emit_signal("play_pressed")
	hide()

func _on_toggle_settings(show: bool) -> void:
	main_container.visible = !show
	settings_container.visible = show

func _on_video_pressed() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		video_btn.text = "VIDEO: WINDOWED"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		video_btn.text = "VIDEO: FULLSCREEN"

func _on_audio_pressed() -> void:
	# Simple Master Volume Toggle for now
	var bus_idx = AudioServer.get_bus_index("Master")
	var muted = AudioServer.is_bus_mute(bus_idx)
	AudioServer.set_bus_mute(bus_idx, !muted)
	audio_btn.text = "AUDIO: " + ("MUTED" if !muted else "ON")

func _on_subtitle_pressed() -> void:
	var sm = get_tree().get_first_node_in_group("subtitle_manager")
	if sm:
		sm.enabled = !sm.enabled
		subtitle_btn.text = "SUBTITLES: " + ("ON" if sm.enabled else "OFF")
