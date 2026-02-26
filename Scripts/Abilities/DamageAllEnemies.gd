extends Node

const ABILITY_TRIGGER_EVENT = "on_play"

func on_event(event_name: String, context: Dictionary):
	if event_name != ABILITY_TRIGGER_EVENT:
		return
	if context.get("source", null) != context.get("self_card", null):
		return

	var battle_manager = context.get("battle_manager", null)
	var self_card = context.get("self_card", null)
	if battle_manager == null or self_card == null:
		return

	var amount = int(self_card.ability_params.get("damage_amount", 1))
	if amount <= 0:
		return

	var targets = battle_manager.opponent_cards_on_battlefield if self_card.card_owner == "Player" else battle_manager.player_cards_on_battlefield
	var destroyed = []
	for card in targets:
		var new_health = max(0, int(card.health) - amount)
		if card.has_method("set_health_value"):
			card.set_health_value(new_health, false)
		else:
			card.health = new_health
			if card.has_node("Health"):
				card.get_node("Health").text = str(card.health)
		if card.health == 0:
			destroyed.append(card)
	for card in destroyed:
		var target_owner = "Opponent" if self_card.card_owner == "Player" else "Player"
		battle_manager.destroy_card(card, target_owner)
	if self_card.card_type == "Magic":
		await battle_manager.wait(1.0)
		battle_manager.destroy_card(self_card, self_card.card_owner)
