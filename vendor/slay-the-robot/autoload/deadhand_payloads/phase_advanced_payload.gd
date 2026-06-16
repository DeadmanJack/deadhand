extends Resource
class_name PhaseAdvancedPayload

@export var day: int = 1
@export var phase: String = "morning"


func to_dict() -> Dictionary:
	return {
		"day": day,
		"phase": phase,
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := PhaseAdvancedPayload.new()
	payload.day = d.get("day", 1)
	payload.phase = d.get("phase", "morning")
	return payload
