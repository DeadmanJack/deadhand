# === MODULE: ResolutionEngine ===
# Purpose: Skill check and contested resolution math for Deadhand encounters.
# Owns:    (stateless — pure resolution helpers)
#
# Consumes events:
#   - CheckStartRequested, CardPlayed, EncounterCommitted   # future TaskResolver wiring
#
# Emits events:
#   - CheckResolved(success, sum, dc) via DeadhandEventBus
#
# Invariants:
#   - Solo checks: matching suit contributes full value; off-suit number cards halve (floor).
#   - critical_success when sum >= dc + 5 on a successful solo check (GDD §4.3).
#
# Does NOT:
#   - Draw or discard cards (see DeckManager).
#   - Apply task rewards or notoriety (see TaskResolver / RunState).
#   - Run contested encounter rounds (see ContestedEncounterRunner).
extends Node

const CRITICAL_MARGIN := 5


func resolve_solo_check(task: DeadhandTaskData, played_card_values: Array) -> Dictionary:
	var primary_suit: String = task.task_primary_suit
	var dc: int = task.task_difficulty_class
	var total: int = 0

	for card_entry: Variant in played_card_values:
		if card_entry is Dictionary:
			total += _effective_card_value(card_entry, primary_suit)

	var success: bool = total >= dc
	var critical_success: bool = success and total >= dc + CRITICAL_MARGIN

	return {
		"success": success,
		"sum": total,
		"dc": dc,
		"critical_success": critical_success,
	}


func resolve_and_emit(task: DeadhandTaskData, played_card_values: Array) -> Dictionary:
	var result: Dictionary = resolve_solo_check(task, played_card_values)
	var bus := _get_bus()
	if bus != null and bus.has_method("emit_check_resolved"):
		bus.emit_check_resolved(task.object_id, result.sum, result.dc, result.success)
	return result


func _effective_card_value(card: Dictionary, primary_suit: String) -> int:
	var base_value: int = int(card.get("value", 0))
	if card.get("is_ace", false) and card.has("ace_declared_value"):
		base_value = int(card.ace_declared_value)

	var suit: String = str(card.get("suit", ""))
	if primary_suit.is_empty() or suit == primary_suit:
		return base_value
	return base_value >> 1


func _get_bus() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/DeadhandEventBus")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DeadhandEventBus")
	return null
