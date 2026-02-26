extends Node

const ABILITY_TRIGGER_EVENT = "on_draw"

func on_event(event_name: String, context: Dictionary):
	if event_name != ABILITY_TRIGGER_EVENT:
		return
	if context.get("source", null) != context.get("self_card", null):
		return

	var self_card = context.get("self_card", null)
	if self_card == null:
		return

	var atk = int(self_card.ability_params.get("buff_attack", 0))
	var hp = int(self_card.ability_params.get("buff_health", 0))
	var new_attack = int(self_card.attack) + atk
	var new_health = int(self_card.health) + hp
	if self_card.has_method("set_attack_value"):
		self_card.set_attack_value(new_attack)
	else:
		self_card.attack = new_attack
		if self_card.has_node("Attack"):
			self_card.get_node("Attack").text = str(self_card.attack)
	if self_card.has_method("set_health_value"):
		self_card.set_health_value(new_health, false)
	else:
		self_card.health = new_health
		if self_card.has_node("Health"):
			self_card.get_node("Health").text = str(self_card.health)
