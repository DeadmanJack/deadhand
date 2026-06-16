extends Resource
class_name CheckResolvedPayload

@export var task: String = ""
@export var sum: int = 0
@export var dc: int = 0
@export var success: bool = false


func to_dict() -> Dictionary:
	return {"task": task, "sum": sum, "dc": dc, "success": success}


static func from_dict(d: Dictionary) -> Resource:
	var payload := CheckResolvedPayload.new()
	payload.task = d.get("task", "")
	payload.sum = d.get("sum", 0)
	payload.dc = d.get("dc", 0)
	payload.success = d.get("success", false)
	return payload
