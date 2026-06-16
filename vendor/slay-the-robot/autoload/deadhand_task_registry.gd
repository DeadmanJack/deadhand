# === MODULE: TaskRegistry ===
# Purpose: Expose which loaded tasks are available for the current phase.
# Owns:    Nothing mutable — reads Global task data and RunState phase.
#
# Consumes events:
#   - phase_advanced(day:int, phase:String)
#
# Emits events:
#   - task_availability_changed(phase:String, available_task_ids:Array[String])
#
# Invariants:
#   - A task is available iff RunState phase is in task.task_available_phases.
#   - Availability recomputes and emits on every phase_advanced.
#
# Does NOT:
#   - Load task JSON (Global / mod loader owns that).
#   - Filter by equipment (EquipmentChanged wiring is future work).
#   - Resolve or start tasks.
extends Node

var _run_state: Node = null
var _bus: Node = null


func _ready() -> void:
	_run_state = get_node_or_null("/root/DeadhandRunState")
	_bus = get_node_or_null("/root/DeadhandEventBus")
	if _bus != null and _bus.has_signal("phase_advanced"):
		if not _bus.phase_advanced.is_connected(_on_phase_advanced):
			_bus.phase_advanced.connect(_on_phase_advanced)


func get_available_task_ids() -> Array[String]:
	var phase: String = _get_current_phase()
	var result: Array[String] = []
	for task_id: String in Global._id_to_deadhand_task_data.keys():
		var task: DeadhandTaskData = Global._id_to_deadhand_task_data[task_id]
		if phase in task.task_available_phases:
			result.append(task_id)
	result.sort()
	return result


func is_task_available(task_id: String) -> bool:
	var task: DeadhandTaskData = Global._id_to_deadhand_task_data.get(task_id, null)
	if task == null:
		return false
	return _get_current_phase() in task.task_available_phases


func _on_phase_advanced(_payload: PhaseAdvancedPayload) -> void:
	_emit_task_availability_changed()


func _emit_task_availability_changed() -> void:
	if _bus == null or not _bus.has_method("emit_task_availability_changed"):
		return
	var phase: String = _get_current_phase()
	_bus.emit_task_availability_changed(phase, get_available_task_ids())


func _get_current_phase() -> String:
	if _run_state != null and _run_state.has_method("get_phase"):
		return _run_state.get_phase()
	if is_inside_tree():
		var run_state: Node = get_node_or_null("/root/DeadhandRunState")
		if run_state != null and run_state.has_method("get_phase"):
			return run_state.get_phase()
	return "morning"
