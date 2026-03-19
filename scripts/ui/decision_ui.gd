extends Control
## decision_ui.gd
## Responsibility: Display "All Normal" / "Something Wrong" prompt.
## Reports choice UPWARD to game_manager via signal.
## Hide/Show logic is command-driven (via game_manager or phase_manager).

# ─── Signals ──────────────────────────────────────────────────────────────────

## Emitted when player clicks a choice.
## Listener: game_manager
signal decision_submitted(result: String)

# ─── Node References ──────────────────────────────────────────────────────────

@onready var prompt_container: Control = $PromptContainer
@onready var normal_button: Button = $PromptContainer/NormalButton
@onready var anomaly_button: Button = $PromptContainer/AnomalyButton

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("decision_ui")
	# Start hidden
	hide()
	
	normal_button.pressed.connect(_on_choice_pressed.bind("all_normal"))
	anomaly_button.pressed.connect(_on_choice_pressed.bind("something_wrong"))

# ─── Public API (called by game_manager) ──────────────────────────────────────

## Displays the UI when player has dwelled on a patient.
func display_for_patient(_patient: Node) -> void:
	# Show mouse for selection
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()


## Phase manager's hard guarantee to clear the screen during transitions.
func force_close() -> void:
	hide()
	# Only re-capture if we aren't already in a transition (handled by controller usually)
	# but for pure UI cleanup:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ─── Internal ─────────────────────────────────────────────────────────────────

func _on_choice_pressed(choice: String) -> void:
	emit_signal("decision_submitted", choice)
	# Capture mouse again after decision
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()
