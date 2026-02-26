extends Node
class_name CardDatabase

const CARD_DATA_PATH = "res://Data/cards.json"

var cards := {}

func _init():
	_load_cards()

func _load_cards():
	var file = FileAccess.open(CARD_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("CardDatabase: Failed to open " + CARD_DATA_PATH)
		cards = {}
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("CardDatabase: Expected a dictionary in cards.json")
		cards = {}
		return

	cards = parsed

func get_card(card_id: String) -> Dictionary:
	if cards.has(card_id):
		return cards[card_id]
	push_warning("CardDatabase: Missing card id " + card_id)
	return {}

func has_card(card_id: String) -> bool:
	return cards.has(card_id)
