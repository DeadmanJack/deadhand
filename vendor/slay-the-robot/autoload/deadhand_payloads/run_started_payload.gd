extends Resource
class_name RunStartedPayload

@export var seed: int = 0
@export var starter_deck_id: String = "default"
@export var run_uuid: String = ""


func to_dict() -> Dictionary:
	return {
		"seed": seed,
		"starter_deck_id": starter_deck_id,
		"run_uuid": run_uuid,
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := RunStartedPayload.new()
	payload.seed = d.get("seed", 0)
	payload.starter_deck_id = d.get("starter_deck_id", "default")
	payload.run_uuid = d.get("run_uuid", "")
	return payload
