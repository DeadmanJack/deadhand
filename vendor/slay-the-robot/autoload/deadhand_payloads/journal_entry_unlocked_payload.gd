extends Resource
class_name JournalEntryUnlockedPayload

@export var entry_id: String = ""


func to_dict() -> Dictionary:
	return {"entry_id": entry_id}


static func from_dict(d: Dictionary) -> Resource:
	var payload := JournalEntryUnlockedPayload.new()
	payload.entry_id = d.get("entry_id", "")
	return payload
