extends GutTest

const RunnerScript = preload("res://scripts/deadhand/deadhand_contested_encounter_runner.gd")

const TASK_ID: String = "task_rob_grave"
const ENCOUNTER_ID: String = "encounter_town_drunk"
const TEST_SEED: int = 42


func before_each() -> void:
	var run_state: Node = get_node("/root/DeadhandRunState")
	run_state.reset_run()
	get_node("/root/DeadhandNotorietyTracker").reset_for_run()
	get_node("/root/DeadhandRNGService").set_run_seed(TEST_SEED)


func test_vertical_slice_content_loaded() -> void:
	assert_true(
		Global._id_to_deadhand_task_data.has(TASK_ID),
		"task_rob_grave should load from Deadhand mod overlay"
	)
	var task: DeadhandTaskData = Global.get_deadhand_task_data(TASK_ID)
	assert_eq(task.task_name, "Rob a Grave")
	assert_eq(task.task_location_id, "location_cemetery")
	assert_eq(task.task_primary_suit, "hearts")
	assert_eq(task.task_difficulty_class, 11)
	assert_eq(task.task_available_phases, ["night"])
	assert_eq(task.task_notoriety_delta, 1)

	assert_true(
		Global._id_to_deadhand_contested_encounter_data.has(ENCOUNTER_ID),
		"encounter_town_drunk should load from Deadhand mod overlay"
	)
	var encounter: DeadhandContestedEncounterData = Global.get_deadhand_contested_encounter_data(ENCOUNTER_ID)
	assert_eq(encounter.contested_name, "The Town Drunk")
	assert_eq(encounter.contested_opponent_deck_template_id, "deck_town_drunk")
	assert_true(
		Global._id_to_card_pack_data.has("deck_town_drunk"),
		"deck_town_drunk card pack should load for Town Drunk encounter"
	)


func test_phase_clock_autoload_full_day_cycle() -> void:
	var run_state: Node = get_node("/root/DeadhandRunState")
	var clock: Node = get_node("/root/DeadhandPhaseClock")

	assert_eq(run_state.get_day(), 1)
	assert_eq(run_state.get_phase(), "morning")

	clock.advance_phase()
	assert_eq(run_state.get_phase(), "afternoon")
	clock.advance_phase()
	assert_eq(run_state.get_phase(), "evening")
	clock.advance_phase()
	assert_eq(run_state.get_phase(), "night")
	clock.advance_phase()

	assert_eq(run_state.get_day(), 2)
	assert_eq(run_state.get_phase(), "morning")


func test_notoriety_tracker_autoload_apply_delta() -> void:
	var tracker: Node = get_node("/root/DeadhandNotorietyTracker")
	var changed_events: Array = []
	DeadhandEventBus.notoriety_changed.connect(func(payload: NotorietyChangedPayload) -> void:
		changed_events.append(payload)
	)

	assert_eq(tracker.get_notoriety(), 0)
	tracker.apply_delta(1, "task_rob_grave_success")
	assert_eq(tracker.get_notoriety(), 1)
	assert_eq(changed_events.size(), 1)
	assert_eq(changed_events[0].old_value, 0)
	assert_eq(changed_events[0].new_value, 1)
	assert_eq(changed_events[0].reason, "task_rob_grave_success")


func test_town_drunk_contested_runner_seed_42() -> void:
	var encounter_data: DeadhandContestedEncounterData = Global.get_deadhand_contested_encounter_data(ENCOUNTER_ID)
	var runner := RunnerScript.new(get_node("/root/DeadhandRNGService"), get_node("/root/DeadhandEventBus"))
	var hands: Dictionary = {
		"player": [
			{"value": 10, "suit": "spades"},
			{"value": 8, "suit": "spades"},
			{"value": 7, "suit": "spades"},
		],
		"opponent": [
			[{"value": 9, "suit": "spades"}, {"value": 7, "suit": "spades"}],
			{"value": 9, "suit": "spades"},
			{"value": 8, "suit": "spades"},
		],
	}
	runner.start_encounter(encounter_data, hands.player, hands.opponent)

	assert_eq(runner.state, RunnerScript.State.RESOLVED)
	assert_eq(runner.get_rounds_played(), 3)
	assert_eq(runner.get_outcome(), RunnerScript.OUTCOME_PLAYER_LOSE)
	assert_eq(runner.get_player_wounds(), 3)
	assert_eq(runner.get_opponent_wounds(), 1)


func test_event_log_has_lines_after_boot() -> void:
	var log: Node = get_node("/root/DeadhandEventLog")
	assert_gte(log.get_line_count(), 1, "EventLog should capture at least one line during boot")
