extends Resource
class_name CardDrawnPayload

@export var card_id: String = ""
@export var to: String = ""


func to_dict() -> Dictionary:
	return {
		"card_id": card_id,
		"to": to,
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := CardDrawnPayload.new()
	payload.card_id = d.get("card_id", "")
	payload.to = d.get("to", "")
	return payload
