extends Resource
class_name HiddenTriggerFiredPayload

@export var trigger_id: String = ""


func to_dict() -> Dictionary:
	return {"trigger_id": trigger_id}


static func from_dict(d: Dictionary) -> Resource:
	var payload := HiddenTriggerFiredPayload.new()
	payload.trigger_id = d.get("trigger_id", "")
	return payload
