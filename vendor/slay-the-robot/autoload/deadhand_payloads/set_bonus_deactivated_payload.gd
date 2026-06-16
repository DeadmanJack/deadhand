extends Resource
class_name SetBonusDeactivatedPayload

@export var set_id: String = ""
@export var bonus_id: String = ""


func to_dict() -> Dictionary:
	return {"set_id": set_id, "bonus_id": bonus_id}


static func from_dict(d: Dictionary) -> Resource:
	var payload := SetBonusDeactivatedPayload.new()
	payload.set_id = d.get("set_id", "")
	payload.bonus_id = d.get("bonus_id", "")
	return payload
