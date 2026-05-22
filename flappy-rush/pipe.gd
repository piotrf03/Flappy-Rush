extends Node2D

const GAP_SIZE = 160.0

func _ready():
	# Losujemy pozycję na osi Y, gdzie ma znajdować się środek szpary
	# (100 to wysoko, 300 to nisko tuż nad ziemią)
	var gap_center = randf_range(100.0, 300.0)
	
	# Przesuwamy górną i dolną część rury w górę i w dół, tworząc przejście
	$TopBody.position.y = gap_center - (GAP_SIZE / 2.0)
	$BottomBody.position.y = gap_center + (GAP_SIZE / 2.0)