extends Node

const ABILITY_TRIGGER_EVENT = "on_play"

const ARROW_DAMAGE = 1

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

	var target_owner = "Opponent"
	if self_card != null && self_card.card_owner == "Opponent":
		target_owner = "Player"
	battle_manager_reference.direct_damage(ARROW_DAMAGE, target_owner)

	await battle_manager_reference.wait(1.0)

	battle_manager_reference.enable_and_turn_button(true)
	input_manager_reference.inputs_disabled = false
