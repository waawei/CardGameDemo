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

	var atk = int(self_card.ability_params.get("buff_attack", 0))
	var hp = int(self_card.ability_params.get("buff_health", 0))
	var mode = str(self_card.ability_params.get("buff_mode", "all"))
	var include_self = bool(self_card.ability_params.get("buff_include_self", true))

	var targets = battle_manager.player_cards_on_battlefield if self_card.card_owner == "Player" else battle_manager.opponent_cards_on_battlefield
	if !include_self:
		targets = targets.filter(func(c): return c != self_card)
	if targets.size() == 0:
		return

	if mode == "random":
		_apply_buff_to_card(targets.pick_random(), atk, hp)
	elif mode == "self":
		_apply_buff_to_card(self_card, atk, hp)
	else:
		for card in targets:
			_apply_buff_to_card(card, atk, hp)
	if self_card.card_type == "Magic":
		await battle_manager.wait(1.0)
		battle_manager.destroy_card(self_card, self_card.card_owner)

func _apply_buff_to_card(card, atk: int, hp: int):
	if card == null:
		return
	var new_attack = int(card.attack) + atk
	var new_health = int(card.health) + hp
	if card.has_method("set_attack_value"):
		card.set_attack_value(new_attack)
	else:
		card.attack = new_attack
		if card.has_node("Attack"):
			card.get_node("Attack").text = str(card.attack)
	if card.has_method("set_health_value"):
		card.set_health_value(new_health, false)
	else:
		card.health = new_health
		if card.has_node("Health"):
			card.get_node("Health").text = str(card.health)
