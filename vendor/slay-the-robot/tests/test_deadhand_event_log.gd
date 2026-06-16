extends GutTest

const EventBusScript = preload("res://autoload/deadhand_event_bus.gd")
const EventLogScript = preload("res://autoload/deadhand_event_log.gd")


func _make_bus_and_log() -> Array:
	var bus = EventBusScript.new()
	var log = EventLogScript.new()
	add_child_autofree(bus)
	add_child_autofree(log)
	log.bind_event_bus(bus)
	await get_tree().process_frame
	return [bus, log]


func test_start_run_writes_jsonl_with_required_fields() -> void:
	var nodes: Array = await _make_bus_and_log()
	var bus = nodes[0]
	var log = nodes[1]

	log.start_run(8675309, "default")
	bus.emit_phase_advanced(1, "morning")
	log.end_run()

	assert_gt(log.get_line_count(), 0, "Event log should contain at least one line")
	var log_path: String = log.get_log_path()
	assert_false(log_path.is_empty())
	assert_true(FileAccess.file_exists(log_path))

	var file := FileAccess.open(log_path, FileAccess.READ)
	assert_not_null(file)
	var first_line: String = file.get_line()
	file.close()

	var parsed: Variant = JSON.parse_string(first_line)
	assert_true(parsed is Dictionary, "Each log line should be valid JSON")
	var entry: Dictionary = parsed
	assert_true(entry.has("seq"), "Line should include seq")
	assert_true(entry.has("t_ms"), "Line should include t_ms")
	assert_true(entry.has("type"), "Line should include type")
	assert_true(entry.has("data"), "Line should include data")
	assert_eq(entry["type"], "run_started")
	assert_eq(entry["data"]["seed"], 8675309)


func test_event_log_records_subsequent_events() -> void:
	var nodes: Array = await _make_bus_and_log()
	var bus = nodes[0]
	var log = nodes[1]

	log.start_run(42)
	bus.emit_card_drawn("5_clubs", "hand")
	log.end_run()

	assert_eq(log.get_line_count(), 3)

	var file := FileAccess.open(log.get_log_path(), FileAccess.READ)
	var lines: Array[String] = []
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if not line.is_empty():
			lines.append(line)
	file.close()

	var card_line: Dictionary = JSON.parse_string(lines[1])
	assert_eq(card_line["seq"], 1)
	assert_eq(card_line["type"], "card_drawn")
	assert_eq(card_line["data"]["card_id"], "5_clubs")
	assert_eq(card_line["data"]["to"], "hand")
