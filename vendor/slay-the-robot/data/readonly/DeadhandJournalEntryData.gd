## Read only data for a journal entry unlocked during a run or across runs.
extends SerializableData
class_name DeadhandJournalEntryData

@export var journal_title: String = ""
@export var journal_body: String = ""
@export var journal_unlock_source: String = ""
@export var journal_category: String = "general"
