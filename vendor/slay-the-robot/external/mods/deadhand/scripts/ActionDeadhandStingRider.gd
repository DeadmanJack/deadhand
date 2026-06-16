## MVP sting rider: applies immediate wounds when timing is "immediate".
extends BaseAction


func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([null])

	for action_interceptor_processor in action_interceptor_processors:
		var wound_amount: int = action_interceptor_processor.get_shadowed_action_values("wound_amount", 0)
		var timing: String = action_interceptor_processor.get_shadowed_action_values("timing", "")

		if timing != "immediate" or wound_amount <= 0:
			continue

		var run_state: Node = _get_run_state()
		if run_state == null or not run_state.has_method("get_player_wounds"):
			continue
		var new_wounds: int = run_state.get_player_wounds() + wound_amount
		if run_state.has_method("set_wounds"):
			run_state.set_wounds(new_wounds, "sting_rider")


func is_instant_action() -> bool:
	return true


func _get_run_state() -> Node:
	if Engine.has_singleton("DeadhandRunState"):
		return Engine.get_singleton("DeadhandRunState")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DeadhandRunState")
	return null
