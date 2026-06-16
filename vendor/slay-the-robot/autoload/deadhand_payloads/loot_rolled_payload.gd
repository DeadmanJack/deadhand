extends Resource
class_name LootRolledPayload

@export var table: String = ""
@export var items: Array[String] = []


func to_dict() -> Dictionary:
	return {"table": table, "items": items.duplicate()}


static func from_dict(d: Dictionary) -> Resource:
	var payload := LootRolledPayload.new()
	payload.table = d.get("table", "")
	var raw_items: Variant = d.get("items", [])
	if raw_items is Array:
		payload.items = Array(raw_items, TYPE_STRING, "", null)
	return payload
