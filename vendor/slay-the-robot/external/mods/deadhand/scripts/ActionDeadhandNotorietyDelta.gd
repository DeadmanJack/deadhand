## Applies a notoriety delta via DeadhandNotorietyTracker.
extends BaseAction


func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([null])

	for action_interceptor_processor in action_interceptor_processors:
		var delta: int = action_interceptor_processor.get_shadowed_action_values("delta", 0)
		var reason: String = action_interceptor_processor.get_shadowed_action_values("reason", "")
		var tracker: Node = _get_notoriety_tracker()
		if tracker != null and tracker.has_method("apply_delta"):
			tracker.apply_delta(delta, reason)


func is_instant_action() -> bool:
	return true


func _get_notoriety_tracker() -> Node:
	if Engine.has_singleton("DeadhandNotorietyTracker"):
		return Engine.get_singleton("DeadhandNotorietyTracker")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DeadhandNotorietyTracker")
	return null
