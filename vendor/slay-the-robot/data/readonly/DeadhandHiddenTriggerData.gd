## Read only data for a hidden trigger evaluated during a run.
extends SerializableData
class_name DeadhandHiddenTriggerData

@export var trigger_conditions: Array[Dictionary] = []
@export var trigger_fires_at_most: String = "once_per_run"
@export var trigger_on_fire_actions: Array[Dictionary] = []
@export var trigger_emit_line: String = ""
@export var trigger_journal_entry_id: String = ""
