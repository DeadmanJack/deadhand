extends Resource
class_name CardBurnedPayload

@export var card_id: String = ""
@export var reason: String = ""


func to_dict() -> Dictionary:
	return {"card_id": card_id, "reason": reason}


static func from_dict(d: Dictionary) -> Resource:
	var payload := CardBurnedPayload.new()
	payload.card_id = d.get("card_id", "")
	payload.reason = d.get("reason", "")
	return payload
