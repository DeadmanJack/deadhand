extends GutTest

## Verifies STR Signals → DeadhandEventBus bridge wiring and forwarding.

const BRIDGED_SIGNALS: Array[String] = [
	"card_drawn",
	"card_played",
	"card_discarded",
	"card_exhausted",
	"card_added_to_hand",
	"card_created",
]

const HANDLER_BY_SIGNAL: Dictionary = {
	"card_drawn": "_on_str_card_drawn",
	"card_played": "_on_str_card_played",
	"card_discarded": "_on_str_card_discarded",
	"card_exhausted": "_on_str_card_exhausted",
	"card_added_to_hand": "_on_str_card_added_to_hand",
	"card_created": "_on_str_card_created",
}


func test_str_bridge_connections_exist() -> void:
	await get_tree().process_frame
	var str_signals: Node = get_node("/root/Signals")
	var bus: Node = get_node("/root/DeadhandEventBus")
	assert_not_null(str_signals, "STR Signals autoload should be present")
	assert_not_null(bus, "DeadhandEventBus autoload should be present")
	for signal_name in BRIDGED_SIGNALS:
		assert_true(
			str_signals.has_signal(signal_name),
			"STR Signals should declare %s" % signal_name
		)
		var handler_name: String = HANDLER_BY_SIGNAL[signal_name]
		var handler := Callable(bus, handler_name)
		assert_true(
			str_signals.is_connected(signal_name, handler),
			"DeadhandEventBus.%s should be connected to STR.%s" % [handler_name, signal_name]
		)


func test_card_drawn_forwards_to_bus() -> void:
	await get_tree().process_frame
	var str_signals: Node = get_node("/root/Signals")
	var bus: Node = get_node("/root/DeadhandEventBus")
	assert_true(
		Global._id_to_card_data.has("2_spades"),
		"Starter card 2_spades should be loaded for bridge simulation"
	)
	var card: CardData = Global._id_to_card_data["2_spades"]
	var bridged: Array = []
	var drawn: Array = []
	bus.bridged_str_signal.connect(func(payload: BridgedSTRSignalPayload) -> void:
		bridged.append(payload)
	)
	bus.card_drawn.connect(func(payload: CardDrawnPayload) -> void:
		drawn.append(payload)
	)
	str_signals.card_drawn.emit(card)
	assert_eq(bridged.size(), 1, "card_drawn should emit bridged_str_signal")
	assert_eq(bridged[0].signal_name, "card_drawn")
	assert_eq(bridged[0].str_args.get("object_id", ""), "2_spades")
	assert_eq(drawn.size(), 1, "card_drawn should emit native card_drawn")
	assert_eq(drawn[0].card_id, "2_spades")
	assert_eq(drawn[0].to, "hand")


func test_card_discarded_forwards_to_bus() -> void:
	await get_tree().process_frame
	var str_signals: Node = get_node("/root/Signals")
	var bus: Node = get_node("/root/DeadhandEventBus")
	assert_true(Global._id_to_card_data.has("3_hearts"))
	var card: CardData = Global._id_to_card_data["3_hearts"]
	var bridged: Array = []
	var discarded: Array = []
	bus.bridged_str_signal.connect(func(payload: BridgedSTRSignalPayload) -> void:
		bridged.append(payload)
	)
	bus.card_discarded.connect(func(payload: CardDiscardedPayload) -> void:
		discarded.append(payload)
	)
	str_signals.card_discarded.emit(card, true)
	assert_eq(bridged.size(), 1)
	assert_eq(bridged[0].signal_name, "card_discarded")
	assert_eq(bridged[0].str_args.get("is_manual_discard", null), true)
	assert_eq(discarded.size(), 1)
	assert_eq(discarded[0].card_id, "3_hearts")
	assert_eq(discarded[0].is_manual, true)
