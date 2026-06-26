extends Node2D
# Chmury w tle z efektem parallaxu (przewijają się wolniej niż gra).
# Węzeł jest w CanvasLayer, więc rysujemy we współrzędnych ekranu i ręcznie
# przesuwamy chmury względem pozycji kamery, zawijając je w nieskończoność.

var cam: Camera2D
var clouds := []
const SPAN := 1800.0
const PARALLAX := 0.25

func _ready() -> void:
	cam = get_node_or_null("../../Camera2D")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260626
	for i in range(16):
		clouds.append({
			"x": rng.randf_range(0.0, SPAN),
			"y": rng.randf_range(30.0, 320.0),
			"s": rng.randf_range(0.6, 1.7),
			"a": rng.randf_range(0.65, 0.95),
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var camx := cam.position.x if cam else 0.0
	for c in clouds:
		var sx: float = fposmod(c.x - camx * PARALLAX, SPAN + 400.0) - 200.0
		_draw_cloud(Vector2(sx, c.y), c.s, c.a)

func _draw_cloud(pos: Vector2, s: float, a: float) -> void:
	var shadow := Color(0.75, 0.82, 0.92, a * 0.8)
	var col := Color(1, 1, 1, a)
	# delikatny cień pod chmurą
	draw_circle(pos + Vector2(0, 10 * s), 26 * s, shadow)
	draw_circle(pos + Vector2(30 * s, 14 * s), 20 * s, shadow)
	# biała bryła chmury
	draw_circle(pos, 27 * s, col)
	draw_circle(pos + Vector2(30 * s, 6 * s), 21 * s, col)
	draw_circle(pos + Vector2(-30 * s, 6 * s), 21 * s, col)
	draw_circle(pos + Vector2(0, -8 * s), 22 * s, col)
