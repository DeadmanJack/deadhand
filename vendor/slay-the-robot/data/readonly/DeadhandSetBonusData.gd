## Read only data for an equipment/card set bonus synergy.
extends SerializableData
class_name DeadhandSetBonusData

@export var set_name: String = ""
@export var set_required_artifact_ids: Array[String] = []
@export var set_required_card_tags: Array[String] = []
@export var set_required_card_tag_min_count: int = 0
@export var set_on_activate_actions: Array[Dictionary] = []
@export var set_on_deactivate_actions: Array[Dictionary] = []
@export var set_discovery_line: String = ""
