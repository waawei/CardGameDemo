extends Node2D


var card_in_slot = false
var card_slot_type = "Magic"

func set_occupied(occupied: bool) -> void:
	card_in_slot = occupied
