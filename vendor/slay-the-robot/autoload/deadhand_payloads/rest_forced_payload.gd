extends Resource
class_name RestForcedPayload

@export var reason: String = ""
@export var location: String = ""


func to_dict() -> Dictionary:
	return {"reason": reason, "location": location}


static func from_dict(d: Dictionary) -> Resource:
	var payload := RestForcedPayload.new()
	payload.reason = d.get("reason", "")
	payload.location = d.get("location", "")
	return payload
