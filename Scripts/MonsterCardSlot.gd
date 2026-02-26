extends Node2D

@export var card_slot_type: String = "Monster"
var card_in_slot = false

@export var dim_color: Color = Color(0.27, 0.27, 0.27, 0.25)
@export var highlight_color: Color = Color(1.2, 1.2, 1.2, 1.0)
@export var tween_duration: float = 0.2

@onready var slot_image: CanvasItem = get_node_or_null("CardSlotImage")
var _highlighted := false
var _tween: Tween

func _ready() -> void:
	if slot_image != null:
		slot_image.modulate = dim_color
	if card_in_slot:
		set_highlight(true)

func set_occupied(occupied: bool) -> void:
	card_in_slot = occupied
	set_highlight(occupied)

func set_highlight(active: bool) -> void:
	if slot_image == null:
		return
	var desired = active or card_in_slot
	if _highlighted == desired:
		return
	_highlighted = desired
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target = highlight_color if desired else dim_color
	_tween.tween_property(slot_image, "modulate", target, tween_duration)
