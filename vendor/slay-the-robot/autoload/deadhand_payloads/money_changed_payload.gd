extends Resource
class_name MoneyChangedPayload

@export var old_value: int = 0
@export var new_value: int = 0
@export var delta: int = 0
@export var reason: String = ""


func to_dict() -> Dictionary:
	return {
		"old_value": old_value,
		"new_value": new_value,
		"delta": delta,
		"reason": reason,
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := MoneyChangedPayload.new()
	payload.old_value = d.get("old_value", 0)
	payload.new_value = d.get("new_value", 0)
	payload.delta = d.get("delta", 0)
	payload.reason = d.get("reason", "")
	return payload
