extends RichTextLabel

@export var max_entries: int = 30
@export var keep_latest_visible: bool = true
@export var log_font: Font
@export var line_separation: int = 6

var _entries: Array[String] = []
@onready var _scroll: ScrollContainer = get_parent() as ScrollContainer

func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	autowrap_mode = TextServer.AUTOWRAP_WORD
	if log_font != null:
		add_theme_font_override("normal_font", log_font)
	add_theme_constant_override("line_separation", line_separation)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func log_event(text: String) -> void:
	if text.strip_edges() == "":
		return
	var color = _get_event_color(text)
	var colored = "[color=#%s]%s[/color]" % [color.to_html(false), text]
	_entries.append(colored)
	if _entries.size() > max_entries:
		_entries.pop_front()
	clear()
	for line in _entries:
		append_text(line + "\n")
	_scroll_to_bottom_deferred()

func _get_event_color(text: String) -> Color:
	var lower = text.to_lower()
	if lower.find("wins") != -1 or lower.find("victory") != -1 or lower.find("defeat") != -1:
		return Color(1.0, 0.85, 0.45, 1)
	if lower.find("draw") != -1 or lower.find("drew") != -1 or text.find("抽") != -1:
		return Color(0.7, 0.88, 1.0, 1)
	if lower.find("attack") != -1 or lower.find("attacks") != -1 or text.find("攻击") != -1:
		return Color(1.0, 0.55, 0.5, 1)
	if lower.find("end turn") != -1 or text.find("结束回合") != -1:
		return Color(0.95, 0.82, 0.5, 1)
	if lower.find("heal") != -1 or text.find("治疗") != -1 or text.find("恢复") != -1:
		return Color(0.6, 1.0, 0.6, 1)
	return Color(0.92, 0.92, 0.92, 1)

func _scroll_to_bottom_deferred() -> void:
	if !keep_latest_visible:
		return
	if _scroll == null:
		return
	call_deferred("_scroll_to_bottom")

func _scroll_to_bottom() -> void:
	if _scroll == null:
		return
	var bar = _scroll.get_v_scroll_bar()
	if bar:
		_scroll.scroll_vertical = int(bar.max_value)
