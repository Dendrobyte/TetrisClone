extends Node

signal line_cleared

# Game Grid
# This is the primary grid to represent the state of the game
# grid[0][1] is row 0 column 1 | row 0 is the bottom row, col 0 is the left-most column
# 0 -> empty
# 2 -> moving block piece
# 2+ -> frozen block pieces
var game_grid = []


func pretty_grid_print():
	print("------------ START ------------")
	for i in range(game_grid.size() - 1, -1, -1):
		print(game_grid[i])
	print("------------ END ------------")


# The actual moving block node
@onready var moving_block: Node3D = $MovingBlockController

# Save offset from start each movement for drawing, freezing. Makes rotation possible (I hope?)
# index 0 is vertical offset, index 1 is horizontal offset
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
@export_range(1, 20) var falling_speed: int = 1  # 1 slowest, 20s fastest
var frame_counter: int = 0
var freeze_delay: int = 5

# Menu stuff
@onready var menu_node = load("res://menu_control.tscn").instantiate()
var pause = false
var is_playing = false
var soundtrack_pos
var music_enabled = true


# Called when the node enters the scene tree for the first time.
func _ready():
	# Start with menu overlay on border background
	add_child(menu_node)
	# Make the pause text invisible
	get_node("UI/PAUSED").visible = false
	# TODO: see if music is enabled
	get_tree().call_group("menu", "is_music_enabled", music_enabled)


# Called to start the game
func start_game():
	init_game_grid()
	spawn_block()

	var soundtrack_node = $UI/Korobeiniki
	soundtrack_node.volume_db = -20.0
	if music_enabled:
		soundtrack_node.play()

	# Final sprint, don't care!
	$UI/GameOver.text = ""
	$UI/RetryButton.visible = false
	$UI/Score.reset()
	$UI/Speed.reset()

	is_playing = true


func end_game():
	for child in $FrozenBlocks.get_children():
		child.queue_free()
	for child in $MovingBlockController.get_children():
		child.queue_free()

	$UI/Korobeiniki.stop()

	$UI/GameOver.text = "GAME OVER\nSCORE: " + str($UI/Score.score)
	$UI/RetryButton.visible = true

	is_playing = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# If we are paused, process nothing
	if pause || !is_playing:
		return
	var has_moved = false
	# Move down at a given speed
	# X is max, so subtract falling speed to make that variable readable = Y
	# multiplier is effectively saying every (Y * 3) frames the block moves
	if frame_counter >= (20 - falling_speed) * 3:
		has_moved = moving_block_transform(0, -1)
		if has_moved:
			freeze_delay = 0
			draw_moving_block()
		else:
			freeze_delay += 1
			# Never go less than 5 frames or more than 60 to freeze
			if freeze_delay == max(min(60, 20 - falling_speed) * 5, 5):
				freeze_moving_block()
		frame_counter = 0
	else:
		frame_counter += 1

	# Delay freezing of a block if moving around
	if has_moved:
		freeze_delay = 0
	freeze_delay += 1

	# Never go less than 5 frames or more than 60 to freeze
	if freeze_delay == max(min(60, 20 - falling_speed) * 5, 5):
		freeze_moving_block()
		freeze_delay = 0


# If the project was better organized, this would make more sense
func block_moved():
	draw_moving_block()
	freeze_delay = 0


func pause_game():
	pause = !pause
	get_node("UI/PAUSED").visible = !get_node("UI/PAUSED").visible
	var soundtrack_node = $UI/Korobeiniki

	# Draw empty or non-empty game grid accordingly
	if pause:
		for child in $FrozenBlocks.get_children():
			child.queue_free()
		for child in $MovingBlockController.get_children():
			child.queue_free()

		# Save the playback position to restart from later
		#if music_enabled:  # I feel like this isn't necessary because you can always stop
		soundtrack_pos = soundtrack_node.get_playback_position()
		soundtrack_node.stop()
	else:
		redraw_game_grid()
		draw_moving_block()
		if music_enabled:
			soundtrack_node.play(soundtrack_pos)


func init_game_grid():
	var grid_rows = []
	for i in range(24):  # Height doesn't really matter
		var row_arr = []
		for j in range(10):
			row_arr.append(0)
		grid_rows.append(row_arr)
	game_grid = grid_rows.duplicate()  # Shallow or deep doesn't matter
	pretty_grid_print()


# Redraw the entire game grid with frozen blocks
func redraw_game_grid():
	# Remove the current children
	for child in $FrozenBlocks.get_children():
		child.queue_free()

	# Iterate over grid and create new grid
	var new_grid = []
	var empty_rows = 0  # could take diff of len(game_grid) - len(new_grid)
	for row in game_grid:
		if 9 not in row:  # 9 marks row to clear
			new_grid.append(row)
			empty_rows += 1
	game_grid = new_grid.duplicate()

	# Then redraw frozen blocks corresponding to proper number
	for row_i in range(game_grid.size()):
		for col_j in range(game_grid[row_i].size()):
			# Subtract 2 because we added 2 since block types start at 0
			if game_grid[row_i][col_j] != 0:
				var block_type = game_grid[row_i][col_j] - 2
				draw_frozen_block(col_j, row_i, block_type)

	# Add new rows onto the grid to account for deleted rows
	for i in range(empty_rows):
		var row_arr = []
		for j in range(10):
			row_arr.append(0)
		game_grid.append(row_arr)

	pretty_grid_print()


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
	for coord in get_moving_block_global_coords():
		draw_frozen_block(coord[0], coord[1], moving_block_type)
		if coord[1] >= 20:
			# TODO: Move to game over functino
			end_game()
			if music_enabled:  # I feel like this isn't necessary because you can always stop
				$UI/Korobeiniki.stop()
			init_game_grid()  # TODO: Start over for now
			return
		game_grid[coord[1]][coord[0]] = moving_block_type + 2  # Add 2 because 0 and 1 are block types

	# Since game grid is updated, check for clearable lines
	# We could technically provide some y-value(s) to redraw but imo the performance doesn't matter
	var clear_line_found = false
	var lines_cleared = 0
	for row in game_grid:
		if 0 not in row:
			clear_line_found = true
			lines_cleared += 1
			for i in range(row.size()):
				# Clear from game grid
				row[i] = 9  # 9 marks for deletion

	# Redraw the whole ass grid after all lines are checked
	if clear_line_found:
		redraw_game_grid()
		line_cleared.emit(lines_cleared)

	# Clear children of moving block controller
	for child in $MovingBlockController.get_children():
		child.queue_free()

	# I doubt I need one per sound effect in general, but this suffices for now
	# Likely reloading sound resource or something for each stream?
	$BlockFreezeSound.play()

	freeze_delay = 0  # Reset here because instant down also freezes. Variable itself should be better organized.
	spawn_block()


# Child function to draw a block, doesn't parent to show in scene
func draw_block(global_x, global_y, block_type):
	var block = load("res://assets/SinglePiece.tscn").instantiate()
	block.position = Vector3(global_x, global_y, 1)

	# This feels... reflect-y
	block.get_children()[0].mesh = load(
		"res://assets/BlockPieces/SinglePiece-%s.obj" % str(block_type)
	)
	return block


# Visually draw a block given its current matrix (rotated) combined with offset from start
func draw_moving_block():
	# Clear children since we always redraw
	for child in $MovingBlockController.get_children():
		child.free()

	for coord in get_moving_block_global_coords():
		var block = draw_block(coord[0], coord[1], moving_block_type)
		$MovingBlockController.add_child(block)


# Visually draw a block that will never move
# Frozen type varies for a landing block or drawing from game grid redraw
func draw_frozen_block(x, y, frozen_block_type):
	var block = draw_block(x, y, frozen_block_type)
	$FrozenBlocks.add_child(block)


# Returns a list of 2d pairs such that those are global_x and global_y coordinates for a moving block
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
		var xCoord = coord[0] + changeX
		var yCoord = coord[1] + changeY
		# Check border bounds, doesn't matter what blocks we check
		if (xCoord < 0 or xCoord > 9) or yCoord < 0:
			can_move = false
			return can_move  # Early return, one illegal move is all we need

		# Check if there are placed blocks around it, can ignore moving block pieces (1s)
		if game_grid[yCoord][xCoord] >= 2:
			can_move = false
			return can_move

	# Increment offset - Inverted, and the change vars are already negative
	offset_from_start = [offset_from_start[0] - changeY, offset_from_start[1] - changeX]

	# It is up to the function that sees this to check can_move and redraw accordingly
	return can_move


func rotate_moving_block(change):
	var rotations = 0
	if change == 1:
		rotations = 1
	if change == -1:
		rotations = 3

	for i in range(rotations):
		rotate_moving_block_once()

	# Clear all previous children and redraw
	for child in $MovingBlockController.get_children():
		child.queue_free()
	draw_moving_block()


# TODO: Make return if possible like the above moving transform function
# Rotates the moving block matrix and triggers a redraw
func rotate_moving_block_once():
	# Rotate the matrix
	var x = moving_block_matrix.size()
	var y = moving_block_matrix[0].size()
	var new_rotation = []
	# Transpose
	for m in range(y):
		var new_row = []
		new_row.resize(x)
		new_rotation.append(new_row)

	# Reverse each row
	for m in range(x):
		for n in range(y):
			new_rotation[n][m] = moving_block_matrix[x - m - 1][n]

	# TODO: See if valid, return early if not

	# Set the new matrix and redraw the block
	moving_block_matrix = new_rotation


func _on_retry_button_pressed():
	start_game()
