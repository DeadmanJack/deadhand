extends Resource
class_name MemoryCardRevealedPayload

@export var card_id: String = ""


func to_dict() -> Dictionary:
	return {"card_id": card_id}


static func from_dict(d: Dictionary) -> Resource:
	var payload := MemoryCardRevealedPayload.new()
	payload.card_id = d.get("card_id", "")
	return payload
