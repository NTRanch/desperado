extends Node2D
## Desperado — game orchestration.
##
## Owns the night's state machine: TITLE -> EXPLORE <-> DIALOGUE ->
## DUEL -> ... -> CHOICE -> ENDING, the three town Shifts (passes),
## duel sequencing, caches, the workshop flashbacks, and the timer.
## Combat maths live in player.gd / duelist.gd; text lives in
## content.gd; this file only sequences them.

const STATE_TITLE: int = 0
const STATE_EXPLORE: int = 1
const STATE_DIALOGUE: int = 2
const STATE_DUEL: int = 3
const STATE_CHOICE: int = 4
const STATE_ENDING: int = 5
const STATE_DEAD: int = 6

const ARENA: Rect2 = Rect2(240, 312, 760, 296)
const GAP_ZONE: Rect2 = Rect2(998, 556, 48, 68)
const DUEL_SPOTS: Array[Vector2] = [
	Vector2(800, 430), Vector2(620, 430), Vector2(760, 410), Vector2(950, 400),
]
const MAX_PROJECTILES: int = 64

var state: int = STATE_TITLE
var stage: int = 0
var pass_index: int = 0
var high_noon: bool = false

var _town: Town
var _player: Player
var _duelists: Array[Duelist] = []
var _current_duelist: Duelist
var _current_duel_idx: int = -1
var _hud: Hud
var _fx: ShiftFx
var _audio: AudioBus
var _modulate: CanvasModulate
var _portraits: Dictionary = {}

var _dialogue_lines: Array = []
var _dialogue_idx: int = 0
var _dialogue_after: String = ""
var _timer_s: float = 0.0
var _timer_running: bool = false
var _shift_chain: int = 0
var _last_hp: int = Player.MAX_HP
var _caches_found: int = 0
var _in_workshop: bool = false
var _flashbacks_seen: Array[bool] = [false, false, false]
var _testimony_seen: Array[bool] = [false, false]
var _ending_id: String = ""
var _projectile_count: int = 0


func _ready() -> void:
	_modulate = CanvasModulate.new()
	add_child(_modulate)
	_town = Town.new()
	add_child(_town)
	_load_portraits()
	var plate: Texture2D = _load_texture("res://assets/plates/town_dusk.png")
	_town.build(plate)
	_fx = ShiftFx.new()
	add_child(_fx)
	_audio = AudioBus.new()
	add_child(_audio)
	_player = Player.new()
	_player.game = self
	_player.position = Vector2(180, 470)
	add_child(_player)
	_player.health_changed.connect(_on_player_health)
	_player.beat_gained.connect(func(_b: int) -> void: _hud.set_beats(_player.beats))
	_player.form_changed.connect(func(_f: int) -> void: _hud.set_form(_player.form, _shift_chain))
	_player.died.connect(_on_player_died)
	for i: int in Content.DUELS.size():
		var d: Duelist = Duelist.new()
		d.game = self
		d.position = DUEL_SPOTS[i]
		add_child(d)
		_duelists.append(d)
	_duelists[0].preview("enforcer")
	_duelists[1].visible = false  # the witness duels as herself in pass 2
	_duelists[2].visible = false  # the captain arrives at midnight
	_duelists[3].visible = false  # the agent waits for dawn
	_hud = Hud.new()
	add_child(_hud)
	_hud.start_requested.connect(_on_start_requested)
	_hud.dialogue_advanced.connect(_advance_dialogue)
	_hud.restart_requested.connect(_on_restart_requested)
	_apply_pass_visuals()
	_hud.set_beats(_player.beats)
	_hud.set_form(_player.form, 0)
	_hud.set_caches(0)
	_hud.show_title(_load_unlock())


func _process(delta: float) -> void:
	if _timer_running:
		_timer_s += delta
		_hud.set_timer(_timer_s)
	if state == STATE_TITLE:
		if Input.is_action_just_pressed("interact"):
			_on_start_requested(false)
		elif Input.is_action_just_pressed("confirm") and _load_unlock():
			_on_start_requested(true)
	elif state == STATE_DEAD or state == STATE_ENDING:
		if Input.is_action_just_pressed("confirm"):
			_on_restart_requested()
	elif state == STATE_CHOICE:
		_read_choice()
	elif state == STATE_EXPLORE:
		_explore_interactions()


func _physics_process(_delta: float) -> void:
	if state == STATE_DUEL:
		_player.global_position = _player.global_position.clamp(ARENA.position, ARENA.end)
		if _current_duelist != null:
			_current_duelist.global_position = _current_duelist.global_position.clamp(ARENA.position, ARENA.end)
	_enforce_gap()


# -- run flow -----------------------------------------------------------------

func _on_start_requested(hn: bool) -> void:
	start_run(hn)


## Begins a run. Public: the selftest drives this too.
func start_run(hn: bool) -> void:
	high_noon = hn
	_hud.hide_title()
	_hud.hide_ending()
	stage = 0
	pass_index = 0
	_timer_s = 0.0
	_timer_running = true
	_caches_found = 0
	_hud.set_caches(0)
	_player.heal_full()
	_player.position = Vector2(180, 470)
	_apply_pass_visuals()
	_play_dialogue("intro", "explore")


func _on_restart_requested() -> void:
	if state == STATE_DEAD:
		_hud.hide_dead()
		_player.heal_full()
		_player.position = Vector2(420, 460)
		_begin_duel(_current_duel_idx)
	elif state == STATE_ENDING:
		state = STATE_TITLE
		_hud.hide_ending()
		_hud.show_title(_load_unlock())


func _on_player_died() -> void:
	if state != STATE_DUEL:
		return
	state = STATE_DEAD
	_player.input_enabled = false
	if _current_duelist != null:
		_current_duelist.disarm()
	_hud.show_dead()
	play_sfx("player_down")


# -- dialogue -------------------------------------------------------------------

func _play_dialogue(key: String, after: String) -> void:
	_dialogue_lines = Content.dialogue(key)
	_dialogue_idx = 0
	_dialogue_after = after
	if _dialogue_lines.is_empty():
		_on_dialogue_finished()
		return
	state = STATE_DIALOGUE
	_player.input_enabled = false
	_show_dialogue_line()


func _show_dialogue_line() -> void:
	var line: Array = _dialogue_lines[_dialogue_idx]
	var speaker: String = String(line[0])
	var character: Dictionary = Content.CHARACTERS[speaker]
	_hud.show_dialogue(String(character["name"]), String(line[1]), _portraits.get(speaker))


func _advance_dialogue() -> void:
	if state != STATE_DIALOGUE:
		return
	play_sfx("ui_click")
	_dialogue_idx += 1
	if _dialogue_idx >= _dialogue_lines.size():
		_hud.hide_dialogue()
		_on_dialogue_finished()
	else:
		_show_dialogue_line()


func _on_dialogue_finished() -> void:
	match _dialogue_after:
		"explore":
			state = STATE_EXPLORE
			_player.input_enabled = true
		"duel0":
			_begin_duel(0)
		"duel1":
			_begin_duel(1)
		"duel2":
			_begin_duel(2)
		"duel3":
			_begin_duel(3)
		"midnight":
			_advance_pass(1)
			state = STATE_EXPLORE
			_player.input_enabled = true
		"dawn":
			_advance_pass(2)
			state = STATE_EXPLORE
			_player.input_enabled = true
		"choice":
			state = STATE_CHOICE
			_hud.show_choice(_caches_found >= Content.CACHE_IDS.size())
		"ending":
			_show_ending()
		_:
			state = STATE_EXPLORE
			_player.input_enabled = true


# -- exploration ------------------------------------------------------------------

func _explore_interactions() -> void:
	_hud.set_prompt(_explore_prompt())
	if Input.is_action_just_pressed("interact"):
		_do_interact()


## The interact action, extracted so the scripted playthrough can
## drive the identical code path the F key drives.
func _do_interact() -> void:
	var pos: Vector2 = _player.global_position
	if _in_workshop:
		if pos.distance_to(_town.interior_exit()) < 46.0:
			_leave_workshop()
			return
		if not _flashbacks_seen[pass_index]:
			_flashbacks_seen[pass_index] = true
			_town.set_memory_visible(true)
			_play_dialogue("flashback_%d" % (pass_index + 1), "explore_workshop")
			return
		return
	if pos.distance_to(_town.workshop_door()) < 46.0:
		_enter_workshop()
		return
	# Caches: Truth reveals; interact collects.
	var cache_id: String = _town.nearest_cache(pos, 44.0)
	if cache_id != "" and _player.form == Content.FORM_TRUTH:
		if _town.collect_cache(cache_id):
			_caches_found += 1
			_hud.set_caches(_caches_found)
			play_sfx("cache_chime")
			_play_dialogue("cache_found", "explore")
		return
	# People / duel triggers.
	if stage == 0:
		if pos.distance_to(_town.witness_figure.position) < 56.0 and not _testimony_seen[0]:
			_testimony_seen[0] = true
			_play_dialogue("testimony_1", "explore")
			return
		if pos.distance_to(DUEL_SPOTS[0]) < 90.0:
			_play_dialogue("pre_enforcer", "duel0")
			return
	elif stage == 1:
		if pos.distance_to(_town.witness_figure.position) < 56.0 and not _testimony_seen[1]:
			_testimony_seen[1] = true
			_play_dialogue("testimony_2", "duel1")
			return
	elif stage == 2:
		if pos.distance_to(DUEL_SPOTS[2]) < 90.0:
			_play_dialogue("pre_captain", "duel2")
			return
	elif stage == 3:
		if pos.distance_to(DUEL_SPOTS[3]) < 100.0:
			_play_dialogue("pre_agent", "duel3")
			return


func _explore_prompt() -> String:
	if state != STATE_EXPLORE:
		return ""
	var pos: Vector2 = _player.global_position
	if _in_workshop:
		if not _flashbacks_seen[pass_index]:
			return "F — remember"
		if pos.distance_to(_town.interior_exit()) < 46.0:
			return "F — leave the workshop"
		return ""
	if pos.distance_to(_town.workshop_door()) < 46.0:
		return "F — enter the workshop"
	var cache_id: String = _town.nearest_cache(pos, 44.0)
	if cache_id != "":
		if _player.form == Content.FORM_TRUTH:
			return "F — open the Deseo cache"
		return String(Content.CACHE_HINTS[cache_id])
	if stage == 0 and pos.distance_to(DUEL_SPOTS[0]) < 90.0:
		return "F — face the Enforcer"
	if stage == 2 and pos.distance_to(DUEL_SPOTS[2]) < 90.0:
		return "F — face the Captain"
	if stage == 3 and pos.distance_to(DUEL_SPOTS[3]) < 100.0:
		return "F — face Agent Sable"
	return ""


func _enter_workshop() -> void:
	_in_workshop = true
	_player.global_position = _town.interior_spawn()
	play_sfx("door_open")


func _leave_workshop() -> void:
	_in_workshop = false
	_town.set_memory_visible(false)
	_player.global_position = _town.workshop_exit()
	play_sfx("door_open")


func _enforce_gap() -> void:
	if _in_workshop or state == STATE_DUEL:
		return
	var pos: Vector2 = _player.global_position
	if not GAP_ZONE.has_point(pos):
		return
	if _player.form == Content.FORM_FREEDOM and _player.is_dodging():
		return
	# The broken footbridge: only a Freedom dash crosses. Push back
	# to the side the player came from.
	if pos.x < GAP_ZONE.get_center().x:
		_player.global_position.x = GAP_ZONE.position.x - 14.0
	else:
		_player.global_position.x = GAP_ZONE.end.x + 14.0


# -- duels -------------------------------------------------------------------------

## Arms duel idx and enters STATE_DUEL. Public for the selftest.
func _begin_duel(idx: int) -> void:
	_current_duel_idx = idx
	var duelist: Duelist = _duelists[idx]
	_current_duelist = duelist
	duelist.visible = true
	if idx == 1:
		_town.witness_figure.visible = false
		duelist.position = _town.witness_figure.position
	var def: Dictionary = Content.duel_def(idx).duplicate()
	if high_noon:
		def["hp"] = int(round(float(def["hp"]) * 1.35))
		def["melee_damage"] = int(round(float(def["melee_damage"]) * 1.3))
		def["ranged_damage"] = int(round(float(def["ranged_damage"]) * 1.3))
	if not duelist.defeated.is_connected(_on_duel_won):
		duelist.defeated.connect(_on_duel_won)
		duelist.surrendered.connect(_on_duel_won)
		duelist.attack_whiffed.connect(_on_attack_whiffed)
	duelist.arm(def, String(Content.DUELS[idx]["id"]), _player)
	_player.global_position = _player.global_position.clamp(ARENA.position, ARENA.end)
	_player.input_enabled = true
	state = STATE_DUEL
	_shift_chain = 0
	_hud.set_duel_title(String(def["title"]))
	_hud.set_boss_phase(0, 3 if def.has("phases") else 0)
	_audio.play_music("boss_theme" if idx == 3 else "duel_theme")
	play_sfx("duel_start")


func _on_duel_won(_duelist: Duelist) -> void:
	if state != STATE_DUEL:
		return
	_player.input_enabled = false
	_hud.set_duel_title("")
	_hud.set_boss_phase(0, 0)
	play_sfx("duel_won")
	match _current_duel_idx:
		0:
			stage = 1
			_play_dialogue("post_enforcer", "midnight")
		1:
			stage = 2
			_duelists[1].visible = false
			_town.witness_figure.visible = true
			_duelists[2].visible = true
			_duelists[2].preview("captain")
			_play_dialogue("post_witness", "explore")
		2:
			stage = 3
			_duelists[3].visible = true
			_duelists[3].preview("agent")
			_play_dialogue("post_captain", "dawn")
		3:
			stage = 4
			_play_dialogue("post_agent", "choice")


func _on_attack_whiffed(_duelist: Duelist) -> void:
	# A last-instant dodge: the strike passed through empty air
	# while the player was mid-dodge (checked in duelist._strike).
	_player.gain_beat()
	play_sfx("parry_chime")


## The player parried (player.melee_hit routes here).
func on_parry() -> void:
	play_sfx("parry_chime")
	if _current_duelist != null and state == STATE_DUEL:
		_current_duelist.apply_parry_stagger()
	_hitstop()


func _hitstop() -> void:
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.085, true, false, true).timeout
	Engine.time_scale = 1.0


## Player shifted form (player callback): FX + chain bookkeeping.
func on_player_shift(pos: Vector2, silhouette: PackedVector2Array, facing: Vector2) -> void:
	_fx.snap(pos + Vector2(0, -8), silhouette, Content.FORM_COLORS[_player.form], facing.angle())
	if state == STATE_DUEL:
		_shift_chain += 1
		_hud.set_form(_player.form, _shift_chain)


## Boss phase changed (duelist callback): snap + HUD + sting.
func on_boss_phase(phase: int, pos: Vector2, silhouette: PackedVector2Array, facing: Vector2) -> void:
	_fx.snap(pos + Vector2(0, -8), silhouette, Color(0.95, 0.85, 0.55), facing.angle())
	_hud.set_boss_phase(phase, 3)
	play_sfx("phase_shift")


func _on_player_health(hp: int, _max_hp: int) -> void:
	_hud.set_hp(hp, Player.MAX_HP)
	if hp < _last_hp and state == STATE_DUEL:
		_shift_chain = 0
		_hud.set_form(_player.form, 0)
	_last_hp = hp


## Player melee resolution (player callback).
func player_melee(centre: Vector2, range_px: float, damage: int, form: int) -> void:
	if state != STATE_DUEL or _current_duelist == null:
		return
	if _current_duelist.global_position.distance_to(centre) <= range_px + 20.0:
		_current_duelist.take_hit(damage, form)


# -- passes / endings -----------------------------------------------------------------

func _advance_pass(idx: int) -> void:
	pass_index = idx
	_player.heal_full()
	_apply_pass_visuals()
	_fx.snap(_player.global_position, _player.figure.silhouette(), Color(0.95, 0.85, 0.55), 0.0)
	play_sfx("phase_shift")


func _apply_pass_visuals() -> void:
	_town.set_pass(pass_index)
	var plate_names: Array[String] = ["town_dusk", "town_midnight", "town_dawn"]
	_town.set_plate(_load_texture("res://assets/plates/%s.png" % plate_names[pass_index]))
	_modulate.color = Content.PASS_MODULATE[pass_index]
	_hud.set_pass(pass_index)
	var stems: Array[String] = ["dusk_theme", "midnight_theme", "dawn_theme"]
	if state != STATE_DUEL:
		_audio.play_music(stems[pass_index])


func _read_choice() -> void:
	var release_ok: bool = _caches_found >= Content.CACHE_IDS.size()
	if Input.is_action_just_pressed("form_1"):
		_finish_with_ending("revenge")
	elif Input.is_action_just_pressed("form_2"):
		_finish_with_ending("truth")
	elif Input.is_action_just_pressed("form_3"):
		_finish_with_ending("freedom")
	elif release_ok and Input.is_key_pressed(KEY_4):
		_finish_with_ending("release")


func _finish_with_ending(ending_id: String) -> void:
	_ending_id = ending_id
	_hud.hide_choice()
	state = STATE_ENDING
	_timer_running = false
	_save_unlock()
	_show_ending()


func _show_ending() -> void:
	var ending: Dictionary = Content.ENDINGS[_ending_id]
	var mins: int = int(_timer_s) / 60
	var secs: float = _timer_s - float(mins * 60)
	var stats: String = "Night cleared in %02d:%04.1f — caches %d/6 — %s" % [
		mins, secs, _caches_found, "High Noon" if high_noon else "first clear",
	]
	_hud.show_ending(String(ending["title"]), ending["lines"], stats)
	_audio.play_music("dawn_theme")


# -- shared services ---------------------------------------------------------------------

## Spawns a projectile for either combatant (bounded pool).
func spawn_projectile(origin: Vector2, dir: Vector2, speed: float, damage: int, from_player: bool, tint: Color, pierce: bool) -> void:
	if _projectile_count >= MAX_PROJECTILES:
		return
	var proj: Projectile = Projectile.new()
	proj.tree_exited.connect(func() -> void: _projectile_count -= 1)
	add_child(proj)
	_projectile_count += 1
	proj.fire(origin, dir, speed, damage, from_player, tint, pierce)
	proj.form = _player.form if from_player else -1


## SFX by stem (audio bus warns, never crashes, when absent).
func play_sfx(stem: String) -> void:
	_audio.play_sfx(stem)


# -- persistence ---------------------------------------------------------------------------

func _save_unlock() -> void:
	var file: FileAccess = FileAccess.open("user://desperado_save.json", FileAccess.WRITE)
	if file == null:
		return
	var best: float = _timer_s
	var existing: Dictionary = _load_save()
	if existing.has("best_time_s") and float(existing["best_time_s"]) > 0.0:
		best = minf(best, float(existing["best_time_s"]))
	file.store_string(JSON.stringify({"high_noon_unlocked": true, "best_time_s": best}))


func _load_save() -> Dictionary:
	if not FileAccess.file_exists("user://desperado_save.json"):
		return {}
	var file: FileAccess = FileAccess.open("user://desperado_save.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _load_unlock() -> bool:
	return bool(_load_save().get("high_noon_unlocked", false))


# -- loading helpers --------------------------------------------------------------------------

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _load_portraits() -> void:
	for char_id: String in Content.CHARACTERS:
		var tex: Texture2D = _load_texture("res://assets/portraits/%s.png" % char_id)
		if tex != null:
			_portraits[char_id] = tex
