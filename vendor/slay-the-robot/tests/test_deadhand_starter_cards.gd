extends GutTest

## Asserts starter deck (ranks 2–7 × 4 suits) loads via deadhand mod overlay.

const STARTER_CARD_IDS: Array[String] = [
	"2_spades", "3_spades", "4_spades", "5_spades", "6_spades", "7_spades",
	"2_hearts", "3_hearts", "4_hearts", "5_hearts", "6_hearts", "7_hearts",
	"2_diamonds", "3_diamonds", "4_diamonds", "5_diamonds", "6_diamonds", "7_diamonds",
	"2_clubs", "3_clubs", "4_clubs", "5_clubs", "6_clubs", "7_clubs",
]


func test_all_starter_cards_loaded() -> void:
	for card_id in STARTER_CARD_IDS:
		assert_true(
			Global._id_to_card_data.has(card_id),
			"Starter card %s should be loaded into Global._id_to_card_data" % card_id
		)


func test_2_spades_card_values() -> void:
	assert_true(Global._id_to_card_data.has("2_spades"))
	var card: CardData = Global._id_to_card_data["2_spades"]
	assert_eq(card.object_id, "2_spades")
	assert_eq(card.card_values.get("suit", ""), "spades")
	assert_eq(int(card.card_values.get("rank", -1)), 2)
	assert_eq(int(card.card_values.get("value", -1)), 2)
	assert_eq(card.card_values.get("is_face", null), false)
	assert_eq(card.card_values.get("is_ace", null), false)
	assert_eq(card.card_values.get("is_sting", null), false)
	assert_false(card.card_is_playable)
	assert_eq(card.card_name, "2 of Spades")
	assert_eq(
		card.card_description,
		"Light work. The kind that buries you slow."
	)
