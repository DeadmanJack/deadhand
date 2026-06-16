extends Resource
class_name RunEndedPayload

@export var reason: String = ""
@export var victory: bool = false


func to_dict() -> Dictionary:
	return {
		"reason": reason,
		"victory": victory,
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := RunEndedPayload.new()
	payload.reason = d.get("reason", "")
	payload.victory = d.get("victory", false)
	return payload
