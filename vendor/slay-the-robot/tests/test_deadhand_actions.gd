extends GutTest

const ACTION_PATHS := {
	"notoriety_delta": "res://scripts/deadhand/actions/ActionDeadhandNotorietyDelta.gd",
	"grant_task_rewards": "res://scripts/deadhand/actions/ActionDeadhandGrantTaskRewards.gd",
	"reveal_memory": "res://scripts/deadhand/actions/ActionDeadhandRevealMemory.gd",
	"sting_rider": "res://scripts/deadhand/actions/ActionDeadhandStingRider.gd",
}


func before_each() -> void:
	DeadhandNotorietyTracker.reset_for_run()
	DeadhandRunState.reset_run()
	DeadhandRNGService.set_run_seed(42)


func _make_action(action_key: String, values: Dictionary) -> BaseAction:
	var script: Script = load(ACTION_PATHS[action_key])
	var action: BaseAction = script.new()
	var typed_values: Dictionary[String, Variant] = {}
	typed_values.merge(values)
	action.init(null, null, [], typed_values)
	return action


func test_notoriety_delta_action_applies_delta() -> void:
	var action: BaseAction = _make_action("notoriety_delta", {"delta": 3, "reason": "grave_robbery"})
	action.perform_action()

	assert_eq(DeadhandNotorietyTracker.get_notoriety(), 3)


func test_grant_task_rewards_rolls_money_into_run_state() -> void:
	var action: BaseAction = _make_action(
		"grant_task_rewards",
		{"money_min": 3, "money_max": 8, "reason": "rob_grave"}
	)
	action.perform_action()

	assert_eq(DeadhandRunState.get_money(), 2 + 6, "Seed 42 rng_loot first roll_range(3,8) should be 6")


func test_grant_task_rewards_fixed_payout_when_min_equals_max() -> void:
	var action: BaseAction = _make_action("grant_task_rewards", {"money_min": 4, "money_max": 4})
	action.perform_action()

	assert_eq(DeadhandRunState.get_money(), 6)


func test_reveal_memory_emits_bus_events() -> void:
	var memory_events: Array = []
	var journal_events: Array = []
	DeadhandEventBus.memory_card_revealed.connect(func(payload: MemoryCardRevealedPayload) -> void:
		memory_events.append(payload)
	)
	DeadhandEventBus.journal_entry_unlocked.connect(func(payload: JournalEntryUnlockedPayload) -> void:
		journal_events.append(payload)
	)

	var action: BaseAction = _make_action("reveal_memory", {
		"journal_entry_id": "journal_locket_engraved_e",
		"card_id": "card_memory_locket_1",
	})
	action.perform_action()

	assert_eq(memory_events.size(), 1)
	assert_eq(memory_events[0].card_id, "card_memory_locket_1")
	assert_eq(journal_events.size(), 1)
	assert_eq(journal_events[0].entry_id, "journal_locket_engraved_e")


func test_sting_rider_applies_immediate_wound() -> void:
	var action: BaseAction = _make_action("sting_rider", {"wound_amount": 2, "timing": "immediate"})
	action.perform_action()

	assert_eq(DeadhandRunState.get_player_wounds(), 2)


func test_sting_rider_skips_non_immediate_timing() -> void:
	var action: BaseAction = _make_action("sting_rider", {"wound_amount": 1, "timing": "end_of_encounter"})
	action.perform_action()

	assert_eq(DeadhandRunState.get_player_wounds(), 0)


func test_card_drink_beer_loaded_in_global() -> void:
	assert_true(
		Global._id_to_card_data.has("card_drink_beer"),
		"Deadhand mod card card_drink_beer should be loaded into Global"
	)
	var card: CardData = Global._id_to_card_data["card_drink_beer"]
	assert_eq(card.card_name, "Beer")
	assert_true(card.card_tags.has("sting"))
	assert_true(card.card_tags.has("drink"))
	assert_true(bool(card.card_values.get("is_sting", false)))
	assert_eq(int(card.card_values.get("rank", -1)), 5)
	assert_eq(card.card_values.get("suit", ""), "clubs")
	assert_eq(card.card_play_actions.size(), 1)
