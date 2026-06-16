extends Resource
class_name RNGRolledPayload

@export var channel: String = ""
@export var result: Variant = 0


func to_dict() -> Dictionary:
	return {
		"channel": channel,
		"result": result,
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := RNGRolledPayload.new()
	payload.channel = d.get("channel", "")
	payload.result = d.get("result", 0)
	return payload
