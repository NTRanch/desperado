class_name Hud
extends CanvasLayer
## All UI: title, combat HUD, dialogue, choices, endings.
##
## Contract: text is typeset here by code (Labels) — generated art
## never carries words (art bible law). The game calls the show_*
## methods; the HUD emits signals for player choices and never
## touches game state directly.

signal start_requested(high_noon: bool)
signal dialogue_advanced
signal stance_chosen(form: int)
signal restart_requested

const INK: Color = Color(0.93, 0.88, 0.78)
const PANEL: Color = Color(0.08, 0.07, 0.10, 0.88)
const ACCENT: Color = Color(0.90, 0.66, 0.30)

var _hp_bar: ProgressBar
var _beat_pips: Label
var _form_label: Label
var _chain_label: Label
var _pass_label: Label
var _timer_label: Label
var _cache_label: Label
var _duel_label: Label
var _boss_pips: Label
var _prompt_label: Label
var _dialogue_panel: Panel
var _dialogue_name: Label
var _dialogue_text: Label
var _portrait_rect: TextureRect
var _title_panel: Panel
var _title_sub: Label
var _ending_panel: Panel
var _ending_title: Label
var _ending_text: Label
var _choice_panel: Panel
var _dead_panel: Panel

var dialogue_open: bool = false


func _ready() -> void:
	_build_combat_hud()
	_build_dialogue()
	_build_title()
	_build_ending()
	_build_choice()
	_build_dead()


func _unhandled_input(event: InputEvent) -> void:
	if dialogue_open and event.is_action_pressed("interact"):
		dialogue_advanced.emit()
		get_viewport().set_input_as_handled()


## -- combat HUD -----------------------------------------------------------

func _build_combat_hud() -> void:
	var top: HBoxContainer = HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 14
	top.offset_top = 10
	top.offset_right = -14
	top.add_theme_constant_override("separation", 18)
	add_child(top)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(220, 18)
	_hp_bar.max_value = Player.MAX_HP
	_hp_bar.value = Player.MAX_HP
	_hp_bar.show_percentage = false
	top.add_child(_hp_bar)
	_beat_pips = _label("Beats: ●○○", 17)
	top.add_child(_beat_pips)
	_form_label = _label("Form: Vengeance", 17)
	top.add_child(_form_label)
	_chain_label = _label("Shift chain: 0", 17)
	top.add_child(_chain_label)
	_cache_label = _label("Caches: 0/6", 17)
	top.add_child(_cache_label)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_pass_label = _label("Dusk Shift", 17)
	top.add_child(_pass_label)
	_timer_label = _label("00:00.0", 17)
	top.add_child(_timer_label)
	_duel_label = _label("", 20)
	_duel_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_duel_label.position = Vector2(-260, 44)
	_duel_label.size = Vector2(520, 28)
	_duel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_duel_label)
	_boss_pips = _label("", 16)
	_boss_pips.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_pips.position = Vector2(-260, 74)
	_boss_pips.size = Vector2(520, 24)
	_boss_pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_boss_pips)
	_prompt_label = _label("", 16)
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.position = Vector2(-300, -120)
	_prompt_label.size = Vector2(600, 24)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_prompt_label)


func set_hp(hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp


func set_beats(beats: int) -> void:
	var pips: String = ""
	for i: int in Player.MAX_BEATS:
		pips += "●" if i < beats else "○"
	_beat_pips.text = "Beats: " + pips


func set_form(form: int, chain: int) -> void:
	_form_label.text = "Form: " + Content.FORM_NAMES[form]
	_form_label.add_theme_color_override("font_color", Content.FORM_COLORS[form].lightened(0.25))
	_chain_label.text = "Shift chain: %d" % chain


func set_pass(pass_index: int) -> void:
	_pass_label.text = Content.PASS_NAMES[pass_index]


func set_timer(seconds: float) -> void:
	var mins: int = int(seconds) / 60
	var secs: float = seconds - float(mins * 60)
	_timer_label.text = "%02d:%04.1f" % [mins, secs]


func set_caches(found: int) -> void:
	_cache_label.text = "Caches: %d/6" % found


func set_duel_title(title: String) -> void:
	_duel_label.text = title


func set_boss_phase(phase: int, phases: int) -> void:
	if phases <= 0:
		_boss_pips.text = ""
		return
	var pips: String = "Boss phase: "
	for i: int in phases:
		pips += "◆" if i <= phase else "◇"
	_boss_pips.text = pips


func set_prompt(text: String) -> void:
	_prompt_label.text = text


## -- dialogue ---------------------------------------------------------------

func _build_dialogue() -> void:
	_dialogue_panel = _panel(Vector2(76, 468), Vector2(1000, 150))
	_portrait_rect = TextureRect.new()
	_portrait_rect.position = Vector2(14, 14)
	_portrait_rect.size = Vector2(96, 122)
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_dialogue_panel.add_child(_portrait_rect)
	_dialogue_name = _label("", 18)
	_dialogue_name.position = Vector2(126, 10)
	_dialogue_name.size = Vector2(850, 26)
	_dialogue_panel.add_child(_dialogue_name)
	_dialogue_text = _label("", 19)
	_dialogue_text.position = Vector2(126, 42)
	_dialogue_text.size = Vector2(850, 96)
	_dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_panel.add_child(_dialogue_text)
	_dialogue_panel.visible = false
	add_child(_dialogue_panel)


## Shows one dialogue line; portrait may be null (colour block used).
func show_dialogue(speaker_name: String, text: String, portrait: Texture2D) -> void:
	dialogue_open = true
	_dialogue_panel.visible = true
	_dialogue_name.text = speaker_name
	_dialogue_text.text = text
	_portrait_rect.texture = portrait


func hide_dialogue() -> void:
	dialogue_open = false
	_dialogue_panel.visible = false


## -- title / ending / choice / death ----------------------------------------

func _build_title() -> void:
	_title_panel = _panel(Vector2(276, 130), Vector2(600, 380))
	var title: Label = _label("DESPERADO", 54)
	title.position = Vector2(0, 26)
	title.size = Vector2(600, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	_title_panel.add_child(title)
	_title_sub = _label("One town. One night. One Form.\n\nJ — attack    K / Space — dodge (on the beat: parry)\nL / E — SHIFT form (1 Beat)    1/2/3 — direct form\nF — talk / search / enter    WASD — move\n\nLast-instant dodges earn Beats. Beats morph the gun.\nChoose the desire that fits the moment.\n\nPress F — begin the night", 18)
	_title_sub.position = Vector2(40, 116)
	_title_sub.size = Vector2(520, 240)
	_title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_panel.add_child(_title_sub)
	add_child(_title_panel)


func show_title(high_noon_unlocked: bool) -> void:
	_title_panel.visible = true
	if high_noon_unlocked:
		_title_sub.text = _title_sub.text.replace("Press F — begin the night", "Press F — begin the night\nPress R — High Noon (New Game+)")


func hide_title() -> void:
	_title_panel.visible = false


func _build_ending() -> void:
	_ending_panel = _panel(Vector2(226, 150), Vector2(700, 330))
	_ending_title = _label("", 30)
	_ending_title.position = Vector2(30, 22)
	_ending_title.size = Vector2(640, 44)
	_ending_title.add_theme_color_override("font_color", ACCENT)
	_ending_panel.add_child(_ending_title)
	_ending_text = _label("", 19)
	_ending_text.position = Vector2(30, 80)
	_ending_text.size = Vector2(640, 200)
	_ending_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ending_panel.add_child(_ending_text)
	_ending_panel.visible = false
	add_child(_ending_panel)


func show_ending(title: String, lines: Array, stats: String) -> void:
	_ending_panel.visible = true
	_ending_title.text = title
	var body: String = ""
	for line: String in lines:
		body += line + "\n\n"
	_ending_text.text = body + stats + "\nPress R — title"


func hide_ending() -> void:
	_ending_panel.visible = false


func _build_choice() -> void:
	_choice_panel = _panel(Vector2(326, 220), Vector2(500, 190))
	var head: Label = _label("The shape you stay in:", 20)
	head.position = Vector2(24, 14)
	head.size = Vector2(452, 28)
	_choice_panel.add_child(head)
	var hints: Label = _label("1 — Vengeance      2 — Truth      3 — Freedom", 18)
	hints.position = Vector2(24, 56)
	hints.size = Vector2(452, 26)
	_choice_panel.add_child(hints)
	var release: Label = _label("4 — Release (all caches found)", 18)
	release.position = Vector2(24, 92)
	release.size = Vector2(452, 26)
	_choice_panel.add_child(release)
	_choice_panel.visible = false
	add_child(_choice_panel)


func show_choice(release_available: bool) -> void:
	_choice_panel.visible = true
	_choice_panel.get_child(2).visible = release_available


func hide_choice() -> void:
	_choice_panel.visible = false


func _build_dead() -> void:
	_dead_panel = _panel(Vector2(376, 250), Vector2(400, 130))
	var label: Label = _label("The kata breaks.\nPress R — rise and retry the duel", 19)
	label.position = Vector2(20, 30)
	label.size = Vector2(360, 70)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dead_panel.add_child(label)
	_dead_panel.visible = false
	add_child(_dead_panel)


func show_dead() -> void:
	_dead_panel.visible = true


func hide_dead() -> void:
	_dead_panel.visible = false


## -- helpers ------------------------------------------------------------------

func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	return label


func _panel(pos: Vector2, size: Vector2) -> Panel:
	var panel: Panel = Panel.new()
	panel.position = pos
	panel.size = size
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	return panel
