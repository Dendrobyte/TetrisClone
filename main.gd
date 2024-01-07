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
	for i in range(game_grid.size() - 1, -1, -1):
		print(game_grid[i])
	print("------------ END ------------")


# The actual moving block node
@onready var moving_block: Node3D = $MovingBlockController

# Save offset from start each movement for drawing, freezing. Makes rotation possible (I hope?)
var offset_from_start = [0, 0]
# Keep track of which block we are moving so we can draw the proper color
var moving_block_type = -1
# Track rotation so we can apply n rotations depending
var moving_block_rotation = -1  # 0 up, 1 right, 2 down, 3 left
# Hold on to the matix so maybe I don't have to rotate multiple times?
var moving_block_matrix = []

# TODO: Need to allow blocks to spawn above the grid. Should be fine since player can't move up. Extend infinitely?
# Weirdly inverted? Row not being X throws me off, but effectively rows are sitting on the Y. We draw top down.
@export var initStartRow: int = 18  # Y | 0 is the bottom row
@export var initStartCol: int = 4  # X | which column /in the above row/ to start at
@export_range(1, 60) var falling_speed: int = 60
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
		# while testing rotation I don't want to have to worry about this
		# frame_counter += 1
		pass


func init_game_grid():
	var grid_rows = []
	for i in range(20):
		var row_arr = []
		for j in range(10):
			row_arr.append(0)
		grid_rows.append(row_arr)
	game_grid = grid_rows.duplicate()  # Shallow or deep doesn't matter
	pretty_grid_print()


# Iterate over the game grid and draw blocks visually
# Called when a line is cleared and we can assume a fair portion of the grid changes
# (For thht case, we could technically provid some y-value to redraw but imo the performance doesn't matter)
# NOTE: This is where the diff numbers for each block comes in
func draw_game_grid():
	pass


func spawn_block():
	# Generate a block
	var block_num = randi_range(0, BlockCoords.block_count - 1)
	moving_block_type = block_num
	moving_block_rotation = 0  # Start up
	offset_from_start = [0, 0]
	moving_block_matrix = BlockCoords.block_map[block_num]

	# Reset the blocks offset from start
	offset_from_start = [0, 0]

	# Draw block!
	draw_moving_block()


# Takes the current moving block coordinates and freeze them to the game grid (coords to 1s)
func freeze_moving_block():
	# Update the game grid with 1s and draw a block at that position
	for row_i in range(moving_block_matrix.size()):
		for col_j in range(moving_block_matrix[row_i].size()):
			if moving_block_matrix[row_i][col_j] != 0:
				var x = initStartCol - offset_from_start[1]
				var y = initStartRow - offset_from_start[0]
				draw_single_frozen_block(x, y)
				game_grid[x][y] = 1  # Inverted for the grid!

	# TODO: Check for line clearing here, now that game_grid is updated
	# Since game grid is updated, check for clearable lines

	# Clear children of moving block controller
	for child in $MovingBlockController.get_children():
		child.queue_free()
	$MovingBlockController.reset_position()

	spawn_block()


# Visually draw a block given its current matrix (rotated) combined with offset from start
func draw_moving_block():
	for row_i in range(moving_block_matrix.size()):
		for col_j in range(moving_block_matrix[row_i].size()):
			print("moving block matrix: ", moving_block_matrix)
			if moving_block_matrix[row_i][col_j] != 0:
				var global_x_changes = initStartCol - offset_from_start[1]
				var global_y_changes = initStartRow - offset_from_start[0]
				print(
					"moving block positions: ",
					row_i + global_x_changes,
					" - ",
					col_j + global_y_changes
				)
				var block = draw_block(row_i + global_x_changes, col_j + global_y_changes)
				$MovingBlockController.add_child(block)


# Child function to draw a block, doesn't parent to show in scene
func draw_block(global_x, global_y):
	var block = load("res://assets/SinglePiece.tscn").instantiate()
	block.position = Vector3(global_x, global_y, 1)
	# This feels... reflect-y
	block.get_children()[0].mesh = load(
		"res://assets/BlockPieces/SinglePiece-%s.obj" % str(moving_block_type)
	)
	return block


# Visually draw a block that will never move
func draw_single_frozen_block(x, y):
	var block = draw_block(x + offset_from_start[0], y + offset_from_start[1])
	$FrozenBlocks.add_child(block)


# Returns a list of 2d pairs such that those are global_x and global_y coordinates for a moving block
# TODO: Use this above where this double for loop shows up?
func get_moving_block_global_coords():
	var global_coords = []
	for row_i in range(moving_block_matrix.size()):
		for col_j in range(moving_block_matrix[row_i].size()):
			if moving_block_matrix[row_i][col_j] != 0:
				var global_x_changes = initStartCol - offset_from_start[1]
				var global_y_changes = initStartRow - offset_from_start[0]
				global_coords.append([row_i + global_x_changes, col_j + global_y_changes])
	return global_coords


# Given an x and y coordinate, update the coordinates in moving_block_coords by the given X and Y
# Weirdness of the row/col stuff is irrelevant to inputs
func moving_block_transform(changeX, changeY):
	var can_move: bool = true  # True unless otherwise noted
	var new_moving_block_coords = get_moving_block_global_coords()
	for coord in new_moving_block_coords:
		coord[0] = coord[0] + changeX
		coord[1] = coord[1] + changeY
		# Check border bounds, doesn't matter what blocks we check
		if (coord[0] < 0 or coord[0] > 9) or coord[1] < 0:
			print("hit border?")
			can_move = false
			return can_move  # Early return, one illegal move is all we need

		# Check if there are placed blocks around it, can ignore moving block pieces (2s)
		if game_grid[coord[1]][coord[0]] == 1:
			can_move = false
			return can_move

	# Increment offset - Inverted, and the change vars are already negative
	offset_from_start = [offset_from_start[0] - changeY, offset_from_start[1] - changeX]
	return can_move


# TODO: Make return if possible like the above moving transform function
func rotate_moving_block(rotation_change):
	moving_block_rotation = (moving_block_rotation + rotation_change) % 4
	var block_matrix = BlockCoords.block_map[moving_block_type]  # Starts at 0

	# Perform rotation(s) on original matrix
	for i in range(abs(moving_block_rotation)):
		var x = block_matrix.size()
		var y = block_matrix[0].size()
		var new_rotation = []

		# Transpose
		for m in range(y):
			var new_row = []
			new_row.resize(x)
			new_rotation.append(new_row)

		# Reverse each row
		for m in range(x):
			for n in range(y):
				new_rotation[n][m] = block_matrix[x - m - 1][n]

		#print("new rotation:", new_rotation)

	# TODO
	# Calculate offset from starting position in moving coords
	# NOTE: You should get the current rotation or something...
	#		Maybe hold on to xOffset and yOffset each move for now tbh

	# Reset moving coords

	# Redraw block
