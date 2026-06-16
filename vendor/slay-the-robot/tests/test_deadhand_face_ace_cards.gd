extends GutTest

## Asserts face cards (12) and aces (4) load via deadhand mod overlay.

const FACE_ACE_CARD_IDS: Array[String] = [
	"j_spades_bowie", "q_spades_hangmans_knot", "k_spades_old_iron",
	"j_hearts_cold_stare", "q_hearts_widows_veil", "k_hearts_preacher",
	"j_diamonds_picklock", "q_diamonds_forged_letter", "k_diamonds_long_shadow",
	"j_clubs_loaded_dice", "q_clubs_lady_fortune", "k_clubs_drifters_coin",
	"a_spades_mayors_mark", "a_hearts_widow_keepsake",
	"a_diamonds_forgers_last_work", "a_clubs_drifters_promise",
]


func test_all_face_and_ace_cards_loaded() -> void:
	for card_id in FACE_ACE_CARD_IDS:
		assert_true(
			Global._id_to_card_data.has(card_id),
			"Face/ace card %s should be loaded into Global._id_to_card_data" % card_id
		)


func test_j_spades_bowie_card_values() -> void:
	assert_true(Global._id_to_card_data.has("j_spades_bowie"))
	var card: CardData = Global._id_to_card_data["j_spades_bowie"]
	assert_eq(card.object_id, "j_spades_bowie")
	assert_eq(card.card_values.get("suit", ""), "spades")
	assert_eq(int(card.card_values.get("rank", -1)), 11)
	assert_eq(int(card.card_values.get("value", -1)), 11)
	assert_eq(card.card_values.get("is_face", null), true)
	assert_eq(card.card_values.get("is_ace", null), false)
	assert_eq(card.card_values.get("is_sting", null), false)
	assert_false(card.card_is_playable)
	assert_eq(card.card_name, "The Bowie")


func test_a_spades_mayors_mark_is_ace() -> void:
	assert_true(Global._id_to_card_data.has("a_spades_mayors_mark"))
	var card: CardData = Global._id_to_card_data["a_spades_mayors_mark"]
	assert_eq(card.object_id, "a_spades_mayors_mark")
	assert_eq(card.card_values.get("suit", ""), "spades")
	assert_eq(int(card.card_values.get("rank", -1)), 14)
	assert_eq(int(card.card_values.get("value", -1)), 14)
	assert_eq(card.card_values.get("is_face", null), false)
	assert_eq(card.card_values.get("is_ace", null), true)
	assert_eq(card.card_values.get("is_sting", null), false)
	assert_false(card.card_is_playable)
	assert_eq(card.card_name, "Mayor's Mark")
