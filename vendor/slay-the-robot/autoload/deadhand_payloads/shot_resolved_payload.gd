extends Resource
class_name ShotResolvedPayload

@export var encounter_id: String = ""
@export var round: int = 0
@export var winner: String = ""


func to_dict() -> Dictionary:
	return {"encounter_id": encounter_id, "round": round, "winner": winner}


static func from_dict(d: Dictionary) -> Resource:
	var payload := ShotResolvedPayload.new()
	payload.encounter_id = d.get("encounter_id", "")
	payload.round = d.get("round", 0)
	payload.winner = d.get("winner", "")
	return payload
