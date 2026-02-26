extends Node

const DEFAULT_EVENT = "on_play"

func on_event(event_name: String, context: Dictionary):
	var self_card = context.get("self_card", null)
	if self_card == null:
		return
	var trigger_event = str(self_card.ability_params.get("trigger_event", DEFAULT_EVENT))
	if event_name != trigger_event:
		return
	if context.get("source", null) != self_card:
		return

	var battle_manager = context.get("battle_manager", null)
	if battle_manager == null:
		return

	var amount = int(self_card.ability_params.get("damage_amount", 1))
	if amount <= 0:
		return

	var owner = str(self_card.card_owner)
	if owner == "":
		owner = str(context.get("turn_owner", "Player"))
	var target_owner = "Opponent" if owner == "Player" else "Player"
	battle_manager.direct_damage(amount, target_owner)
	if self_card.card_type == "Magic":
		await battle_manager.wait(1.0)
		battle_manager.destroy_card(self_card, self_card.card_owner)
