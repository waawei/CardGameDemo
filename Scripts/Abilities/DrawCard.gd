extends Node

const DEFAULT_EVENT = "on_play"

func on_event(event_name: String, context: Dictionary):
	var self_card = context.get("self_card", null)
	if self_card == null:
		return
	var trigger_event = str(self_card.ability_params.get("trigger_event", DEFAULT_EVENT))
	if event_name != trigger_event:
		return
	if context.get("source", null) != context.get("self_card", null):
		return

	var battle_manager = context.get("battle_manager", null)
	if battle_manager == null:
		return

	var count = int(self_card.ability_params.get("draw_count", 1))
	if self_card.card_owner == "Player":
		if battle_manager.has_node("../Deck"):
			battle_manager.get_node("../Deck").draw_card_for_ability(count)
	else:
		if battle_manager.has_node("../OpponentDeck"):
			for i in range(count):
				battle_manager.get_node("../OpponentDeck").draw_card()
	if self_card.card_type == "Magic":
		await battle_manager.wait(1.0)
		battle_manager.destroy_card(self_card, self_card.card_owner)
