extends Node2D



const CARD_WIDTH = 200
const HAND_Y_POSITION = 1150
const DEFAULT_CARD_MOVE_SPEED = 0.1
const HAND_LIMIT = 5

var player_hand = []
var center_screen_x

func _ready():
	center_screen_x = get_viewport().size.x / 2.0
	
		

func add_card_to_hand(card, speed) -> bool:
	if card in player_hand:
		animate_card_to_position(card, card.hand_start_position, DEFAULT_CARD_MOVE_SPEED)
		return true
	if is_hand_full():
		return false
	player_hand.insert(0, card)
	update_hand_positions(speed)
	return true
	
func update_hand_positions(speed):
	for i in range(player_hand.size()):
		var new_position = Vector2(calculating_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		card.hand_start_position = new_position
		animate_card_to_position(card, new_position, speed)


func calculating_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2.0
	return x_offset
	
func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)
	if card and card.has_method("sync_base_transform"):
		tween.tween_callback(func(): card.sync_base_transform())

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)

func is_hand_full() -> bool:
	return player_hand.size() >= HAND_LIMIT
		
	
