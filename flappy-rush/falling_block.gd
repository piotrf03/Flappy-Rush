extends Area2D

var speed := 350.0
var _spin := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_spin = randf_range(-3.0, 3.0)
	# losowy odcień, by bloki nie były identyczne
	rotation = randf_range(0, TAU)

func _process(delta: float) -> void:
	position.y += speed * delta
	rotation += _spin * delta

	# Usuń klocek po minięciu ekranu, by nie zapychał pamięci.
	if position.y > 1500:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		get_tree().call_group("game_manager", "trigger_game_over")
