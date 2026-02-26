extends Node2D

const CARD_SCENE_PATH = "res://Scenes/OpponentCard.tscn"
const CARD_DRAW_SPEED = 1
const STARTING_HAND_SIZE = 5

var opponent_deck = [
	"FaunAcolyte",
	"WitchApprentice",
	"FireflySprite",
	"FawnGuardian",
	"SaplingGuard",
	"ShadowFox",
	"MushroomImp",
	"DewFairy",
	"BluebellHerald",
	"BarkSoldier",
	"WindChimeFox",
	"VineBinder",
	"ForestBear",
	"MoonlightDeer",
	"StardustStag",
	"MistGiantTree",
	"ForestBlessing",
	"SweetJam",
	"FireflyGuidance",
	"SporeCloud",
	"SparkleBeam",
	"CozyNap",
	"MoonlightHeal",
	"ForestGift"
]
var card_database_reference
var fatigue_damage = 0
var battle_manager_reference
var opponent_hand_reference
var ability_bus_reference


func _ready():
	opponent_deck.shuffle()
	$RichTextLabel.text = str(opponent_deck.size())
	_update_deck_count_labels()
	card_database_reference = preload("res://Scripts/CardDataBase.gd").new()
	battle_manager_reference = $"../BattleManager"
	opponent_hand_reference = $"../OpponentHand"
	ability_bus_reference = $"../AbilityBus"
	for i in range(STARTING_HAND_SIZE):
		draw_card()


func draw_card():
	if battle_manager_reference and battle_manager_reference.game_over:
		return
	if opponent_deck.size() == 0:
		_apply_fatigue()
		return
	var card_drawn_name = opponent_deck[0]
	opponent_deck.erase(card_drawn_name)

	if opponent_deck.size() == 0:
		$Sprite2D.visible = false
		$RichTextLabel.visible = false

	$RichTextLabel.text = str(opponent_deck.size())
	_update_deck_count_labels()
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()

	var card_data = card_database_reference.get_card(card_drawn_name)
	if card_data.is_empty():
		return

	new_card.card_id = card_drawn_name
	new_card.card_type = card_data.get("type", "Monster")
	new_card.card_faction = str(card_data.get("faction", ""))
	new_card.cost = int(card_data.get("cost", 0))
	new_card.card_owner = "Opponent"
	if new_card.has_method("set_face_visible"):
		new_card.set_face_visible(false)
	var parsed_params = card_data.get("ability_params", {})
	new_card.ability_params = parsed_params.duplicate(true) if typeof(parsed_params) == TYPE_DICTIONARY else {}
	new_card.evolve_next_id = str(card_data.get("evolve_next_id", ""))
	new_card.evolve_cost = int(card_data.get("evolve_cost", 0))
	new_card.set_evolve_ready(false)
	var parsed_keywords = card_data.get("keywords", [])
	new_card.keywords = parsed_keywords.duplicate() if typeof(parsed_keywords) == TYPE_ARRAY else []
	var new_card_ability_script_path = card_data.get("ability_script", "")
	if new_card_ability_script_path:
		new_card.ability_script = load(new_card_ability_script_path).new()
	var name_text = str(card_data.get("name", card_drawn_name))
	var ability_text = str(card_data.get("ability_text", ""))
	if new_card.has_method("set_name_and_description"):
		new_card.set_name_and_description(name_text, ability_text)

	if new_card.card_type == "Monster":
		if new_card.has_method("set_attack_value"):
			new_card.set_attack_value(int(card_data.get("attack", 0)))
		if new_card.has_method("set_health_value"):
			new_card.set_health_value(int(card_data.get("health", 0)), true)
		if new_card.has_node("Attack"):
			new_card.get_node("Attack").visible = true
		if new_card.has_node("Health"):
			new_card.get_node("Health").visible = true
		if new_card.has_node("HealthBarBg"):
			new_card.get_node("HealthBarBg").visible = true
		if new_card.has_node("HealthBarFill"):
			new_card.get_node("HealthBarFill").visible = true
	else:
		if new_card.has_node("Attack"):
			new_card.get_node("Attack").visible = false
		if new_card.has_node("Health"):
			new_card.get_node("Health").visible = false
		if new_card.has_node("HealthBarBg"):
			new_card.get_node("HealthBarBg").visible = false
		if new_card.has_node("HealthBarFill"):
			new_card.get_node("HealthBarFill").visible = false

	if new_card.has_method("set_cost_evolve_text"):
		new_card.set_cost_evolve_text()

	if opponent_hand_reference and opponent_hand_reference.is_hand_full():
		_discard_drawn_card(new_card)
		return
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	var added = opponent_hand_reference.add_card_to_hand(new_card, CARD_DRAW_SPEED)
	if added and ability_bus_reference:
		ability_bus_reference.emit_event(
			AbilityBus.EVENT_ON_DRAW,
			{
				"battle_manager": battle_manager_reference,
				"input_manager": $"../InputManager",
				"source": new_card,
				"card": new_card,
				"turn_owner": "Opponent"
			}
		)

func _apply_fatigue():
	fatigue_damage += 1
	if battle_manager_reference:
		battle_manager_reference.direct_damage(fatigue_damage, "Opponent")

func _discard_drawn_card(card):
	# Opponent hand full discard should not reveal a card-back flash.
	if battle_manager_reference:
		battle_manager_reference.add_discard("Opponent")
	card.queue_free()

func _update_deck_count_labels():
	if has_node("../OpponentDeckCount"):
		$"../OpponentDeckCount".text = str(opponent_deck.size())
