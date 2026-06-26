extends Camera2D

var scroll_speed := 100.0
const SPEED_ACCEL := 2.0
const MAX_SPEED := 600.0

@export var player: RigidBody2D
@export var score_label: Label
@export var hint_label: Label
@export var best_label: Label
@export var game_over_panel: Panel
@export var final_score_label: Label
@export var best_score_label: Label

var pipe_scene := preload("res://pipe.tscn")
var block_scene := preload("res://falling_block.tscn")

var last_pipe_x := 800.0
var score := 0
var best_score := 0
var is_game_over := false
var game_over_timer := 0.0

var active_streams := []
var shake_intensity := 0.0

const SAVE_PATH := "user://highscore.save"

# --- Dźwięk elektryczności strumienia (zapętlony, sterowany odległością) ---
# Gra od chwili pojawienia się bloków na ekranie; głośność rośnie im bliżej kula strumienia.
const ELEC_FALLOFF := 700.0   # dystans, na którym dźwięk cichnie do minimum
const ELEC_MAX_DB := -14.0    # najgłośniej, gdy kula tuż przy strumieniu (i tak cicho)
const ELEC_MIN_DB := -38.0    # najciszej (przy pojawieniu bloków na drugim końcu ekranu)
var _elec: AudioStreamPlayer

func _ready() -> void:
	make_current()
	add_to_group("game_manager")
	best_score = _load_best()
	if best_label:
		best_label.text = "Best: " + str(best_score)

	_elec = AudioStreamPlayer.new()
	_elec.stream = load("res://electricity.wav")
	_elec.volume_db = ELEC_MIN_DB
	add_child(_elec)

func _process(delta: float) -> void:
	# Trzęsienie ekranu
	if shake_intensity > 0:
		offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		shake_intensity = move_toward(shake_intensity, 0.0, delta * 40.0)
	else:
		offset = Vector2.ZERO

	if is_game_over:
		game_over_timer += delta
		if game_over_timer > 0.5 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			get_tree().reload_current_scene()
		return

	update_electricity()

	# Ukryj podpowiedź po pierwszym strzale
	if hint_label and hint_label.visible and player and player.has_launched:
		hint_label.visible = false

	position.x += scroll_speed * delta
	scroll_speed = min(scroll_speed + SPEED_ACCEL * delta, MAX_SPEED)

	spawn_obstacles()
	process_falling_streams(delta)
	check_bounds()
	update_score()
	extend_ground()

func extend_ground() -> void:
	var dirt := get_node("../Ground/Dirt")
	var grass := get_node("../Ground/Grass")
	var grass_edge := get_node_or_null("../Ground/GrassEdge")
	var ground_col := get_node("../Ground/CollisionShape2D")

	var target_x := position.x + 2000.0

	if dirt.size.x < target_x:
		dirt.size.x = target_x
		grass.size.x = target_x
		if grass_edge:
			grass_edge.size.x = target_x
		ground_col.shape.size.x = target_x
		ground_col.position.x = target_x / 2.0

func spawn_obstacles() -> void:
	var screen_right_edge := position.x + (get_viewport_rect().size.x / 2)

	if screen_right_edge + 200 > last_pipe_x:
		var pipe := pipe_scene.instantiate()
		pipe.position.x = last_pipe_x
		get_parent().add_child(pipe)

		if randf() < 0.25:
			active_streams.append({
				"x": last_pipe_x + 200,
				"timer": 0.0,
				"blocks_spawned": 0,
				"is_gap": false,
				"gap_timer": 0.0
			})

		last_pipe_x += 400.0

func process_falling_streams(delta: float) -> void:
	var screen_left_edge := position.x - (get_viewport_rect().size.x / 2)
	var screen_top := position.y - (get_viewport_rect().size.y / 2)

	for i in range(active_streams.size() - 1, -1, -1):
		var stream = active_streams[i]

		if stream.x < screen_left_edge - 100:
			active_streams.remove_at(i)
			continue

		if stream.is_gap:
			stream.gap_timer += delta
			if stream.gap_timer >= 1.0:
				stream.is_gap = false
				stream.gap_timer = 0.0
				stream.blocks_spawned = 0
		else:
			stream.timer += delta
			if stream.timer >= 0.15:
				stream.timer = 0.0
				stream.blocks_spawned += 1

				var block := block_scene.instantiate()
				block.position = Vector2(stream.x, screen_top - 50)
				get_parent().add_child(block)

				if stream.blocks_spawned >= 8:
					stream.is_gap = true

func update_electricity() -> void:
	# Gra zapętlony szum elektryczności od chwili, gdy strumień bloków jest widoczny
	# na ekranie. Głośność rośnie im bliżej kula jest strumienia.
	if not player or not _elec:
		return

	var screen_right_edge := position.x + (get_viewport_rect().size.x / 2)
	var nearest := INF
	var any_visible := false
	for stream in active_streams:
		# Strumień "na ekranie" = jego kolumna wjechała już zza prawej krawędzi.
		if stream.x <= screen_right_edge:
			any_visible = true
			var d: float = abs(player.position.x - stream.x)
			if d < nearest:
				nearest = d

	if any_visible:
		var t: float = clamp(1.0 - (nearest / ELEC_FALLOFF), 0.0, 1.0)   # 1 = przy strumieniu
		_elec.volume_db = lerp(ELEC_MIN_DB, ELEC_MAX_DB, t)
		if not _elec.playing:
			_elec.play()
	elif _elec.playing:
		_elec.stop()

func check_bounds() -> void:
	if not player:
		return

	var screen_size := get_viewport_rect().size
	var left_edge := position.x - (screen_size.x / 2)
	var right_edge := position.x + (screen_size.x / 2)
	var top_edge := position.y - (screen_size.y / 2)
	var bottom_edge := position.y + (screen_size.y / 2)

	var px := player.position.x
	var py := player.position.y

	if px < left_edge - 30 or px > right_edge + 30 or py < top_edge - 30 or py > bottom_edge + 30:
		trigger_game_over()

func update_score() -> void:
	if not player:
		return
	var calculated_score := int((player.position.x - 400.0) / 400.0)
	if calculated_score > score:
		score = calculated_score
		score_label.text = "Score: " + str(score)
		Audio.play("score", randf_range(0.98, 1.05))

func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true

	shake_intensity = 24.0
	Audio.play("gameover")

	if _elec and _elec.playing:
		_elec.stop()

	if score > best_score:
		best_score = score
		_save_best(best_score)

	if player:
		player.set_process_input(false)
		player.die()

	if game_over_panel:
		game_over_panel.visible = true
	if final_score_label:
		final_score_label.text = "Score: " + str(score)
	if best_score_label:
		best_score_label.text = "Best: " + str(best_score)

func _load_best() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return 0
	var v := f.get_32()
	f.close()
	return int(v)

func _save_best(value: int) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_32(value)
	f.close()
