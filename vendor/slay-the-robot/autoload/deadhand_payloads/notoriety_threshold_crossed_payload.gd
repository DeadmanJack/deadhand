extends Resource
class_name NotorietyThresholdCrossedPayload

@export var threshold: int = 0
@export var direction: String = ""


func to_dict() -> Dictionary:
	return {
		"threshold": threshold,
		"direction": direction,
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := NotorietyThresholdCrossedPayload.new()
	payload.threshold = d.get("threshold", 0)
	payload.direction = d.get("direction", "")
	return payload
