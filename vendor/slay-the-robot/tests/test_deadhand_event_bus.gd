extends GutTest

const EventBusScript = preload("res://autoload/deadhand_event_bus.gd")


func _make_bus():
	var bus = EventBusScript.new()
	add_child_autofree(bus)
	await get_tree().process_frame
	return bus


func test_emit_card_drawn_emits_payload() -> void:
	var bus = await _make_bus()
	var received: Array = []
	bus.card_drawn.connect(func(payload: CardDrawnPayload) -> void:
		received.append(payload)
	)
	bus.emit_card_drawn("5_clubs", "hand")
	assert_eq(received.size(), 1, "card_drawn should emit a payload")
	assert_eq(received[0].card_id, "5_clubs")
	assert_eq(received[0].to, "hand")


func test_card_drawn_payload_round_trip() -> void:
	var original := CardDrawnPayload.new()
	original.card_id = "j_spades_bowie"
	original.to = "hand"
	var round_trip := CardDrawnPayload.from_dict(original.to_dict()) as CardDrawnPayload
	assert_eq(round_trip.card_id, original.card_id)
	assert_eq(round_trip.to, original.to)


func test_card_played_payload_round_trip() -> void:
	var original := CardPlayedPayload.new()
	original.card_id = "j_spades_bowie"
	original.in_check = "rob_grave"
	var round_trip := CardPlayedPayload.from_dict(original.to_dict()) as CardPlayedPayload
	assert_eq(round_trip.card_id, original.card_id)
	assert_eq(round_trip.in_check, original.in_check)


func test_run_started_payload_round_trip() -> void:
	var original := RunStartedPayload.new()
	original.seed = 8675309
	original.starter_deck_id = "default"
	original.run_uuid = "8675309_test"
	var round_trip := RunStartedPayload.from_dict(original.to_dict()) as RunStartedPayload
	assert_eq(round_trip.seed, original.seed)
	assert_eq(round_trip.starter_deck_id, original.starter_deck_id)
	assert_eq(round_trip.run_uuid, original.run_uuid)


func test_run_ended_payload_round_trip() -> void:
	var original := RunEndedPayload.new()
	original.reason = "ride_out"
	original.victory = false
	var round_trip := RunEndedPayload.from_dict(original.to_dict()) as RunEndedPayload
	assert_eq(round_trip.reason, original.reason)
	assert_eq(round_trip.victory, original.victory)


func test_phase_advanced_payload_round_trip() -> void:
	var original := PhaseAdvancedPayload.new()
	original.day = 1
	original.phase = "morning"
	var round_trip := PhaseAdvancedPayload.from_dict(original.to_dict()) as PhaseAdvancedPayload
	assert_eq(round_trip.day, original.day)
	assert_eq(round_trip.phase, original.phase)


func test_rng_rolled_payload_round_trip() -> void:
	var original := RNGRolledPayload.new()
	original.channel = "rng_combat"
	original.result = 42
	var round_trip := RNGRolledPayload.from_dict(original.to_dict()) as RNGRolledPayload
	assert_eq(round_trip.channel, original.channel)
	assert_eq(round_trip.result, original.result)


func test_bridged_str_signal_payload_round_trip() -> void:
	var original := BridgedSTRSignalPayload.new()
	original.signal_name = "card_drawn"
	original.str_args = {"object_id": "card_strike", "card_name": "Strike"}
	var round_trip := BridgedSTRSignalPayload.from_dict(original.to_dict()) as BridgedSTRSignalPayload
	assert_eq(round_trip.signal_name, original.signal_name)
	assert_eq(round_trip.str_args, original.str_args)


func test_emit_rng_rolled_emits_payload() -> void:
	var bus = await _make_bus()
	var received: Array = []
	bus.rng_rolled.connect(func(payload: RNGRolledPayload) -> void:
		received.append(payload)
	)
	bus.emit_rng_rolled("rng_loot", 7)
	assert_eq(received.size(), 1)
	assert_eq(received[0].channel, "rng_loot")
	assert_eq(received[0].result, 7)
