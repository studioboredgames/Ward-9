extends Node
## game_manager.gd
## Responsibility: Central signal router (Mediator).
## Implements: Adaptation Delay (previous-profile caching).

# ─── Signals ──────────────────────────────────────────────────────────────────

signal cycle_started(id: int)
signal cycle_ended(id: int)
signal phase_changed(phase_name: String)
signal decision_received(decision: String, patient: Node)
signal patient_focused(patient: Node)
signal evaluation_updated(state: String, id: int)

# ─── Transit Memory (Psychological State) ─────────────────────────────────────

var behavior_profile: Dictionary = {}
var previous_profile: Dictionary = {} # Implements Adaptation Delay

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
		interaction_system.decision_window_closed.connect(_on_input_patient_unfocused)
		
		# Pro-Focus Signals: Forwarded to Evaluation
		interaction_system.patient_focus_entered.connect(_on_input_focus_entered)
		interaction_system.patient_focus_exited.connect(_on_input_focus_exited)
		
		self.cycle_started.connect(interaction_system.enable_interaction)
		self.cycle_ended.connect(interaction_system.disable_interaction)
	
	# 4. From evaluation_manager (Profiling)
	if evaluation_manager:
		evaluation_manager.evaluation_updated.connect(_on_judgement_updated)
		evaluation_manager.behavior_profile_updated.connect(_on_profile_updated)
	
	# 5. External listeners (Anomaly, Event) connect to this router
	self.cycle_started.connect(anomaly_manager.prepare_cycle_with_profile) # Updated API
	self.cycle_ended.connect(anomaly_manager.cleanup_cycle)
	self.phase_changed.connect(anomaly_manager.handle_phase_shift)
	self.phase_changed.connect(event_manager.handle_phase_shift)
	self.cycle_started.connect(event_manager.on_cycle_started)
	self.evaluation_updated.connect(event_manager.process_evaluation)

	self.decision_received.connect(phase_manager._on_decision_received)

# ─── Behavior Profiling Routing ───────────────────────────────────────────────

func _on_profile_updated(profile: Dictionary) -> void:
	# Implements Lerped Adaptation Delay: Never react to the same cycle context
	previous_profile = behavior_profile
	behavior_profile = profile


func _on_input_focus_entered(patient: Node) -> void:
	if evaluation_manager: evaluation_manager.on_focus_started(patient)
	if patient.has_method("set"): patient.set("is_player_focusing", true)


func _on_input_focus_exited(patient: Node) -> void:
	if evaluation_manager: evaluation_manager.on_focus_ended(patient)
	if patient.has_method("set"): patient.set("is_player_focusing", false)

# ─── Core Signal Routing ──────────────────────────────────────────────────────

func _on_authority_cycle_started(id: int) -> void:
	last_cycle_id = id
	_decision_locked = false
	_current_patient = null
	
	if evaluation_manager: evaluation_manager.reset_cycle_timer()
	
	# Fan out: notify listeners with the Profile-of-Record (previous)
	# This ensures the system acts on a "learned" model, not a reactive one
	emit_signal("cycle_started", id)
	
	# AnomalyManager specific direct call to avoid signal payload limits
	if anomaly_manager:
		anomaly_manager.prepare_cycle(id, previous_profile)


func _on_authority_cycle_ended(id: int) -> void:
	emit_signal("cycle_ended", id)


func _on_authority_phase_changed(phase_name: String) -> void:
	emit_signal("phase_changed", phase_name)


func _on_input_patient_focused(patient: Node) -> void:
	_current_patient = patient
	if decision_ui and patient:
		decision_ui.display_for_patient(patient)
	emit_signal("patient_focused", patient)


func _on_input_patient_unfocused() -> void:
	_current_patient = null


func _on_input_decision_submitted(decision: String) -> void:
	if _decision_locked: return
	if _current_patient == null: return
	_decision_locked = true
	
	if evaluation_manager:
		evaluation_manager.log_decision(decision, last_cycle_id, _current_patient)
	
	emit_signal("decision_received", decision, _current_patient)
	if interaction_system: interaction_system.acknowledge_decision()


func _on_judgement_updated(state: String, id: int) -> void:
	if id != last_cycle_id: return
	emit_signal("evaluation_updated", state, id)
