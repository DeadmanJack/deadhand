extends GutTest

const DeadhandRNGServiceScript = preload("res://autoload/deadhand_rng_service.gd")


func before_each() -> void:
	DeadhandRNGServiceScript.use_deterministic_uids = false
	DeadhandRNGServiceScript.deterministic_run_seed = 0
	DeadhandRNGServiceScript.reset_fallback_for_tests()


func _make_service(seed: int) -> DeadhandRNGService:
	var service := DeadhandRNGServiceScript.new()
	service.set_run_seed(seed)
	return service


func _collect_rolls(service: DeadhandRNGService, track_name: String, count: int) -> Array[int]:
	var rolls: Array[int] = []
	for _i in count:
		rolls.append(service.roll(track_name, 1000))
	return rolls


func test_same_seed_produces_identical_roll_sequences() -> void:
	var service_a := _make_service(42)
	var service_b := _make_service(42)
	var rolls_a := _collect_rolls(service_a, "rng_test", 10)
	var rolls_b := _collect_rolls(service_b, "rng_test", 10)
	assert_eq(rolls_a, rolls_b, "Same seed should yield identical roll sequences")


func test_track_isolation() -> void:
	var service := _make_service(42)
	var combat_rolls := _collect_rolls(service, "rng_combat", 10)
	var loot_rolls := _collect_rolls(service, "rng_loot", 10)
	assert_ne(combat_rolls, loot_rolls, "Different tracks should produce different sequences")


func test_uid_determinism() -> void:
	DeadhandRNGServiceScript.use_deterministic_uids = true
	DeadhandRNGServiceScript.deterministic_run_seed = 42
	DeadhandRNGServiceScript.reset_fallback_for_tests()

	var card_a := CardData.new()
	var uid_a: String = PrototypeData.generate_unique_id(card_a)

	DeadhandRNGServiceScript.reset_fallback_for_tests()
	DeadhandRNGServiceScript.deterministic_run_seed = 42

	var card_b := CardData.new()
	var uid_b: String = PrototypeData.generate_unique_id(card_b)

	assert_eq(uid_a, uid_b, "Same seed should yield identical deterministic UIDs")
	assert_true(uid_a.contains("-42-prototype_uid-"), "UID should contain run seed and track name")
