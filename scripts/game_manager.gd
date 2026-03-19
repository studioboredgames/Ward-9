extends Node
## game_manager.gd
## Responsibility: Central signal router (Mediator).
## Strictly fans out signals from sources to listeners.
## Stores minimal transit memory; contains NO game logic or state decisions.

# ─── Signals (Fan-Out Hub) ────────────────────────────────────────────────────

signal cycle_started(id: int)
signal cycle_ended(id: int)
signal phase_changed(phase_name: String)
signal decision_received(decision: String, patient: Node)
signal patient_focused(patient: Node)
signal evaluation_updated(state: String, id: int)

# ─── Configuration ────────────────────────────────────────────────────────────

@export var debug_logs: bool = true

# ─── Transit Memory ───────────────────────────────────────────────────────────

var last_decision: String = ""
var last_cycle_id: int = 0
var _current_patient: Node = null
var _decision_locked: bool = false

# ─── Node References ──────────────────────────────────────────────────────────

@onready var phase_manager: Node = $PhaseManager
@onready var anomaly_manager: Node = $AnomalyManager
@onready var evaluation_manager: Node = $EvaluationManager
@onready var event_manager: Node = $EventManager

# These lookup group-assigned nodes at runtime
@onready var interaction_system: Node = get_tree().get_first_node_in_group("interaction_system")
@onready var decision_ui: Control = get_tree().get_first_node_in_group("decision_ui")

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("game_manager")
	_connect_signals()
	_verify_systems()


func _verify_systems() -> void:
	if not interaction_system: push_error("game_manager: interaction_system not found")
	if not decision_ui: push_error("game_manager: decision_ui not found")
	if not evaluation_manager: push_error("game_manager: evaluation_manager not found")
	if not anomaly_manager: push_error("game_manager: anomaly_manager not found")
	if not event_manager: push_error("game_manager: event_manager not found")


func _connect_signals() -> void:
	# 1. From phase_manager (Authority)
	phase_manager.cycle_started_notify.connect(_on_authority_cycle_started)
	phase_manager.cycle_ended_notify.connect(_on_authority_cycle_ended)
	phase_manager.phase_changed_notify.connect(_on_authority_phase_changed)
	
	# 2. From decision_ui (Input)
	if decision_ui:
		decision_ui.decision_submitted.connect(_on_input_decision_submitted)
	
	# 3. From interaction_system (Input)
	if interaction_system:
		interaction_system.decision_window_opened.connect(_on_input_patient_focused)
		# Systems react to the router signals
		self.cycle_started.connect(interaction_system.enable_interaction)
		self.cycle_ended.connect(interaction_system.disable_interaction)
	
	# 4. From evaluation_manager (Judgement)
	if evaluation_manager:
		evaluation_manager.evaluation_updated.connect(_on_judgement_updated)
	
	# 5. External listeners (Anomaly, Event) connect to this router
	self.cycle_started.connect(anomaly_manager.prepare_cycle)
	self.cycle_ended.connect(anomaly_manager.cleanup_cycle)
	self.phase_changed.connect(anomaly_manager.handle_phase_shift)
	self.phase_changed.connect(event_manager.handle_phase_shift)
	self.cycle_started.connect(event_manager.on_cycle_started)
	self.evaluation_updated.connect(event_manager.process_evaluation)

	# 6. Authority (PhaseManager) also reacts to the router
	self.decision_received.connect(phase_manager._on_decision_received)

# ─── Signal Routing (Fan-In -> Fan-Out) ───────────────────────────────────────

func _on_authority_cycle_started(id: int) -> void:
	last_cycle_id = id
	_decision_locked = false
	_current_patient = null
	
	if debug_logs: print("--- Cycle Started: ", id, " ---")
	emit_signal("cycle_started", id)


func _on_authority_cycle_ended(id: int) -> void:
	emit_signal("cycle_ended", id)


func _on_authority_phase_changed(phase_name: String) -> void:
	emit_signal("phase_changed", phase_name)


func _on_input_patient_focused(patient: Node) -> void:
	_current_patient = patient
	if decision_ui and patient:
		decision_ui.display_for_patient(patient)
	emit_signal("patient_focused", patient)


func _on_input_decision_submitted(decision: String) -> void:
	# Race Condition Fix: Lock decisions once submitted
	if _decision_locked:
		return
		
	# Validation: Ensure a patient was focused if this is a gameplay decision
	if _current_patient == null:
		push_warning("game_manager: decision_submitted with null patient; ignoring")
		return
		
	_decision_locked = true
	last_decision = decision
	
	if debug_logs: 
		print("Cycle:", last_cycle_id, " Decision:", decision, " Target:", _current_patient.name)
	
	# Invariant: Evaluation happens BEFORE decision_received fan-out
	if evaluation_manager:
		evaluation_manager.log_decision(decision, last_cycle_id, _current_patient)
	
	# Router notifies authorities and listeners
	emit_signal("decision_received", decision, _current_patient)
	
	# Optional: feedback to interaction system
	if interaction_system:
		interaction_system.acknowledge_decision()


func _on_judgement_updated(state: String, id: int) -> void:
	# Validation: Ignore stale evaluation results
	if id != last_cycle_id:
		return
		
	emit_signal("evaluation_updated", state, id)
