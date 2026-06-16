## Reveals a memory card and unlocks the linked journal entry on the EventBus.
extends BaseAction


func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([null])

	for action_interceptor_processor in action_interceptor_processors:
		var journal_entry_id: String = action_interceptor_processor.get_shadowed_action_values(
			"journal_entry_id", ""
		)
		var card_id: String = action_interceptor_processor.get_shadowed_action_values("card_id", "")

		if card_id.is_empty():
			var card_data: CardData = get_action_card_data()
			if card_data != null:
				card_id = card_data.object_id

		var bus: Node = _get_event_bus()
		if bus == null:
			continue
		if not card_id.is_empty() and bus.has_method("emit_memory_card_revealed"):
			bus.emit_memory_card_revealed(card_id)
		if not journal_entry_id.is_empty() and bus.has_method("emit_journal_entry_unlocked"):
			bus.emit_journal_entry_unlocked(journal_entry_id)


func is_instant_action() -> bool:
	return true


func _get_event_bus() -> Node:
	if Engine.has_singleton("DeadhandEventBus"):
		return Engine.get_singleton("DeadhandEventBus")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DeadhandEventBus")
	return null
