extends GutTest

const RunStateScript = preload("res://autoload/deadhand_run_state.gd")
const EventBusScript = preload("res://autoload/deadhand_event_bus.gd")


func _make_run_state():
	var bus = EventBusScript.new()
	var run_state = RunStateScript.new()
	add_child_autofree(bus)
	add_child_autofree(run_state)
	run_state.bind_event_bus(bus)
	await get_tree().process_frame
	return [bus, run_state]


func test_defaults_match_gdd_starting_values() -> void:
	var nodes: Array = await _make_run_state()
	var run_state = nodes[1]

	assert_eq(run_state.get_day(), 1)
	assert_eq(run_state.get_phase(), "morning")
	assert_eq(run_state.get_money(), 2)
	assert_eq(run_state.get_player_wounds(), 0)
	assert_eq(run_state.get_actions_remaining_this_phase(), 1)


func test_apply_money_delta_updates_balance_and_emits() -> void:
	var nodes: Array = await _make_run_state()
	var bus = nodes[0]
	var run_state = nodes[1]
	var money_events: Array = []
	var state_events: Array = []

	bus.money_changed.connect(func(payload: MoneyChangedPayload) -> void:
		money_events.append(payload)
	)
	bus.run_state_changed.connect(func(payload: RunStateChangedPayload) -> void:
		state_events.append(payload)
	)

	run_state.apply_money_delta(5, "pan_for_gold")
	assert_eq(run_state.get_money(), 7)
	assert_eq(money_events.size(), 1)
	assert_eq(money_events[0].old_value, 2)
	assert_eq(money_events[0].new_value, 7)
	assert_eq(money_events[0].delta, 5)
	assert_eq(money_events[0].reason, "pan_for_gold")
	assert_eq(state_events.size(), 1)
	assert_eq(state_events[0].field, "money")
	assert_eq(state_events[0].old_value, 2)
	assert_eq(state_events[0].new_value, 7)


func test_snapshot_serializes_current_state_reads() -> void:
	var nodes: Array = await _make_run_state()
	var run_state = nodes[1]

	run_state.apply_money_delta(-1, "drink")
	run_state.set_wounds(2)
	run_state.set_phase("evening")
	run_state.consume_action()

	var snap: Dictionary = run_state.snapshot()
	assert_eq(snap["day"], 1)
	assert_eq(snap["phase"], "evening")
	assert_eq(snap["money"], 1)
	assert_eq(snap["player_wounds"], 2)
	assert_eq(snap["actions_remaining_this_phase"], 0)
