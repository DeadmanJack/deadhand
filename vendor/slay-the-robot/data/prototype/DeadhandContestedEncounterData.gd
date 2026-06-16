## Prototype data for a Deadhand contested encounter (head-to-head duel).
extends PrototypeData
class_name DeadhandContestedEncounterData

@export var contested_name: String = ""
@export var contested_primary_suit: String = ""
@export var contested_rounds: int = 3
@export var contested_bust_line: int = 0
@export var contested_player_wound_limit: int = 3
@export var contested_opponent_deck_template_id: String = ""
@export var contested_opponent_wound_limit: int = 3
@export var contested_opponent_hand_size: int = 5
@export var contested_on_win_actions: Array[Dictionary] = []
@export var contested_on_lose_actions: Array[Dictionary] = []
@export var contested_flavor_text: String = ""
