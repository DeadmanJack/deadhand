extends GutTest

const ResolutionEngineScript = preload("res://autoload/deadhand_resolution_engine.gd")


var _engine: Node
var _resolved_events: Array


func before_each() -> void:
	_engine = ResolutionEngineScript.new()
	add_child_autofree(_engine)
	_resolved_events.clear()
	DeadhandEventBus.check_resolved.connect(_on_check_resolved)


func after_each() -> void:
	if DeadhandEventBus.check_resolved.is_connected(_on_check_resolved):
		DeadhandEventBus.check_resolved.disconnect(_on_check_resolved)


func _on_check_resolved(payload: CheckResolvedPayload) -> void:
	_resolved_events.append(payload)


func _make_task(primary_suit: String, dc: int) -> DeadhandTaskData:
	var task := DeadhandTaskData.new()
	task.object_id = "task_test_check"
	task.task_primary_suit = primary_suit
	task.task_difficulty_class = dc
	return task


func test_matching_suit_success_at_dc() -> void:
	var task := _make_task("hearts", 10)
	var cards: Array = [{"suit": "hearts", "value": 10}]

	var result: Dictionary = _engine.resolve_solo_check(task, cards)

	assert_true(result.success, "Sum 10 should meet DC 10")
	assert_eq(result.sum, 10)
	assert_eq(result.dc, 10)
	assert_false(result.critical_success)


func test_off_suit_halving_causes_borderline_failure() -> void:
	var task := _make_task("hearts", 10)
	var cards: Array = [
		{"suit": "hearts", "value": 6},
		{"suit": "diamonds", "value": 7},
	]

	var result: Dictionary = _engine.resolve_solo_check(task, cards)

	assert_eq(result.sum, 9, "Off-suit 7 should halve to 3; 6 + 3 = 9")
	assert_false(result.success, "Sum 9 should fail DC 10")
	assert_false(result.critical_success)


func test_critical_success_at_plus_five_over_dc() -> void:
	var task := _make_task("spades", 10)
	var cards: Array = [
		{"suit": "spades", "value": 10},
		{"suit": "spades", "value": 5},
	]

	var result: Dictionary = _engine.resolve_solo_check(task, cards)

	assert_true(result.success)
	assert_eq(result.sum, 15)
	assert_true(result.critical_success, "Sum 15 is DC 10 + 5")


func test_joker_zero_contribution() -> void:
	var task := _make_task("clubs", 5)
	var cards: Array = [
		{"suit": "clubs", "value": 0},
		{"suit": "hearts", "value": 4},
	]

	var result: Dictionary = _engine.resolve_solo_check(task, cards)

	assert_eq(result.sum, 2, "Joker contributes 0; off-suit 4 halves to 2")
	assert_false(result.success)
	assert_false(result.critical_success)


func test_resolve_and_emit_fires_check_resolved() -> void:
	var task := _make_task("hearts", 8)
	var cards: Array = [{"suit": "hearts", "value": 8}]

	var result: Dictionary = _engine.resolve_and_emit(task, cards)

	assert_true(result.success)
	assert_eq(_resolved_events.size(), 1)
	assert_eq(_resolved_events[0].task, "task_test_check")
	assert_eq(_resolved_events[0].sum, 8)
	assert_eq(_resolved_events[0].dc, 8)
	assert_true(_resolved_events[0].success)
