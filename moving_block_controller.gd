extends Node3D


func _process(_delta):
	"""
	Handle block movement
	
	First, call a parent function to update the moving block coordinates.
		This returns "can_move" which represents if we're still within grid bounds and
		not moving into other blocks.
	Second, we transform the physical block piece properly
	"""
	if Input.is_action_just_pressed("move_left"):
		if get_parent().moving_block_transform(-1, 0):
			get_parent().draw_moving_block()
	if Input.is_action_just_pressed("move_right"):
		if get_parent().moving_block_transform(1, 0):
			get_parent().draw_moving_block()
	if Input.is_action_just_pressed("move_down"):
		if get_parent().moving_block_transform(0, -1):
			get_parent().draw_moving_block()
			get_parent().frame_counter = 0  # Reset the frame counter to avoid weird skipping movement
	if Input.is_action_just_pressed("instant_down"):
		# Could iter for possibilities then just redraw at the bottom, but imo not worth the optimization
		while get_parent().moving_block_transform(0, -1):
			get_parent().draw_moving_block()
			get_parent().frame_counter = 0

	# Redraw happens on rotate so we're ignoring rotating actual block since it's finicky
	if Input.is_action_just_pressed("rotate_cw"):
		get_parent().rotate_moving_block(1)
	if Input.is_action_just_pressed("rotate_ccw"):
		get_parent().rotate_moving_block(-1)


func reset_position():
	position = Vector3(0, 0, 0)
