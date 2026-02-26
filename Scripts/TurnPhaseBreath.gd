extends Node

@export var target_path: NodePath = NodePath("TurnPhaseBg")
@export var min_alpha: float = 0.7
@export var max_alpha: float = 1.0
@export var duration: float = 1.0

var _tween: Tween
@onready var _target: CanvasItem = get_node_or_null(target_path)

func _ready() -> void:
	start_breathing()

func start_breathing() -> void:
	if _target == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_target.modulate.a = max_alpha
	_tween = create_tween().set_loops()
	_tween.tween_property(_target, "modulate:a", max_alpha, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_target, "modulate:a", min_alpha, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func stop_breathing() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	if _target != null:
		_target.modulate.a = 1.0
