# === MODULE: NotorietyTracker ===
# Purpose: Single source of truth for the player's Notoriety stat during a run.
# Owns:    int notoriety (0..20)
#
# Consumes events:
#   - NotorietyDeltaRequested(delta:int, reason:String)
#   - TaskResolved(task_id, success, ...)   # auto-applies task.notoriety_on_success
#
# Emits events:
#   - NotorietyChanged(old:int, new:int, reason:String)
#   - NotorietyThresholdCrossed(threshold:int, direction:String)
#
# Invariants:
#   - notoriety is clamped to [0, 20].
#   - Reaching 20 emits RunFailed(reason: "rope") on the same frame.
#
# Does NOT:
#   - Modify any other module's state.
#   - Display anything (UI is downstream of events).
#   - Make any random calls (no need).
extends Node

const MIN_NOTORIETY := 0
const MAX_NOTORIETY := 20
const THRESHOLDS: Array[int] = [5, 10, 15]

var _notoriety: int = 0


func apply_delta(delta: int, reason: String = "") -> void:
	if delta == 0:
		return
	var old_value := _notoriety
	var new_value := clampi(old_value + delta, MIN_NOTORIETY, MAX_NOTORIETY)
	if new_value == old_value:
		return

	_notoriety = new_value
	_emit_notoriety_changed(old_value, new_value, reason)
	_emit_threshold_crossings(old_value, new_value)
	if new_value >= MAX_NOTORIETY:
		_emit_run_ended_rope()


func get_notoriety() -> int:
	return _notoriety


func reset_for_run() -> void:
	_notoriety = 0


func _emit_threshold_crossings(old_value: int, new_value: int) -> void:
	for threshold: int in THRESHOLDS:
		if old_value < threshold and new_value >= threshold:
			_emit_threshold_crossed(threshold, "up")
		elif old_value >= threshold and new_value < threshold:
			_emit_threshold_crossed(threshold, "down")


func _emit_notoriety_changed(old_value: int, new_value: int, reason: String) -> void:
	var bus := _get_bus()
	if bus != null and bus.has_method("emit_notoriety_changed"):
		bus.emit_notoriety_changed(old_value, new_value, reason)


func _emit_threshold_crossed(threshold: int, direction: String) -> void:
	var bus := _get_bus()
	if bus != null and bus.has_method("emit_notoriety_threshold_crossed"):
		bus.emit_notoriety_threshold_crossed(threshold, direction)


func _emit_run_ended_rope() -> void:
	var bus := _get_bus()
	if bus != null and bus.has_method("emit_run_ended"):
		bus.emit_run_ended("rope", false)


func _get_bus() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/DeadhandEventBus")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DeadhandEventBus")
	return null
