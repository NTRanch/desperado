class_name AudioBus
extends Node
## Music + SFX playback from files under res://assets/audio/.
##
## Contract: missing files are a warning, never a crash (the game is
## playable silent). SFX polyphony is bounded by a fixed player pool.
## Verification never hears this bus: headless runs use the Dummy
## audio driver (AUDIO SILENCE RULE binds the builders, not players).

const MUSIC_DIR: String = "res://assets/audio/music/"
const SFX_DIR: String = "res://assets/audio/sfx/"
const MAX_SFX_PLAYERS: int = 8

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0
var _music_cache: Dictionary = {}
var _sfx_cache: Dictionary = {}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)
	for i: int in MAX_SFX_PLAYERS:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		_sfx_players.append(player)


## Loads (and caches) a stream by path; null when absent.
func _load(path: String, cache: Dictionary) -> AudioStream:
	if cache.has(path):
		return cache[path]
	if not ResourceLoader.exists(path):
		push_warning("AudioBus: missing file %s" % path)
		cache[path] = null
		return null
	var stream: AudioStream = load(path)
	cache[path] = stream
	return stream


## Plays a named music track (file stem, e.g. "dusk_theme"), looping.
func play_music(stem: String) -> void:
	var stream: AudioStream = _load(MUSIC_DIR + stem + ".mp3", _music_cache)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	if _music_player.stream != stream:
		_music_player.stream = stream
		_music_player.play()


func stop_music() -> void:
	_music_player.stop()


## Plays a named SFX once (file stem, e.g. "parry_chime").
func play_sfx(stem: String) -> void:
	var stream: AudioStream = _load(SFX_DIR + stem + ".wav", _sfx_cache)
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % MAX_SFX_PLAYERS
	player.stream = stream
	player.play()
