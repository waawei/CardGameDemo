extends Node2D



const CARD_WIDTH = 200
const HAND_Y_POSITION = -50
const DEFAULT_CARD_MOVE_SPEED = 0.1
const HAND_LIMIT = 5

var opponent_hand = []
var center_screen_x

func _ready():
	center_screen_x = get_viewport().size.x / 2.0
	
		

func add_card_to_hand(card, speed) -> bool:
	if card in opponent_hand:
		animate_card_to_position(card, card.hand_start_position, DEFAULT_CARD_MOVE_SPEED)
		return true
	if is_hand_full():
		return false
	opponent_hand.insert(0, card)
	update_hand_positions(speed)
	return true
	
func update_hand_positions(speed):
	for i in range(opponent_hand.size()):
		var new_position = Vector2(calculating_card_position(i), HAND_Y_POSITION)
		var card = opponent_hand[i]
		card.hand_start_position = new_position
		animate_card_to_position(card, new_position, speed)


func calculating_card_position(index):
	var total_width = (opponent_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x - index * CARD_WIDTH + total_width / 2.0
	return x_offset
	
func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)

func remove_card_from_hand(card):
	if card in opponent_hand:
		opponent_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)

func is_hand_full() -> bool:
	return opponent_hand.size() >= HAND_LIMIT
		
	
