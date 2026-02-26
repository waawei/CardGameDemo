extends Node

const ABILITY_TRIGGER_EVENT = "on_attack"
const RESET_EVENT = "turn_end"

var already_activated = false

func on_event(event_name: String, context: Dictionary):
	if event_name == RESET_EVENT:
		var self_card = context.get("self_card", null)
		var turn_owner = context.get("turn_owner", "")
		if self_card != null && self_card.card_owner == turn_owner:
			already_activated = false
		return

	if ABILITY_TRIGGER_EVENT != event_name:
		return
	if already_activated:
		return
	if context.get("source", null) != context.get("self_card", null):
		return

	var battle_manager_reference = context.get("battle_manager", null)
	if battle_manager_reference == null:
		return

	var self_card = context.get("self_card", null)
	if self_card == null:
		return
	if self_card in battle_manager_reference.played_cards_that_attacked_this_turn:
		battle_manager_reference.played_cards_that_attacked_this_turn.erase(self_card)
		already_activated = true
