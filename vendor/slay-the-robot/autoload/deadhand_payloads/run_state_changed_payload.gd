extends Resource
class_name RunStateChangedPayload

@export var field: String = ""
@export var old_value: Variant
@export var new_value: Variant


func to_dict() -> Dictionary:
	return {
		"field": field,
		"old_value": old_value,
		"new_value": new_value,
	}


static func from_dict(d: Dictionary) -> Resource:
	var payload := RunStateChangedPayload.new()
	payload.field = d.get("field", "")
	payload.old_value = d.get("old_value")
	payload.new_value = d.get("new_value")
	return payload
