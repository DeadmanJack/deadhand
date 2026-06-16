# === MODULE: EventLog ===
# Purpose: Append-only JSONL log of every DeadhandEventBus event for replay/debug/CLI tests.
# Owns:    run_uuid, seq counter, log file handle state.
#
# Consumes events:
#   - All DeadhandEventBus signals
#
# Emits events:
#   - log_committed(seq:int) after each line written
#
# Invariants:
#   - seq is monotonic per run starting at 0.
#   - Every line is valid JSON with keys: seq, t_ms, type, data.
#
# Does NOT:
#   - Mutate gameplay state.
#   - Persist across runs without explicit start_run().
extends Node

signal log_committed(seq: int)

var run_uuid: String = ""
var seq: int = 0
var _run_start_ms: int = 0
var _log_path: String = ""
var _line_count: int = 0
var _bus: Node

const LOG_DIR := "user://logs/runs/"

const BUS_SIGNALS: Array[String] = [
	"card_drawn", "card_played", "card_discarded", "card_burned",
	"check_resolved", "shot_resolved", "encounter_started", "encounter_resolved",
	"phase_advanced", "day_advanced", "rest_forced",
	"notoriety_changed", "notoriety_threshold_crossed", "money_changed", "loot_rolled",
	"hidden_trigger_fired", "memory_card_revealed", "journal_entry_unlocked",
	"set_bonus_activated", "set_bonus_deactivated",
	"run_started", "run_ended", "rng_rolled", "bridged_str_signal",
]


func _ready() -> void:
	var bus: Node = get_node_or_null("/root/DeadhandEventBus")
	if bus != null and bus.has_method("bind_event_bus") == false and bus.has_signal("card_drawn"):
		bind_event_bus(bus)
	if _log_path.is_empty():
		start_run(0)


func bind_event_bus(bus: Node) -> void:
	_bus = bus
	if _bus == null:
		return
	for sig_name: String in BUS_SIGNALS:
		if _bus.has_signal(sig_name) and not _bus.is_connected(sig_name, _on_bus_signal):
			_bus.connect(sig_name, _on_bus_signal.bind(sig_name))


func start_run(new_seed: int, starter_deck_id: String = "default") -> void:
	run_uuid = "%d-%d" % [new_seed, Time.get_ticks_msec()]
	seq = 0
	_line_count = 0
	_run_start_ms = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(LOG_DIR)
	_log_path = LOG_DIR + run_uuid + ".jsonl"
	var started := RunStartedPayload.new()
	started.seed = new_seed
	started.starter_deck_id = starter_deck_id
	started.run_uuid = run_uuid
	_log_event("run_started", started.to_dict())


func end_run() -> void:
	var ended := RunEndedPayload.new()
	ended.reason = "normal"
	_log_event("run_ended", ended.to_dict())
	run_uuid = ""


func get_log_path() -> String:
	return _log_path


func get_line_count() -> int:
	return _line_count


func _on_bus_signal(payload: Variant, sig_name: String) -> void:
	var data: Dictionary = {}
	if payload is Resource and payload.has_method("to_dict"):
		data = payload.to_dict()
	else:
		data = {"value": str(payload)}
	_log_event(sig_name, data)


func _log_event(type: String, data: Dictionary) -> void:
	if _log_path.is_empty():
		DirAccess.make_dir_recursive_absolute(LOG_DIR)
		if run_uuid.is_empty():
			run_uuid = "boot-%d" % Time.get_ticks_msec()
		_log_path = LOG_DIR + run_uuid + ".jsonl"
	var entry := {
		"seq": seq,
		"t_ms": Time.get_ticks_msec() - _run_start_ms,
		"type": type,
		"data": data,
	}
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(_log_path) else FileAccess.WRITE
	var f := FileAccess.open(_log_path, mode)
	if f:
		if f.get_length() > 0:
			f.seek_end()
		f.store_line(JSON.stringify(entry))
		f.close()
	log_committed.emit(seq)
	seq += 1
	_line_count += 1
