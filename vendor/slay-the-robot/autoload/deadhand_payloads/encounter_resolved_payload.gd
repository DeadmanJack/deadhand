extends Resource
class_name EncounterResolvedPayload

@export var encounter_id: String = ""
@export var outcome: String = ""


func to_dict() -> Dictionary:
	return {"encounter_id": encounter_id, "outcome": outcome}


static func from_dict(d: Dictionary) -> Resource:
	var payload := EncounterResolvedPayload.new()
	payload.encounter_id = d.get("encounter_id", "")
	payload.outcome = d.get("outcome", "")
	return payload
