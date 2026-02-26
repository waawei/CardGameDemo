extends TextureButton

@onready var ready_sprite: Sprite2D = get_node_or_null("ReadySprite")
@onready var ready_glow: Sprite2D = get_node_or_null("ReadyGlow")
@onready var ending_sprite: Sprite2D = get_node_or_null("EndingSprite")
@onready var enemy_sprite: Sprite2D = get_node_or_null("EnemySprite")
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")

var _state := "ready"
var _prev_state := ""
var _pulse_time := 0.0
var _pulse_active := false
var _ready_base_scale := Vector2.ONE
var _ready_glow_base_scale := Vector2.ONE
const PULSE_PERIOD := 1.6
const PULSE_BRIGHTNESS := 1.15
const PULSE_SCALE := 1.03
const PULSE_GLOW_SCALE := 1.08
const PULSE_GLOW_ALPHA := 0.35

func _ready() -> void:
	if ready_sprite != null:
		_ready_base_scale = ready_sprite.scale
	if ready_glow != null:
		_ready_glow_base_scale = ready_glow.scale
		ready_glow.modulate = Color(1, 1, 1, 0)
		if ready_glow.material == null:
			var glow_mat := CanvasItemMaterial.new()
			glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			ready_glow.material = glow_mat
	set_process(false)
	_apply_state(_state)

func set_state(new_state: String) -> void:
	if new_state == "" or new_state == _state:
		return
	_prev_state = _state
	_state = new_state
	_apply_state(_state)

func _apply_state(state: String) -> void:
	_stop_anim()
	match state:
		"ready":
			show_ready()
		"ending":
			show_ending()
		"enemy":
			show_enemy()

func show_ready() -> void:
	disabled = false
	_show_only(ready_sprite)
	_start_pulse()

func show_ending() -> void:
	disabled = true
	_stop_pulse()
	_show_only(ending_sprite)

func show_enemy() -> void:
	disabled = true
	_stop_pulse()
	_show_only(enemy_sprite)

func play_transition_to_enemy() -> void:
	disabled = true
	_stop_pulse()
	if anim and anim.has_animation("Transition"):
		_prepare_transition_start("ready")
		anim.play("Transition")
		await anim.animation_finished
	_show_only(enemy_sprite)

func play_back_transition_to_ready() -> void:
	disabled = true
	_stop_pulse()
	if anim and anim.has_animation("BackTransition"):
		_prepare_transition_start("enemy")
		anim.play("BackTransition")
		await anim.animation_finished
	disabled = false
	_show_only(ready_sprite)
	_start_pulse()

func _show_only(sprite: Sprite2D) -> void:
	var is_ready = sprite == ready_sprite
	_set_sprite_visible(ready_sprite, is_ready)
	_set_sprite_visible(ending_sprite, sprite == ending_sprite)
	_set_sprite_visible(enemy_sprite, sprite == enemy_sprite)
	if ready_glow != null:
		ready_glow.visible = is_ready
		ready_glow.modulate = Color(1, 1, 1, 0)
		ready_glow.scale = _ready_glow_base_scale

func _set_sprite_visible(sprite: Sprite2D, visible: bool) -> void:
	if sprite == null:
		return
	sprite.visible = visible
	sprite.modulate = Color(1, 1, 1, 1)

func _prepare_transition_start(start_state: String) -> void:
	if ready_sprite == null or ending_sprite == null or enemy_sprite == null:
		return
	ready_sprite.visible = true
	ending_sprite.visible = true
	enemy_sprite.visible = true
	if ready_glow != null:
		ready_glow.visible = false
		ready_glow.modulate = Color(1, 1, 1, 0)
	if start_state == "enemy":
		enemy_sprite.modulate = Color(1, 1, 1, 1)
		ending_sprite.modulate = Color(1, 1, 1, 0)
		ready_sprite.modulate = Color(1, 1, 1, 0)
	else:
		ready_sprite.modulate = Color(1, 1, 1, 1)
		ending_sprite.modulate = Color(1, 1, 1, 0)
		enemy_sprite.modulate = Color(1, 1, 1, 0)

func _stop_anim() -> void:
	if anim and anim.is_playing():
		anim.stop()

func _start_pulse() -> void:
	if ready_sprite == null:
		return
	_pulse_active = true
	_pulse_time = 0.0
	set_process(true)
	ready_sprite.modulate = Color(1, 1, 1, 1)
	ready_sprite.scale = _ready_base_scale
	if ready_glow != null:
		ready_glow.visible = true
		ready_glow.modulate = Color(1, 1, 1, 0)
		ready_glow.scale = _ready_glow_base_scale

func _stop_pulse() -> void:
	_pulse_active = false
	set_process(false)
	if ready_sprite != null:
		ready_sprite.modulate = Color(1, 1, 1, 1)
		ready_sprite.scale = _ready_base_scale
	if ready_glow != null:
		ready_glow.modulate = Color(1, 1, 1, 0)
		ready_glow.scale = _ready_glow_base_scale

func _process(delta: float) -> void:
	if !_pulse_active or ready_sprite == null:
		return
	_pulse_time += delta
	var phase = (_pulse_time / PULSE_PERIOD) * TAU
	var t = (sin(phase) + 1.0) * 0.5
	var bright = lerp(1.0, PULSE_BRIGHTNESS, t)
	ready_sprite.modulate = Color(bright, bright, bright, 1.0)
	ready_sprite.scale = _ready_base_scale * lerp(1.0, PULSE_SCALE, t)
	if ready_glow != null:
		var glow_alpha = lerp(0.0, PULSE_GLOW_ALPHA, t)
		ready_glow.modulate = Color(1.0, 0.95, 0.75, glow_alpha)
		ready_glow.scale = _ready_glow_base_scale * lerp(1.0, PULSE_GLOW_SCALE, t)
