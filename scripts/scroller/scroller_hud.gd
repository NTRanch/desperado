class_name ScrollerHud
extends CanvasLayer
## The scroller HUD, built from code: Beat pips, Shift chain,
## current form, HP, the run timer, the boss bar, a centre
## message, a toast line, and the full-screen shift-snap flash.
## Contract: the level calls refresh() every frame; text and pips
## only change when their value does. flash()/pulse_pips() are
## fire-and-forget juice hooks driven from _process with
## unscaled time, so hit-stop never stretches them.

const VIEW_W: float = 1152.0
const VIEW_H: float = 648.0
const PIP_COUNT: int = 8
const PIP_SIZE: float = 18.0
const PIP_FILLED: Color = Color(0.98, 0.7, 0.25)
const PIP_EMPTY: Color = Color(0.3, 0.24, 0.2, 0.6)
const TEXT_COLOR: Color = Color(0.96, 0.92, 0.86)
const PULSE_S: float = 0.18
const FLASH_ALPHA: float = 0.32
const FLASH_DECAY_PER_S: float = 2.6
const TOAST_FADE_S: float = 0.4
const BOSS_BAR_W: float = 420.0

var _flash: ColorRect
var _flash_a: float = 0.0
var _form_label: Label
var _chain_label: Label
var _hp_label: Label
var _timer_label: Label
var _pips: HBoxContainer
var _pip_rects: Array[ColorRect] = []
var _pulse_s: float = 0.0
var _boss_box: VBoxContainer
var _boss_fill: ColorRect
var _boss: FramingAgent = null
var _message_label: Label
var _toast_label: Label
var _toast_s: float = 0.0
var _clear_shown: bool = false
var _last_form_text: String = ""
var _last_chain_text: String = ""
var _last_hp_text: String = ""
var _last_timer_text: String = ""
var _last_beats: int = -1


func _ready() -> void:
	layer = 10
	_build_labels()
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(0.0, 0.0, 0.0, 0.0)
	add_child(_flash)


## Formats a run time as m:ss.t for the timer and clear screen.
static func format_time(t: float) -> String:
	var minutes: int = int(t) / 60
	var seconds: float = t - float(minutes * 60)
	return "%d:%04.1f" % [minutes, seconds]


## Pushes the player's state into the HUD. Cheap: unchanged
## values are not re-set.
func refresh(p: ScrollerPlayer, elapsed_s: float) -> void:
	var form_text: String = "FORM  " + LaForma.name_of(p.form)
	if form_text != _last_form_text:
		_last_form_text = form_text
		_form_label.text = form_text
		_form_label.add_theme_color_override("font_color", LaForma.color_of(p.form))
	var chain_text: String = "SHIFT CHAIN  x%d" % p.chain
	if chain_text != _last_chain_text:
		_last_chain_text = chain_text
		_chain_label.text = chain_text
	var hp_text: String = "HP  %d" % p.hp
	if hp_text != _last_hp_text:
		_last_hp_text = hp_text
		_hp_label.text = hp_text
	var timer_text: String = "TIME  " + format_time(elapsed_s)
	if timer_text != _last_timer_text:
		_last_timer_text = timer_text
		_timer_label.text = timer_text
	if p.beats != _last_beats:
		_last_beats = p.beats
		for i: int in PIP_COUNT:
			_pip_rects[i].color = PIP_FILLED if i < p.beats else PIP_EMPTY
	if _boss != null:
		if is_instance_valid(_boss):
			_boss_fill.custom_minimum_size.x = BOSS_BAR_W * clampf(float(_boss.hp) / float(_boss.max_hp), 0.0, 1.0)
		else:
			_boss = null
			_boss_box.visible = false


## Fires the full-screen snap flash in a form colour.
func flash(color: Color) -> void:
	_flash.color = Color(color.r, color.g, color.b, FLASH_ALPHA)
	_flash_a = FLASH_ALPHA


## Pops the Beat pips (Beat-earned juice).
func pulse_pips() -> void:
	_pulse_s = PULSE_S


## Shows the boss bar for the given framing agent.
func show_boss(boss: FramingAgent) -> void:
	_boss = boss
	_boss_box.visible = true


## Hides the boss bar (duel over).
func hide_boss() -> void:
	_boss = null
	_boss_box.visible = false


## Shows the clear message with the final time.
func show_clear(time_s: float) -> void:
	_clear_shown = true
	_message_label.text = "DUSK SHIFT CLEAR\nTIME  " + format_time(time_s)
	_message_label.visible = true


## True once the clear message is on screen (smoke gate reads it).
func is_clear_shown() -> bool:
	return _clear_shown


## Shows a transient centre-top message.
func toast(text: String, duration_s: float = 2.2) -> void:
	_toast_label.text = text
	_toast_s = duration_s
	_toast_label.visible = true
	_toast_label.modulate.a = 1.0


func _process(delta: float) -> void:
	var udelta: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	if _flash_a > 0.0:
		_flash_a = maxf(0.0, _flash_a - FLASH_DECAY_PER_S * udelta)
		_flash.color.a = _flash_a
	if _pulse_s > 0.0:
		_pulse_s = maxf(0.0, _pulse_s - udelta)
		var s: float = 1.0 + 0.3 * (_pulse_s / PULSE_S)
		_pips.scale = Vector2(s, s)
	elif _pips.scale != Vector2.ONE:
		_pips.scale = Vector2.ONE
	if _toast_s > 0.0:
		_toast_s -= udelta
		if _toast_s <= 0.0:
			_toast_label.visible = false
		elif _toast_s < TOAST_FADE_S:
			_toast_label.modulate.a = _toast_s / TOAST_FADE_S


func _make_label(text: String, size_px: int, pos: Vector2, width: float, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(width, float(size_px) + 10.0)
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	add_child(label)
	return label


func _build_labels() -> void:
	_form_label = _make_label("FORM  VENGEANCE", 27, Vector2(16.0, 10.0), 420.0)
	_chain_label = _make_label("SHIFT CHAIN  x0", 20, Vector2(16.0, 46.0), 300.0)
	_hp_label = _make_label("HP  10", 20, Vector2(16.0, 74.0), 200.0)
	_pips = HBoxContainer.new()
	_pips.position = Vector2(16.0, 106.0)
	_pips.add_theme_constant_override("separation", 4)
	_pips.pivot_offset = Vector2(86.0, 9.0)
	add_child(_pips)
	for i: int in PIP_COUNT:
		var pip: ColorRect = ColorRect.new()
		pip.custom_minimum_size = Vector2(PIP_SIZE, PIP_SIZE)
		pip.color = PIP_EMPTY
		_pips.add_child(pip)
		_pip_rects.append(pip)
	_timer_label = _make_label("TIME  0:00.0", 22, Vector2(VIEW_W - 236.0, 12.0), 220.0, HORIZONTAL_ALIGNMENT_RIGHT)
	_toast_label = _make_label("", 24, Vector2(276.0, 84.0), 600.0, HORIZONTAL_ALIGNMENT_CENTER)
	_toast_label.add_theme_color_override("font_color", Color(0.98, 0.75, 0.3))
	_toast_label.visible = false
	_message_label = _make_label("", 50, Vector2(76.0, 230.0), 1000.0, HORIZONTAL_ALIGNMENT_CENTER)
	_message_label.visible = false
	_boss_box = VBoxContainer.new()
	_boss_box.position = Vector2((VIEW_W - BOSS_BAR_W) * 0.5, VIEW_H - 58.0)
	_boss_box.add_theme_constant_override("separation", 4)
	add_child(_boss_box)
	var boss_name: Label = Label.new()
	boss_name.text = "FRAMING AGENT"
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_font_size_override("font_size", 16)
	boss_name.add_theme_color_override("font_color", Color(0.85, 0.7, 1.0))
	_boss_box.add_child(boss_name)
	var bar_bg: ColorRect = ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(BOSS_BAR_W, 13.0)
	bar_bg.color = Color(0.16, 0.12, 0.2, 0.85)
	_boss_box.add_child(bar_bg)
	_boss_fill = ColorRect.new()
	_boss_fill.custom_minimum_size = Vector2(BOSS_BAR_W, 13.0)
	_boss_fill.color = Color(0.62, 0.35, 0.95)
	bar_bg.add_child(_boss_fill)
	_boss_box.visible = false
