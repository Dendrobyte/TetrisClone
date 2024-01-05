extends Node

# Game Grid
# This is the primary grid to represent the state of the game
# grid[0][1] is row 0 column 1 | row 0 is the bottom row, col 0 is the left-most column
# 0 -> empty
# 1 -> moving block piece
# 2 -> frozen block piece
var game_grid = []
func pretty_grid_print():
	print("------------ START ------------")
	for i in range(game_grid.size()-1, -1, -1):
		print(game_grid[i])
	print("------------ END ------------")

# Coordinates for our moving block
# It will match the block coordinates matrix, but contain a tuple of global coords where there would be 2s
# TODO: Have the draw block function use these instead
var moving_block_coords = []

# The actual moving block node
@onready var moving_block: Node3D = $MovingBlockController

# Keep track of which block we are moving so we can draw the proper color
var moving_block_type = -1

# TODO: Need to allow blocks to spawn above the grid. Should be fine since player can't move up.
# Weirdly inverted? Row not being X throws me off, but effectively rows are sitting on the Y. We draw top down.
@export var initStartRow:int = 18 # Y | 0 is the bottom row
@export var initStartCol:int = 4 # X | which column /in the above row/ to start at
@export_range (1, 60) var falling_speed:int = 60
var frame_counter: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	init_game_grid()
	spawn_block()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Attempt to move down
	if frame_counter == falling_speed:
		var moved = moving_block_transform(0, -1)
		if moved:
			moving_block.translate(Vector3(0, -1, 0))
		else:
			freeze_moving_block()
		frame_counter = 0
	else:
		frame_counter += 1

func init_game_grid():
	var grid_rows = []
	for i in range(20):
		var row_arr = []
		for j in range(10):
			row_arr.append(0)
		grid_rows.append(row_arr)
	game_grid = grid_rows.duplicate() # Shallow or deep doesn't matter
	pretty_grid_print()

# Iterate over the game grid and draw blocks visually
# Called when a line is cleared and we can assume a fair portion of the grid changes
# (For thht case, we could technically provid some y-value to redraw but imo the performance doesn't matter)
# NOTE: This is where the diff numbers for each block comes in
func draw_game_grid():
	pass

func spawn_block():
	# Generate a block
	var block_num = randi_range(0, BlockCoords.block_count-1)
	moving_block_type = block_num
	var block_matrix = BlockCoords.block_map[block_num]
	
	# Reset the moving block coordinates
	moving_block_coords = []
	
	# Set its position to the start
	var posVertical = initStartRow
	var posHorizontal = initStartCol
	for block_row in block_matrix:
		for block_col in block_row:
			if block_col != 0:
				moving_block_coords.append([posHorizontal, posVertical])
				# TODO: Run this at the end, or elsewhere, to draw all the moving block coords
				draw_moving_block(posHorizontal, posVertical, moving_block_type)
			posHorizontal += 1 # Draw left to right
		posHorizontal = initStartCol
		posVertical -= 1 # Draw top to bottom

# Takes the current moving block coordinates and freeze them to the game grid
# Aka sets those coordinates to 2s
func freeze_moving_block():
	# Update the game grid with 1s and draw a block at that position
	for coord in moving_block_coords:
		game_grid[coord[1]][coord[0]] = 1 # Inverted for the grid!
		# TODO: This draw block function will change to accept all the coords
		draw_frozen_block(coord[0], coord[1], moving_block_type)
		# TODO: Check y levels of block here for line clear
		
	moving_block_coords = []
	for child in $MovingBlockController.get_children():
		child.queue_free()
	$MovingBlockController.reset_position()
	
	spawn_block()

# Child functino to draw a block, doesn't parent to show in scene
func draw_block(horizontal, vertical, block_type):
	var block = load("res://assets/SinglePiece.tscn").instantiate()
	block.position = Vector3(horizontal, vertical, 1)
	# This feels... reflect-y
	# TODO: Sets blocks to all the same color at the moment, perhaps change material type depending?
	#		Need different materials since I'm getting the material and modifying it, not the actual mesh
	block.get_children()[0].get_mesh().surface_get_material(0).albedo_color = BlockCoords.block_colors[block_type]
	return block
	
# Visually draw a block of a certain type at the given coordinates that parents to our moving block controller
func draw_moving_block(horizontal, vertical, block_type):
	var block = draw_block(horizontal, vertical, block_type)
	$MovingBlockController.add_child(block)
	
# Visually draw a block that will never move
func draw_frozen_block(horizontal, vertical, block_type):
	var block = draw_block(horizontal, vertical, block_type)
	$FrozenBlocks.add_child(block)
	
# Given an x and y coordinate, update the coordinates in moving_block_coords by the given X and Y
# Weirdness of the row/col stuff is irrelevant to inputs
func moving_block_transform(changeX, changeY):
	var can_move: bool = true # True unless otherwise noted
	var new_moving_block_coords = moving_block_coords.duplicate(true)
	for coord in new_moving_block_coords:
		coord[0] = coord[0]+changeX
		coord[1] = coord[1]+changeY
		# Check border bounds, doesn't matter what blocks we check
		if (coord[0] < 0 or coord[0] > 9) or coord[1] < 0:
			can_move = false
			return can_move # Early return, one illegal move is all we need
		
		# Check if there are placed blocks around it, can ignore moving block pieces (2s)
		if game_grid[coord[1]][coord[0]] == 1:
			can_move = false
			return can_move
	# TODO: Better way to do this? Like proper temp array stuff?
	moving_block_coords = new_moving_block_coords.duplicate()
	return can_move
