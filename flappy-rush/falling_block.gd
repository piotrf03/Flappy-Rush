extends Area2D

var speed = 350.0

func _ready():
	# Podłączamy sygnał na wypadek fizycznego wejścia obiektu w pole kolizji klocka
	body_entered.connect(_on_body_entered)

func _process(delta):
	position.y += speed * delta
	
	# Jeśli klocek spadnie bardzo nisko i minie ziemię, usuń go by nie zapychał pamięci
	if position.y > 1500:
		queue_free()

func _on_body_entered(body):
	# Sprawdzamy czy to, co uderzyło w klocek to gracz
	if body.name == "Player":
		# Klocki dzwonią do centralnego menedżera (czyli naszej kamery), zgłaszając zgon
		get_tree().call_group("game_manager", "trigger_game_over")