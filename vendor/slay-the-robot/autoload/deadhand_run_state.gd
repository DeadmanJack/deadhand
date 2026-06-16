# === MODULE: RunState ===
# Purpose: Single source of truth for core run fields during a Deadhand run.
# Owns:    day, phase, money, player_wounds, actions_remaining_this_phase
#
# Consumes events:
#   - (none — other modules call public mutators or future bus request signals)
#
# Emits events:
#   - run_state_changed(field:String, old:Variant, new:Variant)
#   - money_changed(old:int, new:int, delta:int, reason:String) via EventBus
#
# Invariants:
#   - day starts at 1; phase starts at "morning"; money starts at 2.
#   - actions_remaining_this_phase resets to 1 whenever phase changes.
#   - All field writes go through public mutators that emit on DeadhandEventBus.
#
# Does NOT:
#   - Advance phases (see PhaseClock).
#   - Track notoriety, deck, or equipment (future modules).
extends Node

const DEFAULT_ACTIONS_PER_PHASE := 1
const STARTING_MONEY := 2

var _day: int = 1
var _phase: String = "morning"
var _money: int = STARTING_MONEY
var _player_wounds: int = 0
var _actions_remaining_this_phase: int = DEFAULT_ACTIONS_PER_PHASE

var _bus: Node = null


func _ready() -> void:
	_bus = get_node_or_null("/root/DeadhandEventBus")


func bind_event_bus(bus: Node) -> void:
	_bus = bus


func get_day() -> int:
	return _day


func get_phase() -> String:
	return _phase


func get_money() -> int:
	return _money


func get_player_wounds() -> int:
	return _player_wounds


func get_actions_remaining_this_phase() -> int:
	return _actions_remaining_this_phase


func snapshot() -> Dictionary:
	return {
		"day": _day,
		"phase": _phase,
		"money": _money,
		"player_wounds": _player_wounds,
		"actions_remaining_this_phase": _actions_remaining_this_phase,
	}


func reset_run() -> void:
	_day = 1
	_phase = "morning"
	_money = STARTING_MONEY
	_player_wounds = 0
	_actions_remaining_this_phase = DEFAULT_ACTIONS_PER_PHASE


func apply_money_delta(delta: int, reason: String = "") -> void:
	var old_value: int = _money
	_money += delta
	_emit_money_changed(old_value, _money, delta, reason)
	_emit_run_state_changed("money", old_value, _money)


func set_wounds(value: int, reason: String = "") -> void:
	var old_value: int = _player_wounds
	_player_wounds = maxi(value, 0)
	_emit_run_state_changed("player_wounds", old_value, _player_wounds)


func set_phase(phase: String) -> void:
	var old_value: String = _phase
	_phase = phase
	var old_actions: int = _actions_remaining_this_phase
	_actions_remaining_this_phase = DEFAULT_ACTIONS_PER_PHASE
	_emit_run_state_changed("phase", old_value, _phase)
	if old_actions != _actions_remaining_this_phase:
		_emit_run_state_changed("actions_remaining_this_phase", old_actions, _actions_remaining_this_phase)


func set_day(day: int) -> void:
	var old_value: int = _day
	_day = maxi(day, 1)
	_emit_run_state_changed("day", old_value, _day)


func consume_action() -> bool:
	if _actions_remaining_this_phase <= 0:
		return false
	var old_value: int = _actions_remaining_this_phase
	_actions_remaining_this_phase -= 1
	_emit_run_state_changed("actions_remaining_this_phase", old_value, _actions_remaining_this_phase)
	return true


func _emit_run_state_changed(field: String, old_value: Variant, new_value: Variant) -> void:
	if _bus != null and _bus.has_method("emit_run_state_changed"):
		_bus.emit_run_state_changed(field, old_value, new_value)


func _emit_money_changed(old_value: int, new_value: int, delta: int, reason: String) -> void:
	if _bus != null and _bus.has_method("emit_money_changed"):
		_bus.emit_money_changed(old_value, new_value, delta, reason)
