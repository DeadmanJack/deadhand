## Prototype data for a Deadhand task the player can attempt during a run.
extends PrototypeData
class_name DeadhandTaskData

@export var task_name: String = ""
@export var task_location_id: String = ""
@export var task_primary_suit: String = "spades"
@export var task_difficulty_class: int = 10
@export var task_available_phases: Array[String] = []
@export var task_action_cost: int = 1
@export var task_reward_money_min: int = 0
@export var task_reward_money_max: int = 0
@export var task_reward_loot_table_id: String = ""
@export var task_notoriety_delta: int = 0
@export var task_on_success_actions: Array[Dictionary] = []
@export var task_on_failure_actions: Array[Dictionary] = []
@export var task_flavor_text: String = ""
