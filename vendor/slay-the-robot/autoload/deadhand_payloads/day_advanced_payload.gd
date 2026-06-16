extends Resource
class_name DayAdvancedPayload

@export var day: int = 1


func to_dict() -> Dictionary:
	return {"day": day}


static func from_dict(d: Dictionary) -> Resource:
	var payload := DayAdvancedPayload.new()
	payload.day = d.get("day", 1)
	return payload
