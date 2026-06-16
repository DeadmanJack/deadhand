# === MODULE: RNGService ===
# Purpose: Seeded, track-isolated randomness for deterministic Deadhand runs.
# Owns:    int run_seed; per-track RandomNumberGenerator instances; per-track UID counters.
#
# Consumes events:
#   - (none — callers invoke methods directly until EventBus wiring in W2-5+)
#
# Emits events:
#   - rng_rolled(track_name:String, result:Variant) on DeadhandEventBus when present
#
# Invariants:
#   - All gameplay randomness for Deadhand flows through this service (§3.1 TDD).
#   - Each track_name gets an independent RNG seeded from run_seed + track hash.
#   - generate_deterministic_uid format: "<prefix>-<run_seed>-<track>-<counter>".
#
# Does NOT:
#   - Replace STR's autoload/Random.gd helpers (shuffle, weighted pick, etc.).
#   - Register as a project autoload until W2-5 (tests instantiate directly).
extends Node

## When true, PrototypeData.generate_unique_id() uses deterministic UIDs via this service.
static var use_deterministic_uids: bool = false
## Run seed used by generate_uid_static() when no autoload instance is registered.
static var deterministic_run_seed: int = 0

static var _fallback_service = null

var run_seed: int = 0
var track_counters: Dictionary[String, int] = {}

var _track_rngs: Dictionary[String, RandomNumberGenerator] = {}


func set_run_seed(new_seed: int) -> void:
	run_seed = new_seed
	track_counters.clear()
	_track_rngs.clear()


func roll(track_name: String, max_exclusive: int) -> int:
	assert(max_exclusive > 0, "roll max_exclusive must be > 0")
	var result: int = _get_track_rng(track_name).randi() % max_exclusive
	_emit_rng_rolled(track_name, result)
	return result


func roll_range(track_name: String, min_val: int, max_val: int) -> int:
	var result: int = _get_track_rng(track_name).randi_range(min_val, max_val)
	_emit_rng_rolled(track_name, result)
	return result


func pick(track_name: String, array: Array) -> Variant:
	if array.is_empty():
		return null
	var index: int = roll(track_name, array.size())
	return array[index]


func generate_deterministic_uid(track_name: String, prefix: String = "") -> String:
	var counter: int = track_counters.get(track_name, 0) + 1
	track_counters[track_name] = counter
	return "%s-%d-%s-%d" % [prefix, run_seed, track_name, counter]


func _get_track_rng(track_name: String) -> RandomNumberGenerator:
	if not _track_rngs.has(track_name):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%s" % [run_seed, track_name])
		_track_rngs[track_name] = rng
	return _track_rngs[track_name]


static func generate_uid_static(prototype_data: PrototypeData) -> String:
	var service = _get_active_service()
	if service.run_seed != deterministic_run_seed:
		service.set_run_seed(deterministic_run_seed)
	var prefix: String = prototype_data.get_unique_id_prefix()
	return service.generate_deterministic_uid("prototype_uid", prefix)


static func _get_active_service():
	if Engine.has_singleton("DeadhandRNGService"):
		return Engine.get_singleton("DeadhandRNGService")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		var node: Node = tree.root.get_node_or_null("DeadhandRNGService")
		if node != null and node.has_method("set_run_seed"):
			return node
	if _fallback_service == null:
		_fallback_service = load("res://autoload/deadhand_rng_service.gd").new()
		_fallback_service.set_run_seed(deterministic_run_seed)
	return _fallback_service


func _ready() -> void:
	use_deterministic_uids = true


static func reset_fallback_for_tests() -> void:
	_fallback_service = null


func _emit_rng_rolled(track_name: String, result: Variant) -> void:
	var bus: Node = null
	if is_inside_tree():
		bus = get_node_or_null("/root/DeadhandEventBus")
	else:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null:
			bus = tree.root.get_node_or_null("DeadhandEventBus")
	if bus != null and bus.has_method("emit_rng_rolled"):
		bus.emit_rng_rolled(track_name, result)
