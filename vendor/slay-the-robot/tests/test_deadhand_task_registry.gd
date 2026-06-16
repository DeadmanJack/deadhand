extends GutTest

const ROB_GRAVE_ID := "task_rob_grave"
const PAN_FOR_GOLD_ID := "test_pan_for_gold"


func before_each() -> void:
	DeadhandRunState.reset_run()


func test_night_rob_grave_available_pan_not() -> void:
	DeadhandRunState.set_phase("night")
	var registry: Node = get_node("/root/DeadhandTaskRegistry")

	assert_true(
		Global._id_to_deadhand_task_data.has(ROB_GRAVE_ID),
		"task_rob_grave should be loaded from mod overlay"
	)
	assert_true(
		Global._id_to_deadhand_task_data.has(PAN_FOR_GOLD_ID),
		"test_pan_for_gold should be loaded from mod overlay"
	)
	assert_true(registry.is_task_available(ROB_GRAVE_ID))
	assert_false(registry.is_task_available(PAN_FOR_GOLD_ID))

	var available: Array[String] = registry.get_available_task_ids()
	assert_true(ROB_GRAVE_ID in available)
	assert_false(PAN_FOR_GOLD_ID in available)


func test_morning_pan_available_rob_grave_not() -> void:
	DeadhandRunState.set_phase("morning")
	var registry: Node = get_node("/root/DeadhandTaskRegistry")

	assert_true(registry.is_task_available(PAN_FOR_GOLD_ID))
	assert_false(registry.is_task_available(ROB_GRAVE_ID))

	var available: Array[String] = registry.get_available_task_ids()
	assert_true(PAN_FOR_GOLD_ID in available)
	assert_false(ROB_GRAVE_ID in available)


func test_phase_advanced_emits_task_availability_changed() -> void:
	var availability_events: Array = []
	DeadhandEventBus.task_availability_changed.connect(func(payload: TaskAvailabilityChangedPayload) -> void:
		availability_events.append(payload)
	)

	DeadhandRunState.set_phase("night")
	DeadhandEventBus.emit_phase_advanced(DeadhandRunState.get_day(), "night")
	await get_tree().process_frame

	assert_eq(availability_events.size(), 1)
	assert_eq(availability_events[0].phase, "night")
	assert_true(ROB_GRAVE_ID in availability_events[0].available_task_ids)
	assert_false(PAN_FOR_GOLD_ID in availability_events[0].available_task_ids)
