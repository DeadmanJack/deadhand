extends GutTest

const TEST_OBJECT_ID: String = "test_deadhand_data"

func _assert_serializable_round_trip(original: SerializableData, restored: SerializableData) -> void:
	var serialized: Dictionary = original.get_serializable_properties(false)
	restored.set_serializable_properties(serialized, false)
	var reserialized: Dictionary = restored.get_serializable_properties(false)
	assert_eq(reserialized, serialized, "Serializable round-trip should preserve all exported fields")

func test_deadhand_task_data_defaults_and_round_trip():
	var task_data: DeadhandTaskData = DeadhandTaskData.new()
	assert_eq(task_data.task_name, "")
	assert_eq(task_data.task_location_id, "")
	assert_eq(task_data.task_primary_suit, "spades")
	assert_eq(task_data.task_difficulty_class, 10)
	assert_eq(task_data.task_available_phases, [])
	assert_eq(task_data.task_action_cost, 1)
	assert_eq(task_data.task_reward_money_min, 0)
	assert_eq(task_data.task_reward_money_max, 0)
	assert_eq(task_data.task_reward_loot_table_id, "")
	assert_eq(task_data.task_notoriety_delta, 0)
	assert_eq(task_data.task_on_success_actions, [])
	assert_eq(task_data.task_on_failure_actions, [])
	assert_eq(task_data.task_flavor_text, "")

	task_data.object_id = TEST_OBJECT_ID
	task_data.task_name = "Rob the Stagecoach"
	task_data.task_location_id = "location_outskirts"
	task_data.task_primary_suit = "hearts"
	task_data.task_difficulty_class = 14
	task_data.task_available_phases = ["morning", "afternoon"]
	task_data.task_action_cost = 2
	task_data.task_reward_money_min = 3
	task_data.task_reward_money_max = 8
	task_data.task_reward_loot_table_id = "loot_stagecoach"
	task_data.task_notoriety_delta = 2
	task_data.task_on_success_actions = [{"action_debug_log": {"message": "success"}}]
	task_data.task_on_failure_actions = [{"action_debug_log": {"message": "failure"}}]
	task_data.task_flavor_text = "Dust and danger."

	var restored: DeadhandTaskData = DeadhandTaskData.new()
	_assert_serializable_round_trip(task_data, restored)

func test_deadhand_contested_encounter_data_defaults_and_round_trip():
	var encounter_data: DeadhandContestedEncounterData = DeadhandContestedEncounterData.new()
	assert_eq(encounter_data.contested_name, "")
	assert_eq(encounter_data.contested_primary_suit, "")
	assert_eq(encounter_data.contested_rounds, 3)
	assert_eq(encounter_data.contested_bust_line, 0)
	assert_eq(encounter_data.contested_player_wound_limit, 3)
	assert_eq(encounter_data.contested_opponent_deck_template_id, "")
	assert_eq(encounter_data.contested_opponent_wound_limit, 3)
	assert_eq(encounter_data.contested_opponent_hand_size, 5)
	assert_eq(encounter_data.contested_on_win_actions, [])
	assert_eq(encounter_data.contested_on_lose_actions, [])
	assert_eq(encounter_data.contested_flavor_text, "")

	encounter_data.object_id = TEST_OBJECT_ID
	encounter_data.contested_name = "Town Drunk"
	encounter_data.contested_primary_suit = "clubs"
	encounter_data.contested_rounds = 5
	encounter_data.contested_bust_line = 21
	encounter_data.contested_player_wound_limit = 2
	encounter_data.contested_opponent_deck_template_id = "deck_town_drunk"
	encounter_data.contested_opponent_wound_limit = 1
	encounter_data.contested_opponent_hand_size = 4
	encounter_data.contested_on_win_actions = [{"action_debug_log": {"message": "win"}}]
	encounter_data.contested_on_lose_actions = [{"action_debug_log": {"message": "lose"}}]
	encounter_data.contested_flavor_text = "He staggers but shoots straight."

	var restored: DeadhandContestedEncounterData = DeadhandContestedEncounterData.new()
	_assert_serializable_round_trip(encounter_data, restored)

func test_deadhand_hidden_trigger_data_defaults_and_round_trip():
	var trigger_data: DeadhandHiddenTriggerData = DeadhandHiddenTriggerData.new()
	assert_eq(trigger_data.trigger_conditions, [])
	assert_eq(trigger_data.trigger_fires_at_most, "once_per_run")
	assert_eq(trigger_data.trigger_on_fire_actions, [])
	assert_eq(trigger_data.trigger_emit_line, "")
	assert_eq(trigger_data.trigger_journal_entry_id, "")

	trigger_data.object_id = TEST_OBJECT_ID
	trigger_data.trigger_conditions = [{"type": "notoriety_at_least", "value": 5}]
	trigger_data.trigger_fires_at_most = "unlimited"
	trigger_data.trigger_on_fire_actions = [{"action_debug_log": {"message": "fired"}}]
	trigger_data.trigger_emit_line = "Something stirs in the dark."
	trigger_data.trigger_journal_entry_id = "journal_whisper"

	var restored: DeadhandHiddenTriggerData = DeadhandHiddenTriggerData.new()
	_assert_serializable_round_trip(trigger_data, restored)

func test_deadhand_set_bonus_data_defaults_and_round_trip():
	var set_bonus_data: DeadhandSetBonusData = DeadhandSetBonusData.new()
	assert_eq(set_bonus_data.set_name, "")
	assert_eq(set_bonus_data.set_required_artifact_ids, [])
	assert_eq(set_bonus_data.set_required_card_tags, [])
	assert_eq(set_bonus_data.set_required_card_tag_min_count, 0)
	assert_eq(set_bonus_data.set_on_activate_actions, [])
	assert_eq(set_bonus_data.set_on_deactivate_actions, [])
	assert_eq(set_bonus_data.set_discovery_line, "")

	set_bonus_data.object_id = TEST_OBJECT_ID
	set_bonus_data.set_name = "Gambler's Kit"
	set_bonus_data.set_required_artifact_ids = ["artifact_lucky_coin", "artifact_worn_deck"]
	set_bonus_data.set_required_card_tags = ["tag_gambler"]
	set_bonus_data.set_required_card_tag_min_count = 2
	set_bonus_data.set_on_activate_actions = [{"action_debug_log": {"message": "activate"}}]
	set_bonus_data.set_on_deactivate_actions = [{"action_debug_log": {"message": "deactivate"}}]
	set_bonus_data.set_discovery_line = "The cards feel heavier."

	var restored: DeadhandSetBonusData = DeadhandSetBonusData.new()
	_assert_serializable_round_trip(set_bonus_data, restored)

func test_deadhand_journal_entry_data_defaults_and_round_trip():
	var journal_entry_data: DeadhandJournalEntryData = DeadhandJournalEntryData.new()
	assert_eq(journal_entry_data.journal_title, "")
	assert_eq(journal_entry_data.journal_body, "")
	assert_eq(journal_entry_data.journal_unlock_source, "")
	assert_eq(journal_entry_data.journal_category, "general")

	journal_entry_data.object_id = TEST_OBJECT_ID
	journal_entry_data.journal_title = "The Hanging Tree"
	journal_entry_data.journal_body = "Three knots. Three names."
	journal_entry_data.journal_unlock_source = "memory_card_hanging_tree"
	journal_entry_data.journal_category = "lore"

	var restored: DeadhandJournalEntryData = DeadhandJournalEntryData.new()
	_assert_serializable_round_trip(journal_entry_data, restored)

func test_global_schema_registers_deadhand_data_classes():
	assert_true(Global.CLASS_NAME_TO_CLASS.has("DeadhandTaskData"))
	assert_true(Global.CLASS_NAME_TO_CLASS.has("DeadhandContestedEncounterData"))
	assert_true(Global.CLASS_NAME_TO_CLASS.has("DeadhandHiddenTriggerData"))
	assert_true(Global.CLASS_NAME_TO_CLASS.has("DeadhandSetBonusData"))
	assert_true(Global.CLASS_NAME_TO_CLASS.has("DeadhandJournalEntryData"))

	var task_script: Script = DeadhandTaskData
	var trigger_script: Script = DeadhandHiddenTriggerData
	assert_eq(Global.READ_ONLY_GETTER_SCHEMA[task_script], "_id_to_deadhand_task_data")
	assert_eq(Global.READ_ONLY_GETTER_SCHEMA[trigger_script], "_id_to_deadhand_hidden_trigger_data")

func test_global_getters_return_registered_data():
	var task_data: DeadhandTaskData = DeadhandTaskData.new(TEST_OBJECT_ID)
	Global.register_rod(task_data)

	assert_eq(Global.get_deadhand_task_data(TEST_OBJECT_ID), task_data)
	assert_not_null(Global.get_deadhand_task_data_from_prototype(TEST_OBJECT_ID))
	assert_ne(Global.get_deadhand_task_data_from_prototype(TEST_OBJECT_ID).object_uid, "")

	var trigger_data: DeadhandHiddenTriggerData = DeadhandHiddenTriggerData.new(TEST_OBJECT_ID + "_trigger")
	Global.register_rod(trigger_data)
	assert_eq(Global.get_deadhand_hidden_trigger_data(TEST_OBJECT_ID + "_trigger"), trigger_data)
