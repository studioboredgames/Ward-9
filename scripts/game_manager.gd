extends Node
## game_manager.gd
## Responsibility: Central signal router and system connector.
## Stores minimal transit memory; contains NO game logic or state decisions.

# ─── Transit Memory ───────────────────────────────────────────────────────────

var last_decision: String = ""
var last_cycle_id: int = 0

# ─── Node References ──────────────────────────────────────────────────────────

@onready var phase_manager: Node = $PhaseManager
@onready var anomaly_manager: Node = $AnomalyManager
@onready var evaluation_manager: Node = $EvaluationManager
@onready var event_manager: Node = $EventManager

# These are gathered from groups to avoid tight coupling to the scene tree structure
@onready var interaction_system: Node = get_tree().get_first_node_in_group("interaction_system")
@onready var decision_ui: Control = get_tree().get_first_node_in_group("decision_ui")

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_connect_signals()


func _connect_signals() -> void:
	# From phase_manager
	phase_manager.cycle_started.connect(_on_cycle_started)
	phase_manager.cycle_ended.connect(_on_cycle_ended)
	phase_manager.phase_changed.connect(_on_phase_changed)
	
	# From decision_ui
	if decision_ui:
		decision_ui.decision_submitted.connect(_on_decision_submitted)
	
	# From interaction_system
	if interaction_system:
		interaction_system.decision_window_opened.connect(_on_decision_window_opened)

# ─── Signal Routing (Fan-Out) ─────────────────────────────────────────────────

func _on_cycle_started(cycle_id: int) -> void:
	last_cycle_id = cycle_id
	
	# Forward to dependent systems
	if anomaly_manager:
		anomaly_manager.prepare_cycle(cycle_id)
		
	if interaction_system:
		interaction_system.enable()


func _on_cycle_ended(cycle_id: int) -> void:
	# Forward to dependent systems
	if interaction_system:
		interaction_system.disable()
	
	if evaluation_manager:
		evaluation_manager.log_decision(last_decision, cycle_id)


func _on_phase_changed(phase_name: String) -> void:
	if anomaly_manager:
		anomaly_manager.handle_phase_shift(phase_name)
		
	if event_manager:
		event_manager.handle_phase_shift(phase_name)


func _on_decision_window_opened(patient: Node) -> void:
	if decision_ui:
		decision_ui.display_for_patient(patient)


func _on_decision_submitted(decision: String) -> void:
	last_decision = decision
	
	# Report back to authority to progress the game
	phase_manager.complete_current_cycle()
	
	# Optional: acknowledge back to interaction system if needed
	if interaction_system:
		interaction_system.acknowledge_decision()
