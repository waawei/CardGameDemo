extends Node
class_name AbilityBus

const EVENT_ON_PLAY = "on_play"
const EVENT_ON_ATTACK = "on_attack"
const EVENT_ON_DEATH = "on_death"
const EVENT_ON_DRAW = "on_draw"
const EVENT_TURN_START = "turn_start"
const EVENT_TURN_END = "turn_end"
const ACTION_LOG_PATH := "../ActionLogLayer/ActionLogPanel/ActionLogScroll/ActionLog"

var _queue = []
var _processing = false

func emit_event(event_name: String, context: Dictionary = {}):
	_queue.append({"event_name": event_name, "context": context})
	if _processing:
		return
	_processing = true
	while _queue.size() > 0:
		var payload = _queue.pop_front()
		_log_event(payload.event_name, payload.context)
		var targets = _get_targets(payload.context)
		for card in targets:
			_dispatch_to_card(card, payload.event_name, payload.context)
	_processing = false

func _get_targets(context: Dictionary) -> Array:
	var targets = []
	if context.has("battle_manager"):
		var battle_manager = context.battle_manager
		var player_cards = _sort_cards_left_to_right(battle_manager.player_cards_on_battlefield)
		var opponent_cards = _sort_cards_left_to_right(battle_manager.opponent_cards_on_battlefield)
		if context.get("turn_owner", "Player") == "Player":
			targets.append_array(player_cards)
			targets.append_array(opponent_cards)
		else:
			targets.append_array(opponent_cards)
			targets.append_array(player_cards)
	if context.has("cards"):
		targets.append_array(context.cards)
	elif context.has("card"):
		targets.append(context.card)
	var unique_targets = []
	var seen = {}
	for card in targets:
		if card == null:
			continue
		if seen.has(card):
			continue
		seen[card] = true
		unique_targets.append(card)
	return unique_targets

func _sort_cards_left_to_right(cards: Array) -> Array:
	var sorted = cards.duplicate()
	sorted.sort_custom(func(a, b): return _get_card_x(a) < _get_card_x(b))
	return sorted

func _get_card_x(card) -> float:
	if card == null:
		return 0.0
	if card.card_slot_card_is_in:
		return card.card_slot_card_is_in.position.x
	return card.position.x

func _dispatch_to_card(card, event_name: String, context: Dictionary):
	if card == null:
		return
	if context.get("skip_self", false) and context.get("source", null) == card:
		return
	if card.ability_script and card.ability_script.has_method("on_event"):
		var local_context = context
		if !context.has("self_card") || context.self_card != card:
			local_context = context.duplicate()
			local_context.self_card = card
		card.ability_script.on_event(event_name, local_context)

func _log_event(event_name: String, context: Dictionary) -> void:
	var log = get_node_or_null(ACTION_LOG_PATH)
	if log == null or !log.has_method("log_event"):
		return
	var text = _format_log_text(event_name, context)
	if text != "":
		log.log_event(text)

func _format_log_text(event_name: String, context: Dictionary) -> String:
	var source = context.get("source", context.get("card", null))
	var owner = ""
	if source != null and source.get("card_owner") != null:
		owner = str(source.card_owner)
	else:
		owner = str(context.get("turn_owner", ""))
	var owner_label = "Player" if owner == "Player" else "Opponent"
	if event_name == EVENT_TURN_START:
		return owner_label + " turn start"
	if event_name == EVENT_TURN_END:
		return owner_label + " turn end"
	if event_name == EVENT_ON_DRAW:
		return owner_label + " drew a card"
	if event_name == EVENT_ON_PLAY:
		var name = _get_card_name(source)
		var ability = _get_ability_text(source)
		if ability != "":
			return owner_label + " played " + name + " - " + ability
		return owner_label + " played " + name
	if event_name == EVENT_ON_ATTACK:
		var target = context.get("target", null)
		var attacker_name = _get_card_name(source)
		if target != null:
			return owner_label + " " + attacker_name + " attacked " + _get_card_name(target)
		return owner_label + " " + attacker_name + " attacked directly"
	if event_name == EVENT_ON_DEATH:
		var dead = context.get("card", source)
		return _get_card_name(dead) + " was defeated"
	return ""

func _get_card_name(card) -> String:
	if card == null:
		return "Unknown"
	var name_val = card.get("card_display_name")
	if name_val != null and str(name_val) != "":
		return str(name_val)
	return str(card.get("card_id"))

func _get_ability_text(card) -> String:
	if card == null:
		return ""
	var ability_val = card.get("ability_text")
	if ability_val == null:
		return ""
	return str(ability_val).strip_edges()
