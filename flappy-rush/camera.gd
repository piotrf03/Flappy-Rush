extends Camera2D

var scroll_speed = 100.0
@export var player: RigidBody2D

@export var score_label: Label
@export var game_over_panel: Panel
@export var final_score_label: Label

var pipe_scene = preload("res://pipe.tscn")
var block_scene = preload("res://falling_block.tscn")

var last_pipe_x = 800.0
var score = 0
var is_game_over = false
var game_over_timer = 0.0

var active_streams = []
var shake_intensity = 0.0 

func _ready():
	make_current()
	add_to_group("game_manager")

func _process(delta):
	# Obsługa trzęsienia się ekranu
	if shake_intensity > 0:
		offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		shake_intensity = move_toward(shake_intensity, 0.0, delta * 40.0)
	else:
		offset = Vector2.ZERO
		
	if is_game_over:
		game_over_timer += delta
		if game_over_timer > 0.5:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				get_tree().reload_current_scene()
		return
		
	position.x += scroll_speed * delta
	scroll_speed += 2.0 * delta 
	
	spawn_obstacles()
	process_falling_streams(delta)
	check_bounds()
	update_score()
	extend_ground() 

func extend_ground():
	var dirt = get_node("../Ground/Dirt")
	var grass = get_node("../Ground/Grass")
	var ground_col = get_node("../Ground/CollisionShape2D")
	
	var target_x = position.x + 2000.0
	
	if dirt.size.x < target_x:
		dirt.size.x = target_x
		grass.size.x = target_x
		ground_col.shape.size.x = target_x
		ground_col.position.x = target_x / 2.0

func spawn_obstacles():
	var screen_right_edge = position.x + (get_viewport_rect().size.x / 2)
	
	if screen_right_edge + 200 > last_pipe_x:
		var pipe = pipe_scene.instantiate()
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

func process_falling_streams(delta):
	var screen_left_edge = position.x - (get_viewport_rect().size.x / 2)
	var screen_top = position.y - (get_viewport_rect().size.y / 2)
	
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
				
				var block = block_scene.instantiate()
				block.position = Vector2(stream.x, screen_top - 50)
				get_parent().add_child(block)
				
				if stream.blocks_spawned >= 8:
					stream.is_gap = true

func check_bounds():
	if not player: return
	
	var screen_size = get_viewport_rect().size
	var left_edge = position.x - (screen_size.x / 2)
	var right_edge = position.x + (screen_size.x / 2)
	var top_edge = position.y - (screen_size.y / 2)
	var bottom_edge = position.y + (screen_size.y / 2)
	
	var px = player.position.x
	var py = player.position.y
	
	if px < left_edge - 30 or px > right_edge + 30 or py < top_edge - 30 or py > bottom_edge + 30:
		trigger_game_over()

# --- TUTAJ JEST BRAKUJĄCA FUNKCJA ---
func update_score():
	if not player: return
	var calculated_score = int((player.position.x - 400.0) / 400.0)
	if calculated_score > score:
		score = calculated_score
		score_label.text = "Score: " + str(score)

func trigger_game_over():
	if is_game_over: return
	is_game_over = true
	
	shake_intensity = 20.0
	
	if player:
		player.set_process_input(false)
		player.die() 
	
	if game_over_panel:
		game_over_panel.visible = true
	if final_score_label:
		final_score_label.text = "Final Score: " + str(score)
