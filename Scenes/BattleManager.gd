extends Node

const SMALL_CARD_SCALE = 1
const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 10
const BATTLE_POS_OFFSET = 25
const MAX_ENERGY = 10
const ENERGY_GROWTH = 1
const STARTING_MAX_ENERGY = 1
const SCORE_ROOT_PATH := "../ScoreLayer/ScorePanel"
const PLAYER_HEALTH_PATH := SCORE_ROOT_PATH + "/ScoreVBox/PlayerPanel/PlayerVBox/PlayerHealthRow/PlayerHealthValue"
const OPPONENT_HEALTH_PATH := SCORE_ROOT_PATH + "/ScoreVBox/OpponentPanel/OpponentVBox/OpponentHealthRow/OpponentHealthValue"
const PLAYER_ENERGY_PATH := SCORE_ROOT_PATH + "/ScoreVBox/PlayerPanel/PlayerVBox/PlayerEnergyRow/PlayerEnergyValue"
const OPPONENT_ENERGY_PATH := SCORE_ROOT_PATH + "/ScoreVBox/OpponentPanel/OpponentVBox/OpponentEnergyRow/OpponentEnergyValue"
const PLAYER_CRYSTALS_PATH := SCORE_ROOT_PATH + "/ScoreVBox/PlayerPanel/PlayerVBox/PlayerEnergyCrystals"
const OPPONENT_CRYSTALS_PATH := SCORE_ROOT_PATH + "/ScoreVBox/OpponentPanel/OpponentVBox/OpponentEnergyCrystals"
const MANA_BAR_PLAYER_PATH := "../ManaLayer/PlayerManaBar"
const MANA_BAR_OPPONENT_PATH := "../ManaLayer/OpponentManaBar"
const TURN_OWNER_LABEL_PATH := "../TurnPhaseLayer/TurnPhasePanel/TurnPhaseVBox/TurnOwnerLabel"
const TURN_PHASE_LABEL_PATH := "../TurnPhaseLayer/TurnPhasePanel/TurnPhaseVBox/TurnPhaseLabel"
const PLAYER_DECK_COUNT_PATH := "../PlayerDeckCount"
const OPPONENT_DECK_COUNT_PATH := "../OpponentDeckCount"
const PLAYER_DISCARD_COUNT_PATH := "../PlayerDiscardCount"
const OPPONENT_DISCARD_COUNT_PATH := "../OpponentDiscardCount"
const ENERGY_CRYSTAL_SIZE := Vector2(18, 18)
const ENERGY_CRYSTAL_RADIUS := 4
const ENERGY_ACTIVE_COLOR := Color(0.25, 0.75, 1.0, 0.95)
const ENERGY_INACTIVE_COLOR := Color(0.1, 0.1, 0.1, 0.55)
const ENERGY_BORDER_COLOR := Color(0.7, 0.6, 0.25, 0.85)
const ENERGY_ACTIVE_TEX = preload("res://Assets/CardFaces/Glowing Orb.png")
const ENERGY_INACTIVE_TEX = preload("res://Assets/CardFaces/Sapphire Crystal.png")
const MANA_ORB_SIZE := Vector2(14, 14)
const MANA_ORB_ACTIVE_COLOR := Color(0.25, 0.8, 1.0, 0.95)
const MANA_ORB_INACTIVE_COLOR := Color(0.12, 0.12, 0.12, 0.45)
const MANA_ORB_LOCKED_COLOR := Color(0.12, 0.12, 0.12, 0.18)
const MANA_ORB_BORDER_COLOR := Color(0.7, 0.6, 0.25, 0.75)
const UI_PULSE_SCALE := Vector2(1.08, 1.08)

var battle_timer
var empty_monster_card_slots = []
var opponent_cards_on_battlefield = []
var player_cards_on_battlefield = []
var played_cards_that_attacked_this_turn = []
var player_health
var opponent_health
var is_opponents_turn = false
var ability_bus
var player_energy = 0
var opponent_energy = 0
var player_max_energy = 0
var opponent_max_energy = 0
var game_over = false
var card_database_reference
var _last_player_health := -1
var _last_opponent_health := -1
var player_discard_count := 0
var opponent_discard_count := 0
const PLAYER_MAGIC_SLOTS := ["MagicSlotPlayer"]
const PLAYER_MONSTER_SLOTS := ["CardSlot6", "CardSlot7", "CardSlot8", "CardSlot9", "CardSlot10"]
const ENABLED_PLAYER_MONSTER_SLOTS := ["CardSlot7", "CardSlot6", "CardSlot9"]
const OPPONENT_MONSTER_SLOTS := [
	"CardSlot11", "CardSlot12", "CardSlot13", "CardSlot14", "CardSlot15",
	"CardSlot16", "CardSlot17", "CardSlot18", "CardSlot19", "CardSlot20"
]
const ENABLED_OPPONENT_MONSTER_SLOTS := ["CardSlot12", "CardSlot13", "CardSlot14"]
const OPPONENT_MAGIC_SLOTS := ["MagicSlotOpponent"]


func _ready():
	battle_timer = $"../BattleTimer"
	battle_timer.wait_time = 1.0
	ability_bus = $"../AbilityBus"
	card_database_reference = preload("res://Scripts/CardDataBase.gd").new()

	_configure_slots()
	_ensure_mana_bar("Player")
	_ensure_mana_bar("Opponent")

	player_health = STARTING_HEALTH
	opponent_health = STARTING_HEALTH
	player_max_energy = STARTING_MAX_ENERGY
	opponent_max_energy = STARTING_MAX_ENERGY
	_update_health_labels()
	_update_discard_labels()
	begin_turn("Player")

func _configure_slots():
	var slots_root = $"../CradSlots"

	for slot_name in PLAYER_MAGIC_SLOTS:
		_set_slot_enabled(slots_root.get_node_or_null(slot_name), true)

	for slot_name in PLAYER_MONSTER_SLOTS:
		var enabled = ENABLED_PLAYER_MONSTER_SLOTS.has(slot_name)
		_set_slot_enabled(slots_root.get_node_or_null(slot_name), enabled)

	for slot_name in OPPONENT_MONSTER_SLOTS:
		var slot = slots_root.get_node_or_null(slot_name)
		var enabled = ENABLED_OPPONENT_MONSTER_SLOTS.has(slot_name)
		_set_slot_enabled(slot, enabled)
		if enabled:
			empty_monster_card_slots.append(slot)

	for slot_name in OPPONENT_MAGIC_SLOTS:
		_set_slot_enabled(slots_root.get_node_or_null(slot_name), true)

func _set_slot_enabled(slot, enabled: bool):
	if slot == null:
		return
	slot.visible = enabled
	if slot.has_node("Area2D/CollisionShape2D"):
		slot.get_node("Area2D/CollisionShape2D").disabled = !enabled
	if slot.has_node("Area2D"):
		var area = slot.get_node("Area2D")
		if area is Area2D:
			area.monitoring = enabled
			area.monitorable = enabled

func direct_damage(damage, target_owner = "Opponent"):
	if game_over:
		return
	if target_owner == "Player":
		player_health = max(0, player_health - damage)
	else:
		opponent_health = max(0, opponent_health - damage)
	_update_health_labels()
	check_game_over()

func heal(amount, target_owner = "Player"):
	if game_over:
		return
	if amount <= 0:
		return
	if target_owner == "Player":
		player_health = min(STARTING_HEALTH, player_health + amount)
	else:
		opponent_health = min(STARTING_HEALTH, opponent_health + amount)
	_update_health_labels()

func _on_end_turn_button_pressed() -> void:
	var button = get_node_or_null("../EndTurnButton")
	if button != null and button.has_method("play_transition_to_enemy"):
		await button.play_transition_to_enemy()
	else:
		_set_end_turn_state("ending")
		await wait(1.0)
	if game_over:
		return
	is_opponents_turn = true
	$"../CardManager".unselect_selected_monster()
	if ability_bus:
		ability_bus.emit_event(
			AbilityBus.EVENT_TURN_END,
			{
				"battle_manager": self,
				"input_manager": $"../InputManager",
				"turn_owner": "Player"
			}
		)
	played_cards_that_attacked_this_turn = []
	opponent_turn()
	
	

func _set_end_turn_state(state: String) -> void:
	var button = get_node_or_null("../EndTurnButton")
	if button == null:
		return
	if button.has_method("set_state"):
		button.set_state(state)

func end_turn_button_enabled(is_enabled):
	if has_node("../EndTurnButton"):
		$"../EndTurnButton".disabled = !is_enabled
		$"../EndTurnButton".visible = true


func opponent_turn():
	if game_over:
		return
	end_turn_button_enabled(false)
	begin_turn("Opponent")
	
	await wait(1.0)
	
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		
		await wait(1.0)
	
	if empty_monster_card_slots.size() != 0:
		await try_play_card_with_highest_attack()
	
	if opponent_cards_on_battlefield.size() != 0:
		var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in  enemy_cards_to_attack:
			if card.summoning_sick:
				continue
			if player_cards_on_battlefield.size() != 0:
				var taunt_targets = get_taunt_targets("Player")
				var catd_to_attack = taunt_targets.pick_random() if taunt_targets.size() > 0 else player_cards_on_battlefield.pick_random()
				await attack(card, catd_to_attack, "Opponent")
			else:
				await direct_attack(card, "Opponent")
	
	# End Turn
	await end_opponent_turn()

func direct_attack(attacking_card, attacker):
	_set_turn_phase(attacker, "Combat")
	if game_over:
		return
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1080
	else:
		$"../InputManager".inputs_disabled = true
		end_turn_button_enabled(false)
		new_pos_y = 0
		played_cards_that_attacked_this_turn.append(attacking_card)
	var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	
	attacking_card.z_index = 5
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	var target_owner = "Opponent"
	if attacker == "Opponent":
		target_owner = "Player"
	direct_damage(attacking_card.attack, target_owner)
	if game_over:
		return
	
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	attacking_card.z_index = 0
	await wait(1.0)
	
	if ability_bus:
		ability_bus.emit_event(
			AbilityBus.EVENT_ON_ATTACK,
			{
				"battle_manager": self,
				"input_manager": $"../InputManager",
				"source": attacking_card,
				"attacker": attacker,
				"target": null
			}
		)
	if attacker == "Player":
		$"../InputManager".inputs_disabled = false
		end_turn_button_enabled(true)
	_set_turn_phase(attacker, "Main")

	

func attack(attacking_card, defending_card, attacker):
	_set_turn_phase(attacker, "Combat")
	if game_over:
		return
	if attacker == "Player":
		$"../InputManager".inputs_disabled = true
		end_turn_button_enabled(false)
		$"../CardManager".selected_monster = null
		played_cards_that_attacked_this_turn.append(attacking_card) 
	
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	_update_card_health_ui(defending_card)
	
	await wait(1.0)
	attacking_card.z_index = 0
	
	var card_was_destroyed = false
	
	if defending_card.health == 0:
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")
		else:
			destroy_card(defending_card, "Player")
		card_was_destroyed = true
	
	if card_was_destroyed:
		await wait(1.0)
	
	if ability_bus:
		ability_bus.emit_event(
			AbilityBus.EVENT_ON_ATTACK,
			{
				"battle_manager": self,
				"input_manager": $"../InputManager",
				"source": attacking_card,
				"attacker": attacker,
				"target": defending_card
			}
		)
	if attacker == "Player":
		$"../InputManager".inputs_disabled = false
		end_turn_button_enabled(true)
	_set_turn_phase(attacker, "Main")



func destroy_card(card, card_owner):
	if game_over:
		return
	var slot = card.card_slot_card_is_in
	if ability_bus:
		ability_bus.emit_event(
			AbilityBus.EVENT_ON_DEATH,
			{
				"battle_manager": self,
				"input_manager": $"../InputManager",
				"source": card,
				"card": card,
				"card_owner": card_owner
			}
		)
	if card_owner == "Player":
		card.defeated = true
		if card.has_node("Area2D/CollisionShape2D"):
			card.get_node("Area2D/CollisionShape2D").disabled = true
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
		if slot and slot.has_node("Area2D/CollisionShape2D"):
			slot.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)
		if slot and slot.card_slot_type == "Monster" and slot not in empty_monster_card_slots:
			empty_monster_card_slots.append(slot)

	if slot:
		if slot.has_method("set_occupied"):
			slot.set_occupied(false)
		else:
			slot.card_in_slot = false
	card.card_slot_card_is_in = null
	add_discard(card_owner)
	# Destroy in place (no discard animation)
	if card.has_node("Area2D/CollisionShape2D"):
		card.get_node("Area2D/CollisionShape2D").disabled = true
	var tween = get_tree().create_tween()
	tween.tween_property(card, "scale", card.scale * 0.6, 0.15)
	tween.parallel().tween_property(card, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.tween_callback(func(): card.queue_free())


func enemy_card_selected(defending_card):
	if game_over:
		return
	var attacking_card = $"../CardManager".selected_monster
	if attacking_card :
		if defending_card in opponent_cards_on_battlefield:
			if has_taunt("Opponent") and !defending_card.has_keyword("Taunt"):
				return
			$"../CardManager".selected_monster = null
			await attack(attacking_card, defending_card, "Player")



func try_play_card_with_highest_attack():
	# PLay the card in hard with highest attack
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		await end_opponent_turn()
		return

	var playable_cards = []
	for card in opponent_hand:
		if can_play_card(card, "Opponent"):
			playable_cards.append(card)
	if playable_cards.size() == 0:
		return
	
	var card_with_highest_atk = playable_cards[0]
	for card in playable_cards:
		var card_atk = int(card.attack) if card.attack != null else 0
		var best_atk = int(card_with_highest_atk.attack) if card_with_highest_atk.attack != null else 0
		if card_atk > best_atk:
			card_with_highest_atk = card

	if card_with_highest_atk.card_type == "Magic":
		_cast_opponent_magic(card_with_highest_atk)
		await wait(0.5)
		return

	var random_empty_monster_card_slot  = empty_monster_card_slots.pick_random()
	empty_monster_card_slots.erase(random_empty_monster_card_slot)
	if random_empty_monster_card_slot.has_method("set_occupied"):
		random_empty_monster_card_slot.set_occupied(true)
	else:
		random_empty_monster_card_slot.card_in_slot = true
	_set_slot_highlight(random_empty_monster_card_slot, true)
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_atk, "position", random_empty_monster_card_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(card_with_highest_atk, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	if card_with_highest_atk.has_method("play_flip_to_front"):
		card_with_highest_atk.play_flip_to_front()
	elif card_with_highest_atk.has_node("AnimationPlayer"):
		card_with_highest_atk.get_node("AnimationPlayer").play("card_flip")
	
	$"../OpponentHand".remove_card_from_hand(card_with_highest_atk)
	card_with_highest_atk.card_slot_card_is_in = random_empty_monster_card_slot
	opponent_cards_on_battlefield.append(card_with_highest_atk)
	card_with_highest_atk.summoning_sick = !card_with_highest_atk.has_keyword("Charge")
	spend_energy(int(card_with_highest_atk.cost), "Opponent")
	await wait(CARD_MOVE_SPEED + 0.1)
	_set_slot_highlight(random_empty_monster_card_slot, false)
	if ability_bus:
		ability_bus.emit_event(
			AbilityBus.EVENT_ON_PLAY,
			{
				"battle_manager": self,
				"input_manager": $"../InputManager",
				"source": card_with_highest_atk,
				"card": card_with_highest_atk,
				"turn_owner": "Opponent"
			}
		)
	
	await wait(1.0)

func _cast_opponent_magic(card):
	if card == null:
		return
	$"../OpponentHand".remove_card_from_hand(card)
	card.card_owner = "Opponent"
	var magic_slot = $"../CradSlots".get_node_or_null("MagicSlotOpponent")
	if magic_slot != null:
		if magic_slot.has_method("set_occupied"):
			magic_slot.set_occupied(true)
		else:
			magic_slot.card_in_slot = true
		_set_slot_highlight(magic_slot, true)
		card.card_slot_card_is_in = magic_slot
		card.position = magic_slot.position
		await wait(0.25)
		_set_slot_highlight(magic_slot, false)
	spend_energy(int(card.cost), "Opponent")
	var context = {
		"battle_manager": self,
		"input_manager": $"../InputManager",
		"source": card,
		"card": card,
		"turn_owner": "Opponent"
	}
	_trigger_card_ability(card, AbilityBus.EVENT_ON_PLAY, context)
	if ability_bus:
		var bus_context = context.duplicate()
		bus_context.skip_self = true
		ability_bus.emit_event(AbilityBus.EVENT_ON_PLAY, bus_context)

func _trigger_card_ability(card, event_name: String, context: Dictionary) -> void:
	if card == null:
		return
	if card.ability_script == null or !card.ability_script.has_method("on_event"):
		return
	var local_context = context.duplicate()
	local_context.self_card = card
	card.ability_script.on_event(event_name, local_context)

func _set_slot_highlight(slot, active: bool) -> void:
	if slot == null:
		return
	if slot.has_method("set_highlight"):
		slot.set_highlight(active)

func wait(wait_time):
	await get_tree().create_timer(wait_time).timeout

func end_opponent_turn():
	if game_over:
		return
	if ability_bus:
		ability_bus.emit_event(
			AbilityBus.EVENT_TURN_END,
			{
				"battle_manager": self,
				"input_manager": $"../InputManager",
				"turn_owner": "Opponent"
			}
	)
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_monster()
	is_opponents_turn = false
	var button = get_node_or_null("../EndTurnButton")
	if button != null and button.has_method("play_back_transition_to_ready"):
		await button.play_back_transition_to_ready()
	begin_turn("Player")
	end_turn_button_enabled(true)

func check_game_over():
	if game_over:
		return
	if player_health <= 0:
		set_game_over("Opponent")
	elif opponent_health <= 0:
		set_game_over("Player")

func set_game_over(winner: String):
	game_over = true
	$"../InputManager".inputs_disabled = true
	end_turn_button_enabled(false)
	_log_action_result(winner)
	if has_node("../EndGameOverlay"):
		$"../EndGameOverlay".visible = true
		if has_node("../EndGameOverlay/Overlay/EndGameLabel"):
			if winner == "Player":
				$"../EndGameOverlay/Overlay/EndGameLabel".text = "Victory"
			else:
				$"../EndGameOverlay/Overlay/EndGameLabel".text = "Defeat"

func _log_action_result(winner: String) -> void:
	var log = get_node_or_null("../ActionLogLayer/ActionLogPanel/ActionLogScroll/ActionLog")
	if log == null or !log.has_method("log_event"):
		return
	if winner == "Player":
		log.log_event("Player wins")
	else:
		log.log_event("Opponent wins")

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func begin_turn(turn_owner: String):
	if game_over:
		return
	if turn_owner == "Player":
		_set_end_turn_state("ready")
	else:
		_set_end_turn_state("enemy")
	_set_turn_phase(turn_owner, "Main")
	var prev_player_energy = player_energy
	var prev_opponent_energy = opponent_energy
	if turn_owner == "Player":
		player_max_energy = min(MAX_ENERGY, player_max_energy + ENERGY_GROWTH)
		player_energy = player_max_energy
		for card in player_cards_on_battlefield:
			card.summoning_sick = false
			if card.evolve_next_id != "":
				card.set_evolve_ready(true)
	else:
		opponent_max_energy = min(MAX_ENERGY, opponent_max_energy + ENERGY_GROWTH)
		opponent_energy = opponent_max_energy
		for card in opponent_cards_on_battlefield:
			card.summoning_sick = false
			if card.evolve_next_id != "":
				card.set_evolve_ready(true)
				_try_auto_evolve(card)
	_update_energy_labels(turn_owner)
	_pulse_energy_if_changed(prev_player_energy, prev_opponent_energy)
	show_turn_label(turn_owner)
	if ability_bus:
		ability_bus.emit_event(
			AbilityBus.EVENT_TURN_START,
			{
				"battle_manager": self,
				"input_manager": $"../InputManager",
				"turn_owner": turn_owner,
				"player_energy": player_energy,
				"opponent_energy": opponent_energy,
				"player_max_energy": player_max_energy,
				"opponent_max_energy": opponent_max_energy
			}
		)

func _try_auto_evolve(card):
	if card == null:
		return
	if !card.evolve_ready:
		return
	if card.evolve_cost > opponent_energy:
		return
	try_evolve_card(card, "Opponent")

func try_evolve_card(card, owner: String) -> bool:
	if card == null:
		return false
	if card.evolve_next_id == "":
		return false
	if !card.evolve_ready:
		return false
	var cost = int(card.evolve_cost)
	if owner == "Player":
		if player_energy < cost:
			return false
		spend_energy(cost, "Player")
	else:
		if opponent_energy < cost:
			return false
		spend_energy(cost, "Opponent")
	if card.has_method("prepare_evolve_animation"):
		card.prepare_evolve_animation()
	var next_id = card.evolve_next_id
	_apply_card_data_to_card(card, next_id)
	if card.has_method("play_evolve_animation"):
		card.play_evolve_animation(true)
	card.evolve_ready = false
	card.set_evolve_ready(false)
	return true

func _apply_card_data_to_card(card, card_id: String):
	var data = card_database_reference.get_card(card_id)
	if data.is_empty():
		return
	card.card_id = card_id
	card.card_type = data.get("type", "Monster")
	card.card_faction = str(data.get("faction", ""))
	card.cost = int(data.get("cost", 0))
	var parsed_keywords = data.get("keywords", [])
	card.keywords = parsed_keywords.duplicate() if typeof(parsed_keywords) == TYPE_ARRAY else []
	var parsed_params = data.get("ability_params", {})
	card.ability_params = parsed_params.duplicate(true) if typeof(parsed_params) == TYPE_DICTIONARY else {}
	card.evolve_next_id = str(data.get("evolve_next_id", ""))
	card.evolve_cost = int(data.get("evolve_cost", 0))
	var ability_script_path = data.get("ability_script", "")
	card.ability_script = null
	if ability_script_path:
		card.ability_script = load(ability_script_path).new()
	if card.has_method("set_name_and_description"):
		card.set_name_and_description(str(data.get("name", card_id)), str(data.get("ability_text", "")))
	if card.card_type == "Monster":
		var atk = int(data.get("attack", 0))
		var hp = int(data.get("health", 0))
		if card.has_method("set_attack_value"):
			card.set_attack_value(atk)
		else:
			card.attack = atk
		if card.has_method("set_health_value"):
			card.set_health_value(hp, true)
		else:
			card.health = hp
		if card.has_node("Attack"):
			card.get_node("Attack").visible = true
		if card.has_node("Health"):
			card.get_node("Health").visible = true
		if card.has_node("HealthBarBg"):
			card.get_node("HealthBarBg").visible = true
		if card.has_node("HealthBarFill"):
			card.get_node("HealthBarFill").visible = true
	else:
		if card.has_node("Attack"):
			card.get_node("Attack").visible = false
		if card.has_node("Health"):
			card.get_node("Health").visible = false
		if card.has_node("HealthBarBg"):
			card.get_node("HealthBarBg").visible = false
		if card.has_node("HealthBarFill"):
			card.get_node("HealthBarFill").visible = false
	if card.has_method("set_cost_evolve_text"):
		card.set_cost_evolve_text()

func _update_card_health_ui(card):
	if card == null:
		return
	if card.has_method("set_health_value"):
		card.set_health_value(int(card.health), false)
	elif card.has_node("Health"):
		card.get_node("Health").text = str(card.health)

func can_play_card(card, owner: String) -> bool:
	if card == null:
		return false
	var cost = int(card.cost)
	if owner == "Player":
		return player_energy >= cost
	return opponent_energy >= cost

func spend_energy(cost: int, owner: String):
	var prev_player = player_energy
	var prev_opponent = opponent_energy
	if owner == "Player":
		player_energy = max(0, player_energy - cost)
	else:
		opponent_energy = max(0, opponent_energy - cost)
	_update_energy_labels()
	_pulse_energy_if_changed(prev_player, prev_opponent)

func _update_energy_labels(charge_owner: String = ""):
	if has_node("../PlayerEnergy"):
		$"../PlayerEnergy".text = str(player_energy) + "/" + str(player_max_energy)
	if has_node("../OpponentEnergy"):
		$"../OpponentEnergy".text = str(opponent_energy) + "/" + str(opponent_max_energy)
	_set_label_text(PLAYER_ENERGY_PATH, str(player_energy) + "/" + str(player_max_energy))
	_set_label_text(OPPONENT_ENERGY_PATH, str(opponent_energy) + "/" + str(opponent_max_energy))
	_update_mana_bar("Player")
	_update_mana_bar("Opponent")
	_update_energy_crystals("Player")
	_update_energy_crystals("Opponent")
	if charge_owner != "":
		_animate_energy_charge(charge_owner)

func _update_health_labels():
	if has_node("../PlayerHealth"):
		$"../PlayerHealth".text = str(player_health)
	if has_node("../OpponentHealth"):
		$"../OpponentHealth".text = str(opponent_health)
	var player_label = _set_label_text(PLAYER_HEALTH_PATH, str(player_health))
	var opponent_label = _set_label_text(OPPONENT_HEALTH_PATH, str(opponent_health))
	if _last_player_health != player_health:
		_pulse_control(player_label)
		_last_player_health = player_health
	if _last_opponent_health != opponent_health:
		_pulse_control(opponent_label)
		_last_opponent_health = opponent_health

func add_discard(owner: String, amount: int = 1) -> void:
	return


func _update_discard_labels() -> void:
	return


func _pulse_energy_if_changed(prev_player: int, prev_opponent: int) -> void:
	if prev_player != player_energy:
		var label = get_node_or_null(PLAYER_ENERGY_PATH)
		_pulse_control(label)
		_pulse_mana_bar("Player")
	if prev_opponent != opponent_energy:
		var label = get_node_or_null(OPPONENT_ENERGY_PATH)
		_pulse_control(label)
		_pulse_mana_bar("Opponent")

func _set_label_text(path: String, text: String):
	var node = get_node_or_null(path)
	if node == null:
		return null
	if node is RichTextLabel:
		node.text = text
	elif node is Label:
		node.text = text
	return node

func _update_energy_crystals(owner: String) -> void:
	var container = null
	var energy = 0
	var max_energy = 0
	if owner == "Player":
		container = get_node_or_null(PLAYER_CRYSTALS_PATH)
		energy = player_energy
		max_energy = player_max_energy
	else:
		container = get_node_or_null(OPPONENT_CRYSTALS_PATH)
		energy = opponent_energy
		max_energy = opponent_max_energy
	if container == null or !(container is HBoxContainer):
		return
	_ensure_crystal_count(container as HBoxContainer, max_energy)
	for i in range(max_energy):
		var crystal = container.get_child(i)
		_set_crystal_style(crystal, i < energy)

func _ensure_crystal_count(container: HBoxContainer, max_energy: int) -> void:
	while container.get_child_count() < max_energy:
		var crystal = TextureRect.new()
		crystal.custom_minimum_size = ENERGY_CRYSTAL_SIZE
		crystal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		crystal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		crystal.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		crystal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(crystal)
	while container.get_child_count() > max_energy:
		var last_index = container.get_child_count() - 1
		var child = container.get_child(last_index)
		child.queue_free()

func _set_crystal_style(crystal, active: bool) -> void:
	if crystal == null or !(crystal is Control):
		return
	if crystal is TextureRect:
		crystal.texture = ENERGY_ACTIVE_TEX if active else ENERGY_INACTIVE_TEX
		crystal.self_modulate = Color(1, 1, 1, 1) if active else Color(1, 1, 1, 0.35)
		return
	var style = StyleBoxFlat.new()
	style.bg_color = ENERGY_ACTIVE_COLOR if active else ENERGY_INACTIVE_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = ENERGY_BORDER_COLOR
	style.corner_radius_top_left = ENERGY_CRYSTAL_RADIUS
	style.corner_radius_top_right = ENERGY_CRYSTAL_RADIUS
	style.corner_radius_bottom_left = ENERGY_CRYSTAL_RADIUS
	style.corner_radius_bottom_right = ENERGY_CRYSTAL_RADIUS
	crystal.add_theme_stylebox_override("panel", style)

func _animate_energy_charge(owner: String) -> void:
	var container = null
	var energy = 0
	if owner == "Player":
		container = get_node_or_null(PLAYER_CRYSTALS_PATH)
		energy = player_energy
	else:
		container = get_node_or_null(OPPONENT_CRYSTALS_PATH)
		energy = opponent_energy
	if container == null or !(container is HBoxContainer):
		return
	var count = min(energy, container.get_child_count())
	for i in range(count):
		var crystal = container.get_child(i)
		if crystal == null or !(crystal is Control):
			continue
		crystal.scale = Vector2(0.8, 0.8)
		var tween = get_tree().create_tween()
		tween.tween_interval(i * 0.05)
		tween.tween_property(crystal, "scale", Vector2(1.12, 1.12), 0.08)
		tween.tween_property(crystal, "scale", Vector2(1.0, 1.0), 0.08)
	_animate_mana_charge(owner)

func _pulse_control(node) -> void:
	if node == null or !(node is Control):
		return
	node.scale = Vector2(1, 1)
	var tween = get_tree().create_tween()
	tween.tween_property(node, "scale", UI_PULSE_SCALE, 0.08)
	tween.tween_property(node, "scale", Vector2(1, 1), 0.08)


func _ensure_mana_bar(owner: String) -> void:
	var bar_path = MANA_BAR_PLAYER_PATH if owner == "Player" else MANA_BAR_OPPONENT_PATH
	var bar = get_node_or_null(bar_path)
	if bar == null or !(bar is HBoxContainer):
		return
	if bar.get_child_count() != MAX_ENERGY:
		for child in bar.get_children():
			child.queue_free()
		for i in range(MAX_ENERGY):
			var orb = Panel.new()
			orb.custom_minimum_size = MANA_ORB_SIZE
			var style = StyleBoxFlat.new()
			style.bg_color = MANA_ORB_INACTIVE_COLOR
			style.border_color = MANA_ORB_BORDER_COLOR
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			var radius = int(min(MANA_ORB_SIZE.x, MANA_ORB_SIZE.y) / 2)
			style.corner_radius_top_left = radius
			style.corner_radius_top_right = radius
			style.corner_radius_bottom_left = radius
			style.corner_radius_bottom_right = radius
			orb.add_theme_stylebox_override("panel", style)
			orb.set_meta("orb_style", style)
			bar.add_child(orb)
	_update_mana_bar(owner)

func _update_mana_bar(owner: String) -> void:
	var bar_path = MANA_BAR_PLAYER_PATH if owner == "Player" else MANA_BAR_OPPONENT_PATH
	var bar = get_node_or_null(bar_path)
	if bar == null or !(bar is HBoxContainer):
		return
	var max_energy = player_max_energy if owner == "Player" else opponent_max_energy
	var current_energy = player_energy if owner == "Player" else opponent_energy
	for i in range(bar.get_child_count()):
		var orb = bar.get_child(i)
		if orb == null:
			continue
		var color = MANA_ORB_LOCKED_COLOR
		if i < max_energy:
			color = MANA_ORB_ACTIVE_COLOR if i < current_energy else MANA_ORB_INACTIVE_COLOR
		if orb.has_meta("orb_style"):
			var style = orb.get_meta("orb_style")
			if style:
				style.bg_color = color
				orb.add_theme_stylebox_override("panel", style)
		else:
			orb.self_modulate = color

func _animate_mana_charge(owner: String) -> void:
	var bar_path = MANA_BAR_PLAYER_PATH if owner == "Player" else MANA_BAR_OPPONENT_PATH
	var bar = get_node_or_null(bar_path)
	if bar == null or !(bar is HBoxContainer):
		return
	var energy = player_energy if owner == "Player" else opponent_energy
	var count = min(energy, bar.get_child_count())
	for i in range(count):
		var orb = bar.get_child(i)
		if orb == null:
			continue
		orb.scale = Vector2(0.9, 0.9)
		var tween = get_tree().create_tween()
		tween.tween_interval(i * 0.04)
		tween.tween_property(orb, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(orb, "scale", Vector2(1.0, 1.0), 0.08)

func _pulse_mana_bar(owner: String) -> void:
	var bar_path = MANA_BAR_PLAYER_PATH if owner == "Player" else MANA_BAR_OPPONENT_PATH
	var bar = get_node_or_null(bar_path)
	if bar == null or !(bar is Control):
		return
	bar.scale = Vector2(1, 1)
	var tween = get_tree().create_tween()
	tween.tween_property(bar, "scale", Vector2(1.05, 1.05), 0.08)
	tween.tween_property(bar, "scale", Vector2(1, 1), 0.08)

func _set_turn_phase(turn_owner: String, phase: String) -> void:
	var owner_label = get_node_or_null(TURN_OWNER_LABEL_PATH)
	var phase_label = get_node_or_null(TURN_PHASE_LABEL_PATH)
	if owner_label != null:
		owner_label.text = "Player Turn" if turn_owner == "Player" else "Opponent Turn"
	if phase_label != null:
		phase_label.text = phase + " Phase"

func show_turn_label(turn_owner: String):
	if !has_node("../TurnLabel"):
		return
	_set_turn_phase(turn_owner, "Main")
	var label = $"../TurnLabel"
	label.text = "Your Turn" if turn_owner == "Player" else "Enemy Turn"
	label.visible = true
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func(): label.visible = false)


func _on_menu_button_pressed() -> void:
	_toggle_menu()

func _on_menu_resume_pressed() -> void:
	_set_menu_visible(false)

func _on_menu_surrender_pressed() -> void:
	_set_menu_visible(false)
	if !game_over:
		set_game_over("Opponent")

func _on_menu_quit_pressed() -> void:
	get_tree().quit()

func _toggle_menu() -> void:
	var panel = get_node_or_null("../MenuLayer/MenuPanel")
	if panel == null:
		return
	_set_menu_visible(!panel.visible)

func _set_menu_visible(visible: bool) -> void:
	var panel = get_node_or_null("../MenuLayer/MenuPanel")
	if panel == null:
		return
	panel.visible = visible
	if has_node("../InputManager"):
		$"../InputManager".inputs_disabled = visible
	if has_node("../EndTurnButton"):
		$"../EndTurnButton".disabled = visible

func show_hand_full(owner: String):
	if owner != "Player":
		return
	if !has_node("../HandLimitLabel"):
		return
	var label = $"../HandLimitLabel"
	label.visible = true
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func(): label.visible = false)

func has_taunt(target_owner: String) -> bool:
	var cards = opponent_cards_on_battlefield if target_owner == "Opponent" else player_cards_on_battlefield
	for card in cards:
		if card.has_keyword("Taunt"):
			return true
	return false

func get_taunt_targets(target_owner: String) -> Array:
	var cards = opponent_cards_on_battlefield if target_owner == "Opponent" else player_cards_on_battlefield
	var taunts = []
	for card in cards:
		if card.has_keyword("Taunt"):
			taunts.append(card)
	return taunts

func enable_and_turn_button(is_enabled):
	end_turn_button_enabled(is_enabled)
