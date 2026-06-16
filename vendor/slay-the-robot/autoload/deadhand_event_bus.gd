# === MODULE: EventBus ===
# Purpose: Central pub/sub for Deadhand domain events with typed Resource payloads.
# Owns:    Typed signal declarations and emit_* helpers; STR Signals bridge.
#
# Consumes events:
#   - STR Signals.card_drawn (when /root/Signals autoload is present)
#
# Emits events:
#   - card_drawn, card_played, card_discarded, card_burned
#   - check_resolved, shot_resolved, encounter_started, encounter_resolved
#   - phase_advanced, day_advanced, rest_forced
#   - notoriety_changed, money_changed, loot_rolled
#   - hidden_trigger_fired, memory_card_revealed, journal_entry_unlocked
#   - set_bonus_activated, set_bonus_deactivated
#   - run_started, run_ended, rng_rolled, bridged_str_signal
#
# Invariants:
#   - Every emit_* helper constructs exactly one payload Resource before emitting.
#   - STR bridge is best-effort; missing Signals autoload is a no-op.
#
# Does NOT:
#   - Persist events (see EventLog).
#   - Mutate RunState or any gameplay module directly.
#   - Replace STR's Signals autoload.
extends Node
class_name DeadhandEventBus

signal card_drawn(payload: CardDrawnPayload)
signal card_played(payload: CardPlayedPayload)
signal card_discarded(payload: CardDiscardedPayload)
signal card_burned(payload: CardBurnedPayload)
signal check_resolved(payload: CheckResolvedPayload)
signal shot_resolved(payload: ShotResolvedPayload)
signal encounter_started(payload: EncounterStartedPayload)
signal encounter_resolved(payload: EncounterResolvedPayload)
signal phase_advanced(payload: PhaseAdvancedPayload)
signal day_advanced(payload: DayAdvancedPayload)
signal rest_forced(payload: RestForcedPayload)
signal notoriety_changed(payload: NotorietyChangedPayload)
signal money_changed(payload: MoneyChangedPayload)
signal loot_rolled(payload: LootRolledPayload)
signal hidden_trigger_fired(payload: HiddenTriggerFiredPayload)
signal memory_card_revealed(payload: MemoryCardRevealedPayload)
signal journal_entry_unlocked(payload: JournalEntryUnlockedPayload)
signal set_bonus_activated(payload: SetBonusActivatedPayload)
signal set_bonus_deactivated(payload: SetBonusDeactivatedPayload)
signal run_started(payload: RunStartedPayload)
signal run_ended(payload: RunEndedPayload)
signal rng_rolled(payload: RNGRolledPayload)
signal bridged_str_signal(payload: BridgedSTRSignalPayload)


func _ready() -> void:
	_bridge_str_signals()


func emit_card_drawn(card_id: String, to: String = "hand") -> void:
	var payload := CardDrawnPayload.new()
	payload.card_id = card_id
	payload.to = to
	card_drawn.emit(payload)


func emit_card_played(card_id: String, in_check: String = "") -> void:
	var payload := CardPlayedPayload.new()
	payload.card_id = card_id
	payload.in_check = in_check
	card_played.emit(payload)


func emit_card_discarded(card_id: String, is_manual: bool = false) -> void:
	var payload := CardDiscardedPayload.new()
	payload.card_id = card_id
	payload.is_manual = is_manual
	card_discarded.emit(payload)


func emit_card_burned(card_id: String, reason: String = "") -> void:
	var payload := CardBurnedPayload.new()
	payload.card_id = card_id
	payload.reason = reason
	card_burned.emit(payload)


func emit_check_resolved(task: String, sum: int, dc: int, success: bool) -> void:
	var payload := CheckResolvedPayload.new()
	payload.task = task
	payload.sum = sum
	payload.dc = dc
	payload.success = success
	check_resolved.emit(payload)


func emit_shot_resolved(encounter_id: String, round: int, winner: String) -> void:
	var payload := ShotResolvedPayload.new()
	payload.encounter_id = encounter_id
	payload.round = round
	payload.winner = winner
	shot_resolved.emit(payload)


func emit_encounter_started(encounter_id: String) -> void:
	var payload := EncounterStartedPayload.new()
	payload.encounter_id = encounter_id
	encounter_started.emit(payload)


func emit_encounter_resolved(encounter_id: String, outcome: String) -> void:
	var payload := EncounterResolvedPayload.new()
	payload.encounter_id = encounter_id
	payload.outcome = outcome
	encounter_resolved.emit(payload)


func emit_phase_advanced(day: int, phase: String) -> void:
	var payload := PhaseAdvancedPayload.new()
	payload.day = day
	payload.phase = phase
	phase_advanced.emit(payload)


func emit_day_advanced(day: int) -> void:
	var payload := DayAdvancedPayload.new()
	payload.day = day
	day_advanced.emit(payload)


func emit_rest_forced(reason: String, location: String = "") -> void:
	var payload := RestForcedPayload.new()
	payload.reason = reason
	payload.location = location
	rest_forced.emit(payload)


func emit_notoriety_changed(old_value: int, new_value: int, reason: String = "") -> void:
	var payload := NotorietyChangedPayload.new()
	payload.old_value = old_value
	payload.new_value = new_value
	payload.reason = reason
	notoriety_changed.emit(payload)


func emit_money_changed(old_value: int, new_value: int, delta: int, reason: String = "") -> void:
	var payload := MoneyChangedPayload.new()
	payload.old_value = old_value
	payload.new_value = new_value
	payload.delta = delta
	payload.reason = reason
	money_changed.emit(payload)


func emit_loot_rolled(table: String, items: Array[String]) -> void:
	var payload := LootRolledPayload.new()
	payload.table = table
	payload.items = items.duplicate()
	loot_rolled.emit(payload)


func emit_hidden_trigger_fired(trigger_id: String) -> void:
	var payload := HiddenTriggerFiredPayload.new()
	payload.trigger_id = trigger_id
	hidden_trigger_fired.emit(payload)


func emit_memory_card_revealed(card_id: String) -> void:
	var payload := MemoryCardRevealedPayload.new()
	payload.card_id = card_id
	memory_card_revealed.emit(payload)


func emit_journal_entry_unlocked(entry_id: String) -> void:
	var payload := JournalEntryUnlockedPayload.new()
	payload.entry_id = entry_id
	journal_entry_unlocked.emit(payload)


func emit_set_bonus_activated(set_id: String, bonus_id: String) -> void:
	var payload := SetBonusActivatedPayload.new()
	payload.set_id = set_id
	payload.bonus_id = bonus_id
	set_bonus_activated.emit(payload)


func emit_set_bonus_deactivated(set_id: String, bonus_id: String) -> void:
	var payload := SetBonusDeactivatedPayload.new()
	payload.set_id = set_id
	payload.bonus_id = bonus_id
	set_bonus_deactivated.emit(payload)


func emit_run_started(seed: int, starter_deck_id: String = "default", run_uuid: String = "") -> void:
	var payload := RunStartedPayload.new()
	payload.seed = seed
	payload.starter_deck_id = starter_deck_id
	payload.run_uuid = run_uuid
	run_started.emit(payload)


func emit_run_ended(reason: String, victory: bool = false) -> void:
	var payload := RunEndedPayload.new()
	payload.reason = reason
	payload.victory = victory
	run_ended.emit(payload)


func emit_rng_rolled(channel: String, result: Variant) -> void:
	var payload := RNGRolledPayload.new()
	payload.channel = channel
	payload.result = result
	rng_rolled.emit(payload)


func emit_bridged_str_signal(signal_name: String, str_args: Dictionary) -> void:
	var payload := BridgedSTRSignalPayload.new()
	payload.signal_name = signal_name
	payload.str_args = str_args.duplicate(true)
	bridged_str_signal.emit(payload)


func _bridge_str_signals() -> void:
	var str_signals: Node = get_node_or_null("/root/Signals")
	if str_signals == null:
		return
	if str_signals.has_signal("card_drawn") and not str_signals.is_connected("card_drawn", _on_str_card_drawn):
		str_signals.card_drawn.connect(_on_str_card_drawn)


func _on_str_card_drawn(card: CardData) -> void:
	var card_id: String = card.object_id if card != null else ""
	emit_card_drawn(card_id, "hand")
	emit_bridged_str_signal("card_drawn", {
		"object_id": card_id,
		"card_name": card.card_name if card != null else "",
	})
