extends RigidBody2D

var is_dragging := false
var drag_start := Vector2.ZERO
const MAX_DRAG := 150.0
const POWER := 6.5
const RADIUS := 16.0

var player_color := Color(1.0, 0.85, 0.25)   # ciepły żółty
var is_dead := false
var has_launched := false
var _bounce_cooldown := 0.0
var _squash := 0.0   # efekt ściśnięcia przy odbiciu

@onready var trail: CPUParticles2D = get_node_or_null("Trail")
@onready var burst: CPUParticles2D = get_node_or_null("Burst")

# Osobny odtwarzacz dla dźwięku napinania procy (żeby móc go zatrzymać przy puszczeniu).
var _draw_player: AudioStreamPlayer
const DRAW_VOLUME_DB := -8.0   # głośność dźwięku napinania procy (0 = pełna, ujemne = ciszej)

func _ready() -> void:
	# Wykrywanie kontaktu, by zagrać dźwięk odbicia.
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

	_draw_player = AudioStreamPlayer.new()
	_draw_player.stream = load("res://sfx/slingshot_draw.wav")
	_draw_player.volume_db = DRAW_VOLUME_DB
	add_child(_draw_player)

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	var is_resting := linear_velocity.length() < 25.0

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and is_resting:
			is_dragging = true
			drag_start = get_global_mouse_position()
			# Dźwięk napinania procy (od początku).
			if _draw_player:
				_draw_player.play()
		elif not event.pressed and is_dragging:
			is_dragging = false
			# Zatrzymaj dźwięk napinania w chwili puszczenia.
			if _draw_player:
				_draw_player.stop()
			var drag_end := get_global_mouse_position()
			var drag_vector := drag_start - drag_end

			if drag_vector.length() > MAX_DRAG:
				drag_vector = drag_vector.normalized() * MAX_DRAG

			# Minimalny próg, żeby przypadkowe stuknięcie nie strzelało.
			if drag_vector.length() > 12.0:
				apply_central_impulse(drag_vector * POWER)
				has_launched = true
				_squash = 1.0
				var power_ratio: float = drag_vector.length() / MAX_DRAG
				Audio.play("release", 0.9 + power_ratio * 0.3)
				if burst:
					burst.restart()

func _physics_process(delta: float) -> void:
	if _bounce_cooldown > 0.0:
		_bounce_cooldown -= delta
	# Ślad cząsteczek tylko gdy kulka realnie leci.
	if trail:
		trail.emitting = (not is_dead) and linear_velocity.length() > 180.0

func _on_body_entered(_body: Node) -> void:
	if is_dead or _bounce_cooldown > 0.0:
		return
	if linear_velocity.length() > 60.0:
		var vol: float = clamp(linear_velocity.length() / 600.0, 0.3, 1.0)
		Audio.play("bounce", randf_range(0.9, 1.1), linear_to_db(vol))
		_squash = 1.0
		_bounce_cooldown = 0.12

func _process(delta: float) -> void:
	if _squash > 0.0:
		_squash = move_toward(_squash, 0.0, delta * 4.0)
	queue_redraw()

func _draw() -> void:
	# --- Efekt squash & stretch ---
	var sx := 1.0 + _squash * 0.25
	var sy := 1.0 - _squash * 0.25

	# 1. Miękki cień pod kulką
	draw_circle(Vector2(0, RADIUS * 0.9), RADIUS * 0.95, Color(0, 0, 0, 0.18))

	# 2. Obrys
	draw_circle(Vector2.ZERO, RADIUS + 2.0, Color(0.15, 0.12, 0.05, 1.0))

	# 3. Ciało (z lekkim spłaszczeniem)
	var body_outer := player_color.darkened(0.15)
	_draw_squashed_circle(Vector2.ZERO, RADIUS, sx, sy, body_outer)
	_draw_squashed_circle(Vector2.ZERO, RADIUS - 2.0, sx, sy, player_color)

	# 4. Refleks świetlny
	draw_circle(Vector2(-RADIUS * 0.35, -RADIUS * 0.4), RADIUS * 0.28, Color(1, 1, 1, 0.55))

	# 5. Oczy (patrzą w kierunku lotu) – tylko gdy żywa
	if not is_dead:
		var look := Vector2.ZERO
		if linear_velocity.length() > 10.0:
			look = linear_velocity.normalized() * 2.0
		_draw_eye(Vector2(5, -4), look)
		_draw_eye(Vector2(-5, -4), look)
	else:
		# X-oczy po śmierci
		_draw_dead_eye(Vector2(6, -4))
		_draw_dead_eye(Vector2(-6, -4))

	# 6. Linia procy + przewidywana trajektoria
	if is_dragging:
		_draw_aim()

func _draw_squashed_circle(center: Vector2, r: float, sx: float, sy: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var seg := 24
	for i in range(seg):
		var a := TAU * float(i) / float(seg)
		pts.append(center + Vector2(cos(a) * r * sx, sin(a) * r * sy))
	draw_colored_polygon(pts, col)

func _draw_eye(offset: Vector2, look: Vector2) -> void:
	draw_circle(offset, 4.5, Color.WHITE)
	draw_circle(offset + look, 2.3, Color(0.1, 0.1, 0.15))

func _draw_dead_eye(offset: Vector2) -> void:
	var c := Color(0.1, 0.1, 0.1)
	draw_line(offset + Vector2(-3, -3), offset + Vector2(3, 3), c, 1.5)
	draw_line(offset + Vector2(3, -3), offset + Vector2(-3, 3), c, 1.5)

func _draw_aim() -> void:
	var local_start := to_local(drag_start)
	var local_mouse := get_local_mouse_position()
	var drag_vector := local_start - local_mouse
	if drag_vector.length() > MAX_DRAG:
		drag_vector = drag_vector.normalized() * MAX_DRAG

	# Linia napięcia procy
	draw_line(Vector2.ZERO, drag_vector, Color(1, 0.3, 0.3, 0.9), 4.0)

	# Kropki przewidywanej trajektorii.
	# Symulujemy tę samą fizykę co silnik (grawitacja + tłumienie, krok po kroku),
	# żeby kropki pokrywały się z faktycznym lotem kuli. Sam wzór rzutu ukośnego
	# byłby błędny, bo kula ma linear_damp (wyhamowuje w locie).
	var step := 1.0 / float(Engine.physics_ticks_per_second)
	var grav := Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)) * gravity_scale
	var total_damp := linear_damp
	if linear_damp_mode == RigidBody2D.DAMP_MODE_COMBINE:
		total_damp += ProjectSettings.get_setting("physics/2d/default_linear_damp", 0.1)

	var vel := drag_vector * POWER   # masa = 1, kulka w spoczynku
	var pos := Vector2.ZERO
	var col := Color(1, 1, 1)
	var steps := 120
	var dot_every := 6
	for i in range(1, steps):
		vel += grav * step
		vel *= maxf(0.0, 1.0 - total_damp * step)
		pos += vel * step
		if i % dot_every == 0:
			var fade := 1.0 - float(i) / float(steps)
			draw_circle(pos, 4.0 * fade, Color(col.r, col.g, col.b, 0.7 * fade))

func die() -> void:
	if is_dead:
		return
	is_dead = true
	is_dragging = false
	collision_layer = 0
	collision_mask = 0
	player_color = Color(0.45, 0.45, 0.5)

	if trail:
		trail.emitting = false
	if burst:
		burst.color = Color(0.9, 0.2, 0.2)
		burst.restart()

	lock_rotation = false
	linear_velocity = Vector2(0, -420)
	angular_velocity = 18.0
