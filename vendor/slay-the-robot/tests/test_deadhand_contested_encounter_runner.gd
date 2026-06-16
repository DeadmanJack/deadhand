extends GutTest

const RunnerScript = preload("res://scripts/deadhand/deadhand_contested_encounter_runner.gd")
const RNGServiceScript = preload("res://autoload/deadhand_rng_service.gd")

const TEST_SEED: int = 42
const ENCOUNTER_ID: String = "encounter_town_drunk"


func before_each() -> void:
	var rng: Node = get_node("/root/DeadhandRNGService")
	rng.set_run_seed(TEST_SEED)


func _make_runner() -> RefCounted:
	return RunnerScript.new(get_node("/root/DeadhandRNGService"), get_node("/root/DeadhandEventBus"))


func _town_drunk_hand_values() -> Dictionary:
	return {
		"player": [
			{"value": 10, "suit": "spades"},
			{"value": 8, "suit": "spades"},
			{"value": 7, "suit": "spades"},
		],
		"opponent": [
			[{"value": 9, "suit": "spades"}, {"value": 7, "suit": "spades"}],
			{"value": 9, "suit": "spades"},
			{"value": 8, "suit": "spades"},
		],
	}


func _run_town_drunk_scenario(runner: RefCounted, encounter_data: DeadhandContestedEncounterData) -> Dictionary:
	var hands: Dictionary = _town_drunk_hand_values()
	runner.start_encounter(encounter_data, hands.player, hands.opponent)
	return {
		"outcome": runner.get_outcome(),
		"player_wounds": runner.get_player_wounds(),
		"opponent_wounds": runner.get_opponent_wounds(),
		"player_sum": runner.get_player_revealed_sum(),
		"opponent_sum": runner.get_opponent_revealed_sum(),
		"rounds": runner.get_rounds_played(),
		"state": runner.state,
	}


func _load_encounter_data() -> DeadhandContestedEncounterData:
	assert_true(
		Global._id_to_deadhand_contested_encounter_data.has(ENCOUNTER_ID),
		"encounter_town_drunk should load from Deadhand mod overlay"
	)
	return Global.get_deadhand_contested_encounter_data(ENCOUNTER_ID)


func test_town_drunk_deterministic_scenario_and_events() -> void:
	var encounter_data: DeadhandContestedEncounterData = _load_encounter_data()
	assert_eq(encounter_data.contested_primary_suit, "spades")
	assert_eq(encounter_data.contested_bust_line, 21)
	assert_eq(encounter_data.contested_rounds, 3)

	var events: Array = []
	var bus: Node = get_node("/root/DeadhandEventBus")
	bus.encounter_started.connect(func(payload: EncounterStartedPayload) -> void:
		events.append({"type": "encounter_started", "encounter_id": payload.encounter_id})
	)
	bus.shot_resolved.connect(func(payload: ShotResolvedPayload) -> void:
		events.append({
			"type": "shot_resolved",
			"encounter_id": payload.encounter_id,
			"round": payload.round,
			"winner": payload.winner,
		})
	)
	bus.encounter_resolved.connect(func(payload: EncounterResolvedPayload) -> void:
		events.append({"type": "encounter_resolved", "encounter_id": payload.encounter_id, "outcome": payload.outcome})
	)

	var runner_a := _make_runner()
	var result_a: Dictionary = _run_town_drunk_scenario(runner_a, encounter_data)
	var events_first_run: Array = events.duplicate(true)

	events.clear()
	get_node("/root/DeadhandRNGService").set_run_seed(TEST_SEED)
	var runner_b := _make_runner()
	var result_b: Dictionary = _run_town_drunk_scenario(runner_b, encounter_data)

	assert_eq(result_a, result_b, "Same seed should reproduce identical encounter outcome")
	events = events_first_run
	assert_eq(result_a.state, RunnerScript.State.RESOLVED)
	assert_eq(result_a.rounds, 3)
	assert_eq(result_a.player_sum, 25, "Player cumulative reveal sum should exceed bust line")
	assert_eq(result_a.opponent_sum, 26)
	assert_eq(result_a.player_wounds, 3, "Player should lose on wound limit after bust extra")
	assert_eq(result_a.opponent_wounds, 1)
	assert_eq(result_a.outcome, RunnerScript.OUTCOME_PLAYER_LOSE)

	var expected_events: Array = [
		{"type": "encounter_started", "encounter_id": ENCOUNTER_ID},
		{"type": "shot_resolved", "encounter_id": ENCOUNTER_ID, "round": 1, "winner": RunnerScript.WINNER_PLAYER},
		{"type": "shot_resolved", "encounter_id": ENCOUNTER_ID, "round": 2, "winner": RunnerScript.WINNER_OPPONENT},
		{"type": "shot_resolved", "encounter_id": ENCOUNTER_ID, "round": 3, "winner": RunnerScript.WINNER_OPPONENT},
		{"type": "encounter_resolved", "encounter_id": ENCOUNTER_ID, "outcome": RunnerScript.OUTCOME_PLAYER_LOSE},
	]
	assert_eq(events, expected_events, "EventBus should emit encounter lifecycle in order")


func test_off_suit_halving_and_player_win() -> void:
	var encounter_data: DeadhandContestedEncounterData = DeadhandContestedEncounterData.new()
	encounter_data.object_id = "encounter_test_win"
	encounter_data.contested_primary_suit = "spades"
	encounter_data.contested_rounds = 3
	encounter_data.contested_bust_line = 0
	encounter_data.contested_player_wound_limit = 3
	encounter_data.contested_opponent_wound_limit = 2

	var runner := _make_runner()
	runner.start_encounter(
		encounter_data,
		[
			{"value": 10, "suit": "spades"},
			{"value": 7, "suit": "hearts"},
			{"value": 8, "suit": "spades"},
		],
		[
			{"value": 3, "suit": "spades"},
			{"value": 5, "suit": "spades"},
			{"value": 2, "suit": "spades"},
		],
	)

	assert_eq(runner.get_outcome(), RunnerScript.OUTCOME_PLAYER_WIN)
	assert_eq(runner.get_opponent_wounds(), 2)
	assert_eq(runner.get_player_wounds(), 1)
	assert_eq(runner.get_player_revealed_sum(), 21)
	assert_eq(runner.get_opponent_revealed_sum(), 10)


func test_mutual_shot_tie() -> void:
	var encounter_data: DeadhandContestedEncounterData = DeadhandContestedEncounterData.new()
	encounter_data.object_id = "encounter_test_tie"
	encounter_data.contested_primary_suit = "spades"
	encounter_data.contested_rounds = 1
	encounter_data.contested_bust_line = 0
	encounter_data.contested_player_wound_limit = 3
	encounter_data.contested_opponent_wound_limit = 3

	var events: Array = []
	get_node("/root/DeadhandEventBus").shot_resolved.connect(func(payload: ShotResolvedPayload) -> void:
		events.append(payload.winner)
	)

	var runner := _make_runner()
	runner.start_encounter(
		encounter_data,
		[{"value": 6, "suit": "spades"}],
		[{"value": 6, "suit": "spades"}],
	)

	assert_eq(events, [RunnerScript.WINNER_TIE])
	assert_eq(runner.get_player_wounds(), 1)
	assert_eq(runner.get_opponent_wounds(), 1)
