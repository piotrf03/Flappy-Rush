extends RigidBody2D

var is_dragging = false
var drag_start = Vector2.ZERO
const MAX_DRAG = 150.0
const POWER = 6.5

# Zmienna przechowująca kolor postaci (domyślnie jasnoszary/biały)
var player_color = Color(0.9, 0.9, 0.9)

func _input(event):
	var is_resting = linear_velocity.length() < 15.0
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and is_resting:
			is_dragging = true
			drag_start = get_global_mouse_position()
		elif not event.pressed and is_dragging:
			is_dragging = false
			var drag_end = get_global_mouse_position()
			var drag_vector = drag_start - drag_end
			
			if drag_vector.length() > MAX_DRAG:
				drag_vector = drag_vector.normalized() * MAX_DRAG
				
			apply_central_impulse(drag_vector * POWER)

func _process(_delta):
	queue_redraw()

func _draw():
	# 1. Rysowanie samej postaci 
	# (0,0) to środek obiektu, 16.0 to promień - idealnie pasujący do naszego CollisionShape2D
	draw_circle(Vector2.ZERO, 16.0, player_color)
	
	# 2. Rysowanie linii procy (celownika)
	if is_dragging:
		var local_start = to_local(drag_start)
		var local_mouse = get_local_mouse_position()
		var drag_vector = local_start - local_mouse
		
		if drag_vector.length() > MAX_DRAG:
			drag_vector = drag_vector.normalized() * MAX_DRAG
			
		draw_line(Vector2.ZERO, drag_vector, Color.RED, 4.0)

func die():
	is_dragging = false
	collision_layer = 0
	collision_mask = 0
	
	# Zamiast odnosić się do Sprite2D, po prostu zmieniamy naszą zmienną koloru na ciemną
	player_color = Color(0.2, 0.2, 0.2)
	
	lock_rotation = false
	linear_velocity = Vector2(0, -400) 
	angular_velocity = 20.0