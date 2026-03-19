extends Node
## game_manager.gd
## Responsibility: Central signal router and system connector.
## Strictly follows "one-directional" flow: receives reports, fans out commands.
## Contains ONLY minimal transit memory; no complex phase or gameplay logic.

# ─── Transit Memory (Minimal) ────────────────────────────────────────────────

var last_decision: String = ""   ## "all_normal" | "something_wrong"
var last_cycle_id: int = -1      ## Mirrors phase_manager's current cycle

# ─── Node References (Core Systems) ──────────────────────────────────────────

@onready var phase_manager: Node = $PhaseManager
@onready var anomaly_manager: Node = $AnomalyManager
@onready var evaluation_manager: Node = $EvaluationManager
@onready var event_manager: Node = $EventManager
@onready var interaction_system: Node = get_tree().get_first_node_in_group("interaction_system")
@onready var decision_ui: Control = get_tree().get_first_node_in_group("decision_ui")

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Add to group for easier lookup if needed, though this is the root typically.
	add_to_group("game_manager")
	_connect_signals()

# ─── Signal Routing (Fan-In) ─────────────────────────────────────────────────

func _connect_signals() -> void:
	# From Phase Manager
	phase_manager.cycle_started.connect(_on_cycle_started)
	phase_manager.cycle_ended.connect(_on_cycle_ended)
	phase_manager.phase_changed.connect(_on_phase_changed)
	
	# From Interaction System
	if interaction_system:
		interaction_system.decision_window_opened.connect(_on_decision_window_opened)
	
	# From Decision UI
	if decision_ui:
		decision_ui.decision_submitted.connect(_on_decision_submitted)
	
	# From Evaluation Manager
	evaluation_manager.evaluation_updated.connect(_on_evaluation_updated)

# ─── Fan-Out Handlers ────────────────────────────────────────────────────────

func _on_cycle_started(cycle_id: int) -> void:
	last_cycle_id = cycle_id
	# Command anomaly_manager to refresh world for new cycle
	anomaly_manager.prepare_cycle(cycle_id)
	# Enable player interaction
	if interaction_system:
		interaction_system.enable()


func _on_cycle_ended(cycle_id: int) -> void:
	# Disable interaction immediately
	if interaction_system:
		interaction_system.disable()
	
	# Force close UI if still open
	if decision_ui:
		decision_ui.force_close()
	
	# Report results to evaluation_manager after short delay (per spec)
	var timer := get_tree().create_timer(randf_range(0.3, 0.5))
	await timer.timeout
	evaluation_manager.log_decision(last_decision, cycle_id)


func _on_phase_changed(phase_name: String) -> void:
	# Inform systems of phase shift (for atmospheric changes, etc.)
	event_manager.handle_phase_shift(phase_name)
	anomaly_manager.handle_phase_shift(phase_name)


func _on_decision_window_opened(patient: Node) -> void:
	# Show UI
	if decision_ui:
		decision_ui.display_for_patient(patient)


func _on_decision_submitted(decision: String) -> void:
	last_decision = decision
	# Acknowledge back to interaction system to unlock its internal gate
	if interaction_system:
		interaction_system.acknowledge_decision()
	
	# Trigger phase_manager to wrap up the cycle
	phase_manager.complete_current_cycle()


func _on_evaluation_updated(state: String, cycle_id: int) -> void:
	# Event manager reacts to the player's performance
	event_manager.process_evaluation(state, cycle_id)
