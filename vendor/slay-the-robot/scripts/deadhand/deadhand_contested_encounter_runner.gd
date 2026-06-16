# === MODULE: ContestedEncounterRunner ===
# Purpose: Head-to-head contested encounter state machine (3-shot simultaneous reveal).
# Owns:    Encounter round state, per-side wound tracks, cumulative reveal sums, outcome.
#
# Consumes events:
#   - (none — callers invoke start_encounter directly)
#
# Emits events:
#   - encounter_started, shot_resolved, encounter_resolved via DeadhandEventBus
#
# Invariants:
#   - All contested randomness uses DeadhandRNGService track "rng_contested".
#   - State progresses IDLE → IN_ROUND → RESOLVED exactly once per start_encounter call.
#
# Does NOT:
#   - Draw cards from decks or mutate RunState.
#   - Render UI or register as an autoload (W3-5 may wire later).
extends RefCounted

const RNG_TRACK: String = "rng_contested"
const OUTCOME_PLAYER_WIN: String = "player_win"
const OUTCOME_PLAYER_LOSE: String = "player_lose"
const WINNER_PLAYER: String = "player"
const WINNER_OPPONENT: String = "opponent"
const WINNER_TIE: String = "tie"

enum State { IDLE, IN_ROUND, RESOLVED }

var state: State = State.IDLE

var _encounter_data: DeadhandContestedEncounterData = null
var _player_wounds: int = 0
var _opponent_wounds: int = 0
var _player_revealed_sum: int = 0
var _opponent_revealed_sum: int = 0
var _rounds_played: int = 0
var _outcome: String = ""
var _rng_service = null
var _event_bus: Node = null


func _init(rng_service = null, event_bus: Node = null) -> void:
	_rng_service = rng_service
	_event_bus = event_bus


func start_encounter(
	encounter_data: DeadhandContestedEncounterData,
	player_hand_values: Array,
	opponent_hand_values: Array,
) -> void:
	assert(state == State.IDLE, "start_encounter requires IDLE state")
	assert(encounter_data != null, "encounter_data is required")

	_encounter_data = encounter_data
	_player_wounds = 0
	_opponent_wounds = 0
	_player_revealed_sum = 0
	_opponent_revealed_sum = 0
	_rounds_played = 0
	_outcome = ""
	state = State.IN_ROUND

	_get_rng_service().roll(RNG_TRACK, 1000)
	_emit_encounter_started(encounter_data.object_id)

	var max_rounds: int = maxi(encounter_data.contested_rounds, 0)
	for round_index in max_rounds:
		if _is_side_defeated():
			break
		if round_index >= player_hand_values.size() or round_index >= opponent_hand_values.size():
			break

		_rounds_played += 1
		var player_effective: int = _resolve_card_play(player_hand_values[round_index])
		var opponent_effective: int = _resolve_card_play(opponent_hand_values[round_index])
		_player_revealed_sum += player_effective
		_opponent_revealed_sum += opponent_effective

		var round_winner: String = _determine_round_winner(player_effective, opponent_effective)
		_apply_round_wounds(round_winner)
		_apply_bust_extra_wound(round_winner)
		_emit_shot_resolved(encounter_data.object_id, _rounds_played, round_winner)

		if _is_side_defeated():
			break

	_outcome = _determine_outcome()
	state = State.RESOLVED
	_emit_encounter_resolved(encounter_data.object_id, _outcome)


func get_outcome() -> String:
	return _outcome


func get_player_wounds() -> int:
	return _player_wounds


func get_opponent_wounds() -> int:
	return _opponent_wounds


func get_player_revealed_sum() -> int:
	return _player_revealed_sum


func get_opponent_revealed_sum() -> int:
	return _opponent_revealed_sum


func get_rounds_played() -> int:
	return _rounds_played


func _resolve_card_play(entry: Variant) -> int:
	var card: Dictionary = _pick_card_entry(entry)
	var base_value: int = int(card.get("value", 0))
	var suit: String = str(card.get("suit", _encounter_data.contested_primary_suit))
	return _effective_value(base_value, suit)


func _pick_card_entry(entry: Variant) -> Dictionary:
	if entry is Array:
		var picked: Variant = _get_rng_service().pick(RNG_TRACK, entry)
		return _normalize_card_entry(picked)
	return _normalize_card_entry(entry)


func _normalize_card_entry(entry: Variant) -> Dictionary:
	if entry is Dictionary:
		return entry
	if entry is int or entry is float:
		return {"value": int(entry), "suit": _encounter_data.contested_primary_suit}
	push_error("Invalid contested card entry: %s" % str(entry))
	return {"value": 0, "suit": _encounter_data.contested_primary_suit}


func _effective_value(base_value: int, suit: String) -> int:
	var primary_suit: String = _encounter_data.contested_primary_suit
	if primary_suit.is_empty() or suit == primary_suit:
		return base_value
	return base_value >> 1


func _determine_round_winner(player_effective: int, opponent_effective: int) -> String:
	if player_effective > opponent_effective:
		return WINNER_PLAYER
	if opponent_effective > player_effective:
		return WINNER_OPPONENT
	return WINNER_TIE


func _apply_round_wounds(round_winner: String) -> void:
	match round_winner:
		WINNER_PLAYER:
			_opponent_wounds += 1
		WINNER_OPPONENT:
			_player_wounds += 1
		WINNER_TIE:
			_player_wounds += 1
			_opponent_wounds += 1


func _apply_bust_extra_wound(round_winner: String) -> void:
	var bust_line: int = _encounter_data.contested_bust_line
	if bust_line <= 0:
		return

	match round_winner:
		WINNER_PLAYER:
			if _opponent_revealed_sum > bust_line:
				_opponent_wounds += 1
		WINNER_OPPONENT:
			if _player_revealed_sum > bust_line:
				_player_wounds += 1
		WINNER_TIE:
			if _player_revealed_sum > bust_line:
				_player_wounds += 1
			if _opponent_revealed_sum > bust_line:
				_opponent_wounds += 1


func _is_side_defeated() -> bool:
	return (
		_player_wounds >= _encounter_data.contested_player_wound_limit
		or _opponent_wounds >= _encounter_data.contested_opponent_wound_limit
	)


func _determine_outcome() -> String:
	if _player_wounds >= _encounter_data.contested_player_wound_limit:
		return OUTCOME_PLAYER_LOSE
	if _opponent_wounds >= _encounter_data.contested_opponent_wound_limit:
		return OUTCOME_PLAYER_WIN

	var player_wounds_dealt: int = _opponent_wounds
	var opponent_wounds_dealt: int = _player_wounds
	if player_wounds_dealt > opponent_wounds_dealt:
		return OUTCOME_PLAYER_WIN
	if opponent_wounds_dealt > player_wounds_dealt:
		return OUTCOME_PLAYER_LOSE
	return OUTCOME_PLAYER_LOSE


func _get_rng_service():
	if _rng_service != null:
		return _rng_service
	if Engine.has_singleton("DeadhandRNGService"):
		return Engine.get_singleton("DeadhandRNGService")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var node: Node = tree.root.get_node_or_null("DeadhandRNGService")
		if node != null:
			return node
	return load("res://autoload/deadhand_rng_service.gd").new()


func _get_event_bus() -> Node:
	if _event_bus != null:
		return _event_bus
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DeadhandEventBus")
	return null


func _emit_encounter_started(encounter_id: String) -> void:
	var bus: Node = _get_event_bus()
	if bus != null and bus.has_method("emit_encounter_started"):
		bus.emit_encounter_started(encounter_id)


func _emit_shot_resolved(encounter_id: String, round: int, winner: String) -> void:
	var bus: Node = _get_event_bus()
	if bus != null and bus.has_method("emit_shot_resolved"):
		bus.emit_shot_resolved(encounter_id, round, winner)


func _emit_encounter_resolved(encounter_id: String, outcome: String) -> void:
	var bus: Node = _get_event_bus()
	if bus != null and bus.has_method("emit_encounter_resolved"):
		bus.emit_encounter_resolved(encounter_id, outcome)
