extends Node2D

signal hovered
signal hovered_off

const DEFAULT_CARD_SIZE := Vector2(116.25, 186.875)
const DEFAULT_FRAME_KEY := "xinghui"
const CARD_BACK_TEXTURE := preload("res://Assets/cardback.png")
const CARD_BACK_USE_REGION := false
const CARD_BACK_REGION := Rect2()
const STAT_COLORS := {
	"CostLabel": Color(0.92, 0.78, 0.25, 1.0),
	"Attack": Color(0.9, 0.28, 0.2, 1.0),
	"Health": Color(0.2, 0.78, 0.35, 1.0)
}
const STAT_ANCHORS := {
	"CostLabel": "CostAnchor",
	"Attack": "AttackAnchor",
	"Health": "HealthAnchor"
}
const STAT_OUTLINE_COLOR := Color(0.08, 0.07, 0.06, 1.0)
const STAT_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.6)
const STAT_OUTLINE_SIZE := 2
const STAT_SHADOW_OFFSET := Vector2(1, 1)
const STAT_MIN_SIZE := Vector2(12, 12)
const COST_READY_COLOR := Color(0.72, 0.95, 0.7, 1.0)
const COST_LOCKED_COLOR := Color(0.68, 0.6, 0.45, 1.0)
const FRAME_STYLES := {
	"xinghui": {
		"texture": preload("res://Assets/CardTheme/moon_plus.png"),
		"use_region": false,
		"region": Rect2()
	},
	"yingqi": {
		"texture": preload("res://Assets/CardTheme/shadow_plus.png"),
		"use_region": false,
		"region": Rect2()
	},
	"senling": {
		"texture": preload("res://Assets/CardTheme/forest_plus.png"),
		"use_region": false,
		"region": Rect2()
	}
}
const FACTION_TO_FRAME := {
	"星辉": "xinghui",
	"森灵": "senling",
	"影契": "yingqi",
	"xinghui": "xinghui",
	"senling": "senling",
	"yingqi": "yingqi"
}
const TYPE_TO_FRAME := {
	"monster": "xinghui",
	"magic": "xinghui",
	"spell": "xinghui",
	"support": "xinghui",
	"item": "xinghui"
}
const ART_PATH_PATTERNS: Array[String] = [
	"res://Assets/CardFaces/%s.png",
	"res://Assets/CardFaces/%s.webp",
	"res://Assets/Portraits/%s.png",
	"res://Assets/Portraits/%s.webp"
]

@export var frame_style_override: String = ""
@export var portrait_path_override: String = ""
@export var auto_scale_frames := false
@export var auto_fit_portrait := false
@export var portrait_box_ratio := Vector2(0.78, 0.56)
@export var portrait_offset_ratio := Vector2(0.0, -0.12)

@onready var card_front: Node2D = $CardFront
@onready var card_back: Node2D = $CardBack
@onready var card_frame: Sprite2D = $CardFront/CardImage
@onready var card_portrait: Sprite2D = $CardFront/CardCharacterImage
@onready var card_back_image: Sprite2D = $CardBack/CardBackImage

var _pending_visual_refresh := false

var hand_start_position
var card_slot_card_is_in
var _card_id := ""
var _card_type := ""
var _card_faction := ""
var card_display_name := ""
var ability_text := ""
var cost = 0
var card_owner
var keywords = []
var summoning_sick = false
var health: int = 0
var attack: int = 0
var defeated = false
var ability_script
var ability_params = {}
var evolve_next_id = ""
var evolve_cost = 0
var evolve_ready = false
var max_health = 0
const EVOLVE_FADE_TIME := 0.2
var _last_front_visible := true
var _hovered := false
var _dragging := false
var _hover_tween: Tween
var _base_position := Vector2.ZERO
var _base_scale := Vector2.ONE
var _base_z := 0
var _base_front_position := Vector2.ZERO
var _base_front_scale := Vector2.ONE
var _design_front_scale := Vector2.ONE
var _design_back_scale := Vector2.ONE
var _frame_scale_multiplier := Vector2.ONE
var _back_scale_multiplier := Vector2.ONE
var _label_base_pos := {}
var _label_base_size := {}
var _label_base_scale := {}

@export var hover_scale := Vector2(1.3, 1.3)
@export var hover_offset_y := -60.0
@export var hover_tween_time := 0.15
@export var hover_z_index := 100

var card_id: String:
	get:
		return _card_id
	set(value):
		_card_id = value
		_request_visual_refresh()

var card_type: String:
	get:
		return _card_type
	set(value):
		_card_type = value
		_request_visual_refresh()

var card_faction: String:
	get:
		return _card_faction
	set(value):
		_card_faction = value
		_request_visual_refresh()

func _ready():
	# All cards must be a child of CardManager of this will error
	get_parent().connect_card_signals(self)
	_frame_scale_multiplier = _derive_scale_multiplier(card_frame, _get_card_size())
	_back_scale_multiplier = _derive_scale_multiplier(card_back_image, _get_card_size())
	_refresh_visuals()
	if card_front:
		_last_front_visible = card_front.visible
		_design_front_scale = card_front.scale
	if card_back:
		_design_back_scale = card_back.scale
	var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if anim and !anim.is_connected("animation_finished", Callable(self, "_on_card_animation_finished")):
		anim.connect("animation_finished", Callable(self, "_on_card_animation_finished"))
	_sync_ui_visibility()
	_apply_stat_label_styles()
	_force_stat_label_layout()
	_capture_base_transform()

func _process(_delta: float):
	if card_front == null:
		return
	if card_front.visible == _last_front_visible:
		return
	_last_front_visible = card_front.visible
	_sync_ui_visibility()

func _capture_base_transform() -> void:
	_base_position = _get_rest_position()
	_base_scale = scale
	_base_z = z_index
	if card_front:
		_base_front_position = card_front.position
		# Always anchor hover to the design scale to avoid accumulation.
		_base_front_scale = _design_front_scale

func _get_rest_position() -> Vector2:
	if card_slot_card_is_in != null:
		return card_slot_card_is_in.position
	if hand_start_position != null:
		return hand_start_position
	return position

func set_dragging(active: bool) -> void:
	if _dragging == active:
		return
	_dragging = active
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	if active:
		if _hovered:
			_apply_hover_state(false, true)
		_hovered = false
		_capture_base_transform()
	else:
		_capture_base_transform()

func sync_base_transform() -> void:
	_capture_base_transform()

func set_hovered(active: bool, force: bool = false) -> void:
	if _dragging and active:
		return
	if !_hovered and active:
		_capture_base_transform()
	if _hovered == active and !force:
		return
	_hovered = active
	_apply_hover_state(active, false)

func _apply_hover_state(active: bool, instant: bool) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	var target_pos = _base_position
	var target_z = _base_z
	var target_front_scale = _base_front_scale
	if active:
		target_front_scale = Vector2(
			_base_front_scale.x * hover_scale.x,
			_base_front_scale.y * hover_scale.y
		)
		var bottom_offset = _get_bottom_offset_for_front(target_front_scale)
		target_pos = Vector2(
			_base_position.x,
			_base_position.y + hover_offset_y - bottom_offset
		)
		target_z = hover_z_index
	if instant or hover_tween_time <= 0.0:
		if card_front:
			card_front.scale = target_front_scale
		else:
			scale = target_front_scale
		position = target_pos
		z_index = target_z
		_apply_stat_label_hover(target_front_scale, true, null)
		return
	_hover_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if card_front:
		_hover_tween.tween_property(card_front, "scale", target_front_scale, hover_tween_time)
	else:
		_hover_tween.tween_property(self, "scale", target_front_scale, hover_tween_time)
	_hover_tween.tween_property(self, "position", target_pos, hover_tween_time)
	z_index = target_z
	_apply_stat_label_hover(target_front_scale, false, _hover_tween)

func _apply_stat_label_hover(target_front_scale: Vector2, instant: bool, tween: Tween) -> void:
	var base_front = _base_front_scale
	if abs(base_front.x) <= 0.0001:
		base_front.x = 1.0
	if abs(base_front.y) <= 0.0001:
		base_front.y = 1.0
	var factor = Vector2(target_front_scale.x / base_front.x, target_front_scale.y / base_front.y)
	for label_name in STAT_COLORS.keys():
		var label = get_node_or_null(label_name)
		if label == null or !(label is Control):
			continue
		var base_pos: Vector2 = _label_base_pos.get(label_name, label.position)
		var base_scale: Vector2 = _label_base_scale.get(label_name, Vector2.ONE)
		var target_scale = Vector2(base_scale.x * factor.x, base_scale.y * factor.y)
		var target_pos = Vector2(base_pos.x * factor.x, base_pos.y * factor.y)
		if instant or tween == null:
			label.scale = target_scale
			label.position = target_pos
		else:
			tween.tween_property(label, "scale", target_scale, hover_tween_time)
			tween.tween_property(label, "position", target_pos, hover_tween_time)

func _get_bottom_offset_for_front(target_front_scale: Vector2) -> float:
	var size = _get_card_size()
	var base_front_y = _base_front_scale.y
	if abs(base_front_y) <= 0.0001:
		base_front_y = 1.0
	var factor_y = target_front_scale.y / base_front_y
	var root_scale_y = _base_scale.y
	if abs(root_scale_y) <= 0.0001:
		root_scale_y = 1.0
	return (size.y * 0.5) * root_scale_y * (factor_y - 1.0)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)

func has_keyword(keyword: String) -> bool:
	return keywords.has(keyword)

func _request_visual_refresh():
	if !is_inside_tree():
		_pending_visual_refresh = true
		return
	_refresh_visuals()

func _refresh_visuals():
	if !is_inside_tree():
		_pending_visual_refresh = true
		return
	_pending_visual_refresh = false
	if card_frame == null or card_back_image == null or card_portrait == null:
		return
	_apply_back_texture()
	_apply_frame_style()
	_apply_portrait()
	_sync_ui_visibility()

func _apply_stat_label_styles():
	for label_name in STAT_COLORS.keys():
		var label = get_node_or_null(label_name)
		if label == null or !(label is Label):
			continue
		label.z_index = 3
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", STAT_COLORS[label_name])
		label.add_theme_color_override("font_outline_color", STAT_OUTLINE_COLOR)
		label.add_theme_color_override("font_shadow_color", STAT_SHADOW_COLOR)
		label.add_theme_constant_override("outline_size", STAT_OUTLINE_SIZE)
		label.add_theme_constant_override("shadow_offset_x", int(STAT_SHADOW_OFFSET.x))
		label.add_theme_constant_override("shadow_offset_y", int(STAT_SHADOW_OFFSET.y))
	_apply_evolve_label_color()

func _force_stat_label_layout():
	for label_name in STAT_COLORS.keys():
		var label = get_node_or_null(label_name)
		if label == null or !(label is Control):
			continue
		var left: float = float(label.offset_left)
		var top: float = float(label.offset_top)
		var right: float = float(label.offset_right)
		var bottom: float = float(label.offset_bottom)
		var size := Vector2(right - left, bottom - top)
		if size.x < STAT_MIN_SIZE.x:
			size.x = STAT_MIN_SIZE.x
		if size.y < STAT_MIN_SIZE.y:
			size.y = STAT_MIN_SIZE.y
		var anchor_name = STAT_ANCHORS.get(label_name, "")
		var anchor = get_node_or_null(anchor_name)
		if anchor != null and anchor is Node2D:
			label.set_anchors_preset(Control.PRESET_TOP_LEFT)
			label.size = size
			label.position = anchor.position - size * 0.5
		else:
			label.set_anchors_preset(Control.PRESET_TOP_LEFT)
			label.position = Vector2(left, top)
			label.size = size
		_cache_label_base(label_name, label)

func _cache_label_base(label_name: String, label: Control) -> void:
	_label_base_pos[label_name] = label.position
	_label_base_size[label_name] = label.size
	_label_base_scale[label_name] = label.scale

func _get_card_size() -> Vector2:
	var shape_node: CollisionShape2D = get_node_or_null("Area2D/CollisionShape2D")
	if shape_node and shape_node.shape is RectangleShape2D:
		return shape_node.shape.size
	return DEFAULT_CARD_SIZE

func _apply_back_texture():
	_apply_sprite_texture(
		card_back_image,
		CARD_BACK_TEXTURE,
		CARD_BACK_USE_REGION,
		CARD_BACK_REGION,
		_get_card_size(),
		_back_scale_multiplier
	)

func _apply_frame_style():
	var style_key := _resolve_frame_style_key()
	var style: Dictionary = FRAME_STYLES.get(style_key, FRAME_STYLES[DEFAULT_FRAME_KEY])
	_apply_sprite_texture(
		card_frame,
		style["texture"],
		style["use_region"],
		style["region"],
		_get_card_size(),
		_frame_scale_multiplier
	)

func _resolve_frame_style_key() -> String:
	if frame_style_override.strip_edges() != "":
		return frame_style_override.strip_edges().to_lower()
	if _card_faction.strip_edges() != "":
		var faction_key := _card_faction.strip_edges()
		if FACTION_TO_FRAME.has(faction_key):
			return FACTION_TO_FRAME[faction_key]
		var normalized := faction_key.to_lower()
		if FACTION_TO_FRAME.has(normalized):
			return FACTION_TO_FRAME[normalized]
	var type_key := card_type.strip_edges().to_lower()
	if TYPE_TO_FRAME.has(type_key):
		return TYPE_TO_FRAME[type_key]
	return DEFAULT_FRAME_KEY

func _apply_sprite_texture(
	sprite: Sprite2D,
	texture: Texture2D,
	use_region: bool,
	region_rect: Rect2,
	target_size: Vector2,
	scale_multiplier: Vector2 = Vector2.ONE
) -> void:
	if sprite == null or texture == null:
		return
	sprite.texture = texture
	sprite.region_enabled = use_region
	if use_region:
		sprite.region_rect = region_rect
	if !auto_scale_frames:
		return
	var base_scale = _calc_auto_scale(texture, use_region, region_rect, target_size)
	if base_scale == Vector2.ZERO:
		return
	sprite.scale = Vector2(base_scale.x * scale_multiplier.x, base_scale.y * scale_multiplier.y)

func _calc_auto_scale(
	texture: Texture2D,
	use_region: bool,
	region_rect: Rect2,
	target_size: Vector2
) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var size := region_rect.size if use_region else texture.get_size()
	if size.x <= 0 or size.y <= 0:
		return Vector2.ZERO
	if target_size.x <= 0 or target_size.y <= 0:
		return Vector2.ZERO
	return Vector2(target_size.x / size.x, target_size.y / size.y)

func _derive_scale_multiplier(sprite: Sprite2D, target_size: Vector2) -> Vector2:
	if sprite == null or sprite.texture == null:
		return Vector2.ONE
	if !auto_scale_frames:
		return Vector2.ONE
	var base_scale = _calc_auto_scale(sprite.texture, sprite.region_enabled, sprite.region_rect, target_size)
	if base_scale == Vector2.ZERO:
		return Vector2.ONE
	return Vector2(sprite.scale.x / base_scale.x, sprite.scale.y / base_scale.y)

func _apply_portrait():
	var path := _resolve_portrait_path()
	if path == "":
		card_portrait.visible = false
		card_portrait.texture = null
		return
	var texture: Texture2D = load(path)
	if texture == null:
		card_portrait.visible = false
		card_portrait.texture = null
		return
	card_portrait.texture = texture
	card_portrait.visible = true
	var is_magic := card_type.strip_edges().to_lower() == "magic"
	if auto_fit_portrait or is_magic:
		_fit_portrait(texture)

func _resolve_portrait_path() -> String:
	var override_path := portrait_path_override.strip_edges()
	if override_path != "" and ResourceLoader.exists(override_path):
		return override_path
	if _card_id.strip_edges() == "":
		return ""
	var id_key := _card_id.strip_edges()
	for pattern in ART_PATH_PATTERNS:
		var candidate: String = pattern % id_key
		if ResourceLoader.exists(candidate):
			return candidate
	return ""

func _fit_portrait(texture: Texture2D):
	if !auto_fit_portrait:
		return
	var card_size := _get_card_size()
	var box_size := Vector2(card_size.x * portrait_box_ratio.x, card_size.y * portrait_box_ratio.y)
	var tex_size := texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	var portrait_scale: float = min(box_size.x / tex_size.x, box_size.y / tex_size.y)
	card_portrait.scale = Vector2(portrait_scale, portrait_scale)
	card_portrait.position = Vector2(card_size.x * portrait_offset_ratio.x, card_size.y * portrait_offset_ratio.y)

func prepare_evolve_animation():
	if card_back:
		card_back.visible = true
	if card_back_image:
		card_back_image.visible = true
	if card_front:
		card_front.visible = false
		card_front.modulate = Color(1, 1, 1, 0)

func play_evolve_animation(skip_prepare: bool = false):
	if !skip_prepare:
		prepare_evolve_animation()
	var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")
	var duration := 0.0
	if anim and anim.has_animation("card_flip"):
		anim.play("card_flip")
		duration = anim.get_animation("card_flip").length
	_fade_in_front(duration)

func _fade_in_front(delay: float):
	if card_front == null:
		return
	var tween = get_tree().create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func():
		if card_front:
			card_front.visible = true
			card_front.modulate = Color(1, 1, 1, 0)
	)
	tween.tween_property(card_front, "modulate", Color(1, 1, 1, 1), EVOLVE_FADE_TIME)

func _on_card_animation_finished(anim_name: StringName) -> void:
	if anim_name != &"card_flip":
		return
	if card_front:
		card_front.scale = _design_front_scale
	if card_back:
		card_back.scale = _design_back_scale

func set_evolve_ready(is_ready: bool):
	evolve_ready = is_ready
	_apply_evolve_label_color()

func _apply_evolve_label_color():
	var label = get_node_or_null("CostLabel")
	if label == null or !(label is Label):
		return
	label.modulate = Color(1, 1, 1, 1)
	if evolve_next_id == "":
		if STAT_COLORS.has("CostLabel"):
			label.add_theme_color_override("font_color", STAT_COLORS["CostLabel"])
		return
	var color = COST_READY_COLOR if evolve_ready else COST_LOCKED_COLOR
	label.add_theme_color_override("font_color", color)

func set_name_and_description(card_name: String, description: String):
	card_display_name = card_name
	ability_text = description
	if has_node("NameLabel"):
		get_node("NameLabel").text = card_name
	if has_node("Ability"):
		get_node("Ability").text = description

func set_cost_evolve_text():
	if !has_node("CostLabel"):
		return
	var evolve_text = "-"
	if evolve_next_id != "":
		evolve_text = str(evolve_cost)
	get_node("CostLabel").text = str(cost) + "|" + evolve_text

func set_attack_value(value: int):
	attack = value
	if has_node("Attack"):
		get_node("Attack").text = str(attack)

func set_health_value(value: int, update_max: bool = false):
	health = max(0, value)
	if update_max or max_health <= 0:
		max_health = max(1, health)
	if has_node("Health"):
		get_node("Health").text = str(health) + "/" + str(max_health)
	_update_health_bar()

func _update_health_bar():
	if !has_node("HealthBarBg") or !has_node("HealthBarFill"):
		return
	var bg: ColorRect = get_node("HealthBarBg")
	var fill: ColorRect = get_node("HealthBarFill")
	var ratio := 0.0
	if max_health > 0:
		ratio = clamp(float(health) / float(max_health), 0.0, 1.0)
	fill.size.x = bg.size.x * ratio

func _sync_ui_visibility():
	var show_front = true
	if card_front:
		show_front = card_front.visible
	if has_node("CostLabel"):
		get_node("CostLabel").visible = show_front
	if has_node("Attack"):
		get_node("Attack").visible = show_front and card_type == "Monster"
	if has_node("Health"):
		get_node("Health").visible = show_front and card_type == "Monster"
	if has_node("NameLabel"):
		get_node("NameLabel").visible = false
	if has_node("Ability"):
		get_node("Ability").visible = false
