extends Resource
class_name CardPlayedPayload

@export var card_id: String = ""
@export var in_check: String = ""


func to_dict() -> Dictionary:
	return {
		"card_id": card_id,
		"in_check": in_check,
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := CardPlayedPayload.new()
	payload.card_id = d.get("card_id", "")
	payload.in_check = d.get("in_check", "")
	return payload
