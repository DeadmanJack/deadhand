extends Resource
class_name CardDiscardedPayload

@export var card_id: String = ""
@export var is_manual: bool = false


func to_dict() -> Dictionary:
	return {"card_id": card_id, "is_manual": is_manual}


static func from_dict(d: Dictionary) -> Resource:
	var payload := CardDiscardedPayload.new()
	payload.card_id = d.get("card_id", "")
	payload.is_manual = d.get("is_manual", false)
	return payload
