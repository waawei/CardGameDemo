extends Node

const ABILITY_TRIGGER_EVENT = "on_play"

const TORNADO_DAMAGE = 1

func on_event(event_name: String, context: Dictionary):
	if ABILITY_TRIGGER_EVENT != event_name:
		return
	if context.get("source", null) != context.get("self_card", null):
		return

	var battle_manager_reference = context.get("battle_manager", null)
	var input_manager_reference = context.get("input_manager", null)
	if battle_manager_reference == null || input_manager_reference == null:
		return
	var self_card = context.get("self_card", null)

	input_manager_reference.inputs_disabled = true
	battle_manager_reference.enable_and_turn_button(false)

	await battle_manager_reference.wait(1.0)
	var target_cards = battle_manager_reference.opponent_cards_on_battlefield
	var target_owner = "Opponent"
	if self_card != null && self_card.card_owner == "Opponent":
		target_cards = battle_manager_reference.player_cards_on_battlefield
		target_owner = "Player"

	var cards_to_destroy = []

	for card in target_cards:
		var new_health = max(0, int(card.health) - TORNADO_DAMAGE)
		if card.has_method("set_health_value"):
			card.set_health_value(new_health, false)
		else:
			card.health = new_health
			card.get_node("Health").text = str(card.health)
		if card.health == 0:
			cards_to_destroy.append(card)

	await battle_manager_reference.wait(1.0)

	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			battle_manager_reference.destroy_card(card, target_owner)

	if self_card != null:
		battle_manager_reference.destroy_card(self_card, self_card.card_owner)
	await battle_manager_reference.wait(1.0)

	battle_manager_reference.enable_and_turn_button(true)
	input_manager_reference.inputs_disabled = false
