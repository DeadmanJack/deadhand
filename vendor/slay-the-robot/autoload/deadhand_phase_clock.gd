# === MODULE: PhaseClock ===
# Purpose: Drive the four-phase day cycle (morning/afternoon/evening/night) and forced rest.
# Owns:    Phase order logic; delegates day/phase storage to RunState.
#
# Consumes events:
#   - (none — callers invoke advance_phase() directly until ActionTaken wiring)
#
# Emits events:
#   - phase_advanced(day:int, phase:String)
#   - day_advanced(day:int)
#   - rest_forced(reason:String, location:String)
#
# Invariants:
#   - Phases cycle M → A → E → N in order.
#   - After night, rest_forced emits before day_advanced; day increments and phase resets to morning.
#
# Does NOT:
#   - Mutate RunState fields directly (uses RunState public mutators).
#   - Resolve rest location or heal wounds (future Rest module).
extends Node

const PHASE_ORDER: Array[String] = ["morning", "afternoon", "evening", "night"]

var _run_state: Node = null
var _bus: Node = null


func _ready() -> void:
	_run_state = get_node_or_null("/root/DeadhandRunState")
	_bus = get_node_or_null("/root/DeadhandEventBus")


func bind_run_state(run_state: Node) -> void:
	_run_state = run_state


func bind_event_bus(bus: Node) -> void:
	_bus = bus


func advance_phase() -> void:
	var run_state := _get_run_state()
	var current_phase: String = run_state.get_phase()
	var current_day: int = run_state.get_day()

	if current_phase == "night":
		_emit_rest_forced("end_of_night")
		var next_day: int = current_day + 1
		run_state.set_day(next_day)
		_emit_day_advanced(next_day)
		run_state.set_phase("morning")
		_emit_phase_advanced(next_day, "morning")
		return

	var next_index: int = PHASE_ORDER.find(current_phase) + 1
	var next_phase: String = PHASE_ORDER[next_index]
	run_state.set_phase(next_phase)
	_emit_phase_advanced(current_day, next_phase)


func _get_run_state() -> Node:
	if _run_state != null:
		return _run_state
	if is_inside_tree():
		return get_node_or_null("/root/DeadhandRunState")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DeadhandRunState")
	push_error("PhaseClock: RunState not available")
	return null


func _emit_phase_advanced(day: int, phase: String) -> void:
	if _bus != null and _bus.has_method("emit_phase_advanced"):
		_bus.emit_phase_advanced(day, phase)


func _emit_day_advanced(day: int) -> void:
	if _bus != null and _bus.has_method("emit_day_advanced"):
		_bus.emit_day_advanced(day)


func _emit_rest_forced(reason: String, location: String = "") -> void:
	if _bus != null and _bus.has_method("emit_rest_forced"):
		_bus.emit_rest_forced(reason, location)
