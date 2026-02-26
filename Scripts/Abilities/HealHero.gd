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

	var amount = int(self_card.ability_params.get("heal_amount", 0))
	if amount <= 0:
		return
	battle_manager.heal(amount, self_card.card_owner)
	if self_card.card_type == "Magic":
		await battle_manager.wait(1.0)
		battle_manager.destroy_card(self_card, self_card.card_owner)
