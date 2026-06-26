extends Node
# Globalny menedżer dźwięku (autoload "Audio").
# Wywołuj z dowolnego miejsca: Audio.play("release")

var _pools := {}

const DEFS := {
	"release": "res://sfx/slingshot_release.wav",
	"bounce": "res://sfx/bounce_new.wav",
	"score": "res://sfx/score.mp3",
	"gameover": "res://sfx/gameover.wav",
	"whoosh": "res://sfx/whoosh.wav",
}

# ===== GŁOŚNOŚĆ DŹWIĘKÓW (w decybelach) =====
# Tu zmieniasz głośność każdego dźwięku. 0 = pełna, wartości ujemne = ciszej
# (np. -6 = wyraźnie ciszej, -12 = dużo ciszej). Możesz też dać dodatnie, by podgłośnić.
const VOLUMES := {
	"release": -3.0,    # wystrzał z procy
	"bounce": 0.0,     # odbicie kuli
	"score": 0.0,      # zdobycie punktu
	"gameover": 0.0,   # koniec gry
	"whoosh": -4.0,    # (nieużywany) świst
}

func _ready() -> void:
	# Dla każdego dźwięku tworzymy małą pulę odtwarzaczy, żeby mogły grać równolegle.
	for key in DEFS.keys():
		var stream = load(DEFS[key])
		var pool := []
		for i in range(4):
			var p := AudioStreamPlayer.new()
			p.stream = stream
			add_child(p)
			pool.append(p)
		_pools[key] = pool

func play(sound_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not _pools.has(sound_name):
		return
	# Bazowa głośność z tabeli VOLUMES + ewentualna korekta podana w wywołaniu.
	var vol: float = volume_db + VOLUMES.get(sound_name, 0.0)
	for p in _pools[sound_name]:
		if not p.playing:
			p.pitch_scale = pitch
			p.volume_db = vol
			p.play()
			return
	# Wszystkie zajęte – nadpisujemy pierwszy.
	var first = _pools[sound_name][0]
	first.pitch_scale = pitch
	first.volume_db = vol
	first.play()
