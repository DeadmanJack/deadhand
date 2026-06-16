extends Resource
class_name TaskAvailabilityChangedPayload

@export var phase: String = "morning"
@export var available_task_ids: Array[String] = []


func to_dict() -> Dictionary:
	return {
		"phase": phase,
		"available_task_ids": available_task_ids.duplicate(),
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := TaskAvailabilityChangedPayload.new()
	payload.phase = d.get("phase", "morning")
	var ids: Variant = d.get("available_task_ids", [])
	if ids is Array:
		for id: Variant in ids:
			if id is String:
				payload.available_task_ids.append(id)
	return payload
