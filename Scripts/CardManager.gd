extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEEED = 0.1
const DEFAULT_CARD_SCALE = 1
const CARD_BIGGER_SCALE = 0.9
const CARD_SMALLER_SCALE = 0.9

var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference
var played_monster_card_this_turn = false
var selected_monster
var ability_bus
var hovered_slot
@onready var card_info_panel: Control = get_node_or_null("../CardInfoLayer/CardInfoPanel")
@onready var card_info_text: RichTextLabel = get_node_or_null("../CardInfoLayer/CardInfoPanel/CardInfoText")
@onready var card_info_title: Label = get_node_or_null("../CardInfoLayer/CardInfoPanel/CardInfoTitle")
@onready var card_info_cost_value: Label = get_node_or_null("../CardInfoLayer/CardInfoPanel/CardInfoStats/CardInfoCost/CardInfoCostValue")
@onready var card_info_attack_box: HBoxContainer = get_node_or_null("../CardInfoLayer/CardInfoPanel/CardInfoStats/CardInfoAttack")
@onready var card_info_attack_value: Label = get_node_or_null("../CardInfoLayer/CardInfoPanel/CardInfoStats/CardInfoAttack/CardInfoAttackValue")
@onready var card_info_health_box: HBoxContainer = get_node_or_null("../CardInfoLayer/CardInfoPanel/CardInfoStats/CardInfoHealth")
@onready var card_info_health_value: Label = get_node_or_null("../CardInfoLayer/CardInfoPanel/CardInfoStats/CardInfoHealth/CardInfoHealthValue")

func _ready():
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	ability_bus = $"../AbilityBus"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)
	_set_card_info_visible(false)

func _process(_delta: float):
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), 
			clamp(mouse_pos.y, 0, screen_size.y))
		_update_slot_hover_effect()
	else:
		_clear_slot_hover_effect()
		

func card_clicked(card):
	if card.card_slot_card_is_in:
		if $"../BattleManager".is_opponents_turn:
			return
				
		if card.card_type != "Monster":
			return 
		if card.summoning_sick:
			return
		
		if card in $"../BattleManager".played_cards_that_attacked_this_turn:
			return
		
		if $"../BattleManager".opponent_cards_on_battlefield.size() == 0:
			$"../BattleManager".direct_attack(card, "Player")
		else:
			select_card_for_battle(card)
	else:
		start_drag(card)

func select_card_for_battle(card):
	if selected_monster:
		if selected_monster == card:
			if card.evolve_ready and $"../BattleManager".player_energy >= card.evolve_cost:
				var evolved = $"../BattleManager".try_evolve_card(card, "Player")
				if evolved:
					card.position.y += 20
					selected_monster = null
					return
			card.position.y += 20
			selected_monster = null
		else:
			selected_monster.position.y += 20
			selected_monster = card
			card.position.y -= 20
	else:
		selected_monster = card
		card.position.y -= 20
	


func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
	_set_card_info_visible(false)
	if card_being_dragged and card_being_dragged.has_method("set_dragging"):
		card_being_dragged.set_dragging(true)
	_clear_slot_hover_effect()
	
	
func finish_drag():
	card_being_dragged.scale = Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE)
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		if card_being_dragged.card_type == "Magic" and card_slot_found.card_slot_type == "Magic":
			if !$"../BattleManager".can_play_card(card_being_dragged, "Player"):
				player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEEED)
				_clear_dragging_state()
				card_being_dragged = null
				return
			_cast_magic_from_hand(card_being_dragged, card_slot_found)
			_clear_slot_hover_effect()
			_clear_dragging_state()
			card_being_dragged = null
			return
		if card_being_dragged.card_type == card_slot_found.card_slot_type:
			
			if card_being_dragged.card_type == "Monster" && played_monster_card_this_turn:
				player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEEED)
				_clear_dragging_state()
				card_being_dragged = null
				return
			if !$"../BattleManager".can_play_card(card_being_dragged, "Player"):
				player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEEED)
				_clear_dragging_state()
				card_being_dragged = null
				return
				
			card_being_dragged.scale = Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE)
			card_being_dragged.z_index = -1
			is_hovering_on_card = false
			card_being_dragged.card_slot_card_is_in = card_slot_found
			player_hand_reference.remove_card_from_hand(card_being_dragged)
			card_being_dragged.position = card_slot_found.position
			if card_slot_found.has_method("set_occupied"):
				card_slot_found.set_occupied(true)
			else:
				card_slot_found.card_in_slot = true
			card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true
			
			
			if card_being_dragged.card_type == "Monster":
				$"../BattleManager".player_cards_on_battlefield.append(card_being_dragged)
				played_monster_card_this_turn = true
				card_being_dragged.summoning_sick = !card_being_dragged.has_keyword("Charge")
			
			$"../BattleManager".spend_energy(int(card_being_dragged.cost), "Player")
			
			if ability_bus:
				ability_bus.emit_event(
					AbilityBus.EVENT_ON_PLAY,
					{
						"battle_manager": $"../BattleManager",
						"input_manager": $"../InputManager",
						"source": card_being_dragged,
						"card": card_being_dragged,
						"turn_owner": "Player"
					}
				)
			
			_clear_dragging_state()
			card_being_dragged = null
			_clear_slot_hover_effect()
			return 
	if card_being_dragged.card_type == "Magic":
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEEED)
		_clear_dragging_state()
		card_being_dragged = null
		_clear_slot_hover_effect()
		return
	player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEEED)
	_clear_dragging_state()
	card_being_dragged = null
	_clear_slot_hover_effect()

func _clear_dragging_state() -> void:
	if card_being_dragged and card_being_dragged.has_method("set_dragging"):
		card_being_dragged.set_dragging(false)

func _cast_magic_from_hand(card, slot = null):
	if $"../BattleManager".is_opponents_turn:
		player_hand_reference.add_card_to_hand(card, DEFAULT_CARD_MOVE_SPEEED)
		return
	if !$"../BattleManager".can_play_card(card, "Player"):
		player_hand_reference.add_card_to_hand(card, DEFAULT_CARD_MOVE_SPEEED)
		return
	card.scale = Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE)
	card.card_owner = "Player"
	card.z_index = -1
	is_hovering_on_card = false
	player_hand_reference.remove_card_from_hand(card)
	if slot != null:
		card.card_slot_card_is_in = slot
		card.position = slot.position
		if slot.has_method("set_occupied"):
			slot.set_occupied(true)
		else:
			slot.card_in_slot = true
		if slot.has_node("Area2D/CollisionShape2D"):
			slot.get_node("Area2D/CollisionShape2D").disabled = true
	else:
		card.card_slot_card_is_in = null
		card.position = Vector2(card.position.x, card.position.y - 120)
	$"../BattleManager".spend_energy(int(card.cost), "Player")
	var context = {
		"battle_manager": $"../BattleManager",
		"input_manager": $"../InputManager",
		"source": card,
		"card": card,
		"turn_owner": "Player"
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


func unselect_selected_monster():
	if selected_monster:
		selected_monster.position.y += 20
		selected_monster = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_left_click_released():
	if card_being_dragged:
		finish_drag()


func on_hovered_over_card(card):
	_show_card_info(card)
	if card.get("card_owner") == "Opponent":
		return
	if card.card_slot_card_is_in:
		return
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)
	
func on_hovered_off_card(card):
	var new_card_hovered = raycast_check_for_card()
	if new_card_hovered:
		_show_card_info(new_card_hovered)
	else:
		_set_card_info_visible(false)
	if card.get("card_owner") == "Opponent":
		return
	if !card.defeated:
		if !card.card_slot_card_is_in && !card_being_dragged:
			highlight_card(card, false)
			if new_card_hovered:
				highlight_card(new_card_hovered, true)
			else:
				is_hovering_on_card = false
		

func highlight_card(card, hovered):
	if card.card_slot_card_is_in:
		return
	if card.has_method("set_hovered"):
		card.set_hovered(hovered)
		return
	
	if hovered:
		card.scale = Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 1

func _set_card_info_visible(visible: bool) -> void:
	if card_info_panel:
		card_info_panel.visible = visible

func _show_card_info(card) -> void:
	if card == null or card_info_panel == null or card_info_text == null:
		return
	var owner = card.get("card_owner")
	if owner == "Opponent" and card.get("card_slot_card_is_in") == null:
		_set_card_info_visible(false)
		return
	var front = card.get("card_front")
	if front != null and front is Node2D and not front.visible:
		_set_card_info_visible(false)
		return
	var display_name = _get_card_display_name(card)
	if card_info_cost_value != null:
		card_info_cost_value.text = str(card.cost)
	if card.card_type == "Monster":
		if card_info_attack_box != null:
			card_info_attack_box.visible = true
		if card_info_health_box != null:
			card_info_health_box.visible = true
		var max_hp: int = int(card.max_health) if int(card.max_health) > 0 else int(card.health)
		if card_info_attack_value != null:
			card_info_attack_value.text = str(card.attack)
		if card_info_health_value != null:
			card_info_health_value.text = str(max_hp)
	else:
		if card_info_attack_box != null:
			card_info_attack_box.visible = false
		if card_info_health_box != null:
			card_info_health_box.visible = false
	if card_info_title != null:
		card_info_title.text = display_name
		card_info_text.text = _build_card_info_body(card, display_name)
	else:
		card_info_text.text = _build_card_info_text(card)
	_position_card_info_panel()
	card_info_panel.visible = true

func _get_card_display_name(card) -> String:
	var name_val = card.get("card_display_name")
	if name_val != null and str(name_val) != "":
		return str(name_val)
	return str(card.card_id)

func _build_card_info_body(card, display_name: String = "") -> String:
	if display_name == "":
		display_name = _get_card_display_name(card)
	var faction := str(card.card_faction)
	var type_text := str(card.card_type)
	var ability := ""
	var ability_val = card.get("ability_text")
	if ability_val != null:
		ability = str(ability_val)
	if ability.strip_edges() == "":
		ability = "\u65e0"
	var lines := PackedStringArray()
	lines.append("\u7c7b\u578b: " + type_text + "  \u9635\u8425: " + faction)
	lines.append("\u6548\u679c: " + ability)
	return "\n".join(lines)

func _build_card_info_text(card) -> String:
	var display_name = _get_card_display_name(card)
	var body = _build_card_info_body(card, display_name)
	if body == "":
		return display_name
	return display_name + "\n" + body

func _position_card_info_panel() -> void:
	if card_info_panel == null:
		return
	var viewport_size = get_viewport_rect().size
	var panel_size = card_info_panel.size
	var pos = get_viewport().get_mouse_position() + Vector2(24, 24)
	pos.x = clamp(pos.x, 8.0, viewport_size.x - panel_size.x - 8.0)
	pos.y = clamp(pos.y, 8.0, viewport_size.y - panel_size.y - 8.0)
	card_info_panel.position = pos

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters) 
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return result[0].collider.get_parent()
	return null

func _update_slot_hover_effect() -> void:
	if card_being_dragged == null:
		return
	var slot = raycast_check_for_card_slot()
	if slot != hovered_slot:
		if hovered_slot != null:
			_set_slot_highlight(hovered_slot, false)
		hovered_slot = slot
	if hovered_slot != null:
		_set_slot_highlight(hovered_slot, _is_valid_slot_for_card(card_being_dragged, hovered_slot))

func _clear_slot_hover_effect() -> void:
	if hovered_slot != null:
		_set_slot_highlight(hovered_slot, false)
		hovered_slot = null

func _set_slot_highlight(slot, active: bool) -> void:
	if slot == null:
		return
	if slot.has_method("set_highlight"):
		slot.set_highlight(active)

func _is_valid_slot_for_card(card, slot) -> bool:
	if card == null or slot == null:
		return false
	if $"../BattleManager".is_opponents_turn:
		return false
	if slot.card_in_slot:
		return false
	if card.card_type == "Magic":
		if slot.card_slot_type != "Magic":
			return false
		return $"../BattleManager".can_play_card(card, "Player")
	if card.card_type != slot.card_slot_type:
		return false
	if card.card_type == "Monster" and played_monster_card_this_turn:
		return false
	return $"../BattleManager".can_play_card(card, "Player")

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters) 
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_card_with_highest_z_index(result)
	return null


func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
	

func reset_played_monster():
	played_monster_card_this_turn = false
