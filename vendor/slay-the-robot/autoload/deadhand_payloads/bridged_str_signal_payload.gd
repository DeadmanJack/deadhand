extends Resource
class_name BridgedSTRSignalPayload

@export var signal_name: String = ""
@export var str_args: Dictionary = {}


func to_dict() -> Dictionary:
	return {
		"signal_name": signal_name,
		"str_args": str_args.duplicate(true),
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := BridgedSTRSignalPayload.new()
	payload.signal_name = d.get("signal_name", "")
	payload.str_args = d.get("str_args", {}).duplicate(true)
	return payload
