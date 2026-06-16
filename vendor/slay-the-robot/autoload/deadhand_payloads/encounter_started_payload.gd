extends Resource
class_name EncounterStartedPayload

@export var encounter_id: String = ""


func to_dict() -> Dictionary:
	return {"encounter_id": encounter_id}


static func from_dict(d: Dictionary) -> Resource:
	var payload := EncounterStartedPayload.new()
	payload.encounter_id = d.get("encounter_id", "")
	return payload
