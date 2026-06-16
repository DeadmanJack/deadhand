extends GutTest

const NotorietyTrackerScript = preload("res://autoload/deadhand_notoriety_tracker.gd")


var _tracker: Node
var _changed_events: Array
var _threshold_events: Array
var _run_ended_events: Array


func before_each() -> void:
	_tracker = NotorietyTrackerScript.new()
	add_child_autofree(_tracker)
	_tracker.reset_for_run()
	_changed_events.clear()
	_threshold_events.clear()
	_run_ended_events.clear()
	DeadhandEventBus.notoriety_changed.connect(_on_notoriety_changed)
	DeadhandEventBus.notoriety_threshold_crossed.connect(_on_threshold_crossed)
	DeadhandEventBus.run_ended.connect(_on_run_ended)


func after_each() -> void:
	if DeadhandEventBus.notoriety_changed.is_connected(_on_notoriety_changed):
		DeadhandEventBus.notoriety_changed.disconnect(_on_notoriety_changed)
	if DeadhandEventBus.notoriety_threshold_crossed.is_connected(_on_threshold_crossed):
		DeadhandEventBus.notoriety_threshold_crossed.disconnect(_on_threshold_crossed)
	if DeadhandEventBus.run_ended.is_connected(_on_run_ended):
		DeadhandEventBus.run_ended.disconnect(_on_run_ended)


func _on_notoriety_changed(payload: NotorietyChangedPayload) -> void:
	_changed_events.append(payload)


func _on_threshold_crossed(payload: NotorietyThresholdCrossedPayload) -> void:
	_threshold_events.append(payload)


func _on_run_ended(payload: RunEndedPayload) -> void:
	_run_ended_events.append(payload)


func test_clamps_at_zero_and_twenty() -> void:
	_tracker.apply_delta(-5, "test_floor")
	assert_eq(_tracker.get_notoriety(), 0, "Notoriety should not go below 0")
	assert_eq(_changed_events.size(), 0, "No change event when clamped at floor")

	_tracker.apply_delta(25, "test_ceiling")
	assert_eq(_tracker.get_notoriety(), 20, "Notoriety should clamp at 20")
	assert_eq(_changed_events.size(), 1)
	assert_eq(_changed_events[0].old_value, 0)
	assert_eq(_changed_events[0].new_value, 20)


func test_threshold_crossed_up_at_five_ten_fifteen() -> void:
	_tracker.apply_delta(6, "task_success")
	assert_eq(_threshold_events.size(), 1)
	assert_eq(_threshold_events[0].threshold, 5)
	assert_eq(_threshold_events[0].direction, "up")

	_tracker.apply_delta(5, "more_crime")
	assert_eq(_threshold_events.size(), 2)
	assert_eq(_threshold_events[1].threshold, 10)
	assert_eq(_threshold_events[1].direction, "up")

	_tracker.apply_delta(4, "even_more")
	assert_eq(_threshold_events.size(), 3)
	assert_eq(_threshold_events[2].threshold, 15)
	assert_eq(_threshold_events[2].direction, "up")


func test_threshold_crossed_down() -> void:
	_tracker.apply_delta(16, "ramp_up")
	_threshold_events.clear()

	_tracker.apply_delta(-6, "pay_sheriff")
	assert_eq(_threshold_events.size(), 1)
	assert_eq(_threshold_events[0].threshold, 15)
	assert_eq(_threshold_events[0].direction, "down")

	_tracker.apply_delta(-5, "pay_sheriff")
	assert_eq(_threshold_events.size(), 2)
	assert_eq(_threshold_events[1].threshold, 10)
	assert_eq(_threshold_events[1].direction, "down")

	_tracker.apply_delta(-5, "pay_sheriff")
	assert_eq(_threshold_events.size(), 3)
	assert_eq(_threshold_events[2].threshold, 5)
	assert_eq(_threshold_events[2].direction, "down")


func test_rope_at_twenty_emits_run_ended() -> void:
	_tracker.apply_delta(20, "final_straw")
	assert_eq(_tracker.get_notoriety(), 20)
	assert_eq(_run_ended_events.size(), 1)
	assert_eq(_run_ended_events[0].reason, "rope")
	assert_false(_run_ended_events[0].victory)


func test_reset_for_run_clears_notoriety() -> void:
	_tracker.apply_delta(10, "crime")
	assert_eq(_tracker.get_notoriety(), 10)
	_tracker.reset_for_run()
	assert_eq(_tracker.get_notoriety(), 0)
