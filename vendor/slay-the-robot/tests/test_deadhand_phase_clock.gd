extends GutTest

const RunStateScript = preload("res://autoload/deadhand_run_state.gd")
const PhaseClockScript = preload("res://autoload/deadhand_phase_clock.gd")
const EventBusScript = preload("res://autoload/deadhand_event_bus.gd")
const EventLogScript = preload("res://autoload/deadhand_event_log.gd")


func _make_clock_stack() -> Array:
	var bus = EventBusScript.new()
	var log = EventLogScript.new()
	var run_state = RunStateScript.new()
	var clock = PhaseClockScript.new()
	add_child_autofree(bus)
	add_child_autofree(log)
	add_child_autofree(run_state)
	add_child_autofree(clock)
	run_state.bind_event_bus(bus)
	clock.bind_event_bus(bus)
	clock.bind_run_state(run_state)
	log.bind_event_bus(bus)
	await get_tree().process_frame
	return [bus, log, run_state, clock]


func test_full_day_cycle_advances_through_all_phases() -> void:
	var nodes: Array = await _make_clock_stack()
	var bus = nodes[0]
	var run_state = nodes[2]
	var clock = nodes[3]
	var phase_events: Array = []

	bus.phase_advanced.connect(func(payload: PhaseAdvancedPayload) -> void:
		phase_events.append(payload)
	)

	assert_eq(run_state.get_day(), 1)
	assert_eq(run_state.get_phase(), "morning")

	clock.advance_phase()
	assert_eq(run_state.get_phase(), "afternoon")
	clock.advance_phase()
	assert_eq(run_state.get_phase(), "evening")
	clock.advance_phase()
	assert_eq(run_state.get_phase(), "night")

	assert_eq(phase_events.size(), 3)
	assert_eq(phase_events[0].phase, "afternoon")
	assert_eq(phase_events[1].phase, "evening")
	assert_eq(phase_events[2].phase, "night")
	for payload: PhaseAdvancedPayload in phase_events:
		assert_eq(payload.day, 1)


func test_forced_rest_after_night_advances_day() -> void:
	var nodes: Array = await _make_clock_stack()
	var bus = nodes[0]
	var log = nodes[1]
	var run_state = nodes[2]
	var clock = nodes[3]
	var rest_events: Array = []
	var day_events: Array = []

	log.start_run(42)
	bus.rest_forced.connect(func(payload: RestForcedPayload) -> void:
		rest_events.append(payload)
	)
	bus.day_advanced.connect(func(payload: DayAdvancedPayload) -> void:
		day_events.append(payload)
	)

	for _i in 4:
		clock.advance_phase()

	assert_eq(rest_events.size(), 1)
	assert_eq(rest_events[0].reason, "end_of_night")
	assert_eq(day_events.size(), 1)
	assert_eq(day_events[0].day, 2)
	assert_eq(run_state.get_day(), 2)
	assert_eq(run_state.get_phase(), "morning")
	assert_gt(log.get_line_count(), 0)
