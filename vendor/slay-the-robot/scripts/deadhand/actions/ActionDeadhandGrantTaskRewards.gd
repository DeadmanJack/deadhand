## Rolls task money rewards via rng_loot and applies the delta to RunState.
extends BaseAction


func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([null])

	for action_interceptor_processor in action_interceptor_processors:
		var money_min: int = action_interceptor_processor.get_shadowed_action_values("money_min", 0)
		var money_max: int = action_interceptor_processor.get_shadowed_action_values("money_max", money_min)
		var reason: String = action_interceptor_processor.get_shadowed_action_values("reason", "task_reward")

		if money_max < money_min:
			var swap: int = money_min
			money_min = money_max
			money_max = swap

		var payout: int = money_min
		if money_max > money_min:
			var rng_service: Node = _get_rng_service()
			if rng_service != null and rng_service.has_method("roll_range"):
				payout = rng_service.roll_range("rng_loot", money_min, money_max)

		var run_state: Node = _get_run_state()
		if run_state != null and run_state.has_method("apply_money_delta"):
			run_state.apply_money_delta(payout, reason)


func is_instant_action() -> bool:
	return true


func _get_rng_service() -> Node:
	if Engine.has_singleton("DeadhandRNGService"):
		return Engine.get_singleton("DeadhandRNGService")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DeadhandRNGService")
	return null


func _get_run_state() -> Node:
	if Engine.has_singleton("DeadhandRunState"):
		return Engine.get_singleton("DeadhandRunState")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DeadhandRunState")
	return null
