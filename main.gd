extends Node

# Game Grid
# This is the primary grid to represent the state of the game
# 0 -> empty
# 1 -> taken (frozen block)
# 2 -> moving block piece
var game_grid = []

# Called when the node enters the scene tree for the first time.
func _ready():
	init_game_grid()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Listen for the timer ending signal I guess
	pass

func init_game_grid():
	var row_arr = []
	for i in range(10):
		var col_arr = []
		for j in range(20):
			col_arr.append(0)
		row_arr.append(col_arr)
	game_grid = row_arr.duplicate() # Shallow or deep doesn't matter
