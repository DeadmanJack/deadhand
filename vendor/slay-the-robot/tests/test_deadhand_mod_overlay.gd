extends GutTest

## Go/no-go gate smoke test (TDD §8.7 step 5).
## Requires Deadhand autoloads registered and deadhand mod enabled in mod_list.json.


func test_mod_card_loaded() -> void:
	assert_true(
		Global._id_to_card_data.has("test_5_clubs"),
		"Deadhand mod card test_5_clubs should be loaded into Global"
	)
	var card: CardData = Global._id_to_card_data["test_5_clubs"]
	assert_eq(card.card_values.get("suit", ""), "clubs")
	assert_eq(int(card.card_values.get("rank", -1)), 5)


func test_mod_task_loaded() -> void:
	assert_true(
		Global._id_to_deadhand_task_data.has("test_pan_for_gold"),
		"Deadhand mod task test_pan_for_gold should be loaded into Global"
	)
	var task: DeadhandTaskData = Global._id_to_deadhand_task_data["test_pan_for_gold"]
	assert_eq(task.task_name, "Pan for Gold")
	assert_eq(task.task_primary_suit, "diamonds")


func test_event_log_captured_boot() -> void:
	var log = get_node("/root/DeadhandEventLog")
	assert_gte(log.get_line_count(), 1, "EventLog should capture at least one line during boot")
	var log_path: String = log.get_log_path()
	assert_false(log_path.is_empty())
	assert_true(FileAccess.file_exists(log_path))
	var file := FileAccess.open(log_path, FileAccess.READ)
	assert_not_null(file)
	var line := file.get_line()
	file.close()
	var parsed: Variant = JSON.parse_string(line)
	assert_true(parsed is Dictionary)
	assert_true(parsed.has("seq"))
	assert_true(parsed.has("t_ms"))
	assert_true(parsed.has("type"))
	assert_true(parsed.has("data"))
