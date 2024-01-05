extends Node3D

func _process(delta):
	"""
	Handle block movement
	
	First, call a parent function to update the moving block coordinates.
		This returns "can_move" which represents if we're still within grid bounds and
		not moving into other blocks.
	Second, we transform the physical block piece properly
	"""
	if Input.is_action_just_pressed("move_left"):
		if get_parent().moving_block_transform(-1, 0):
			translate(Vector3(-1, 0, 0))
	if Input.is_action_just_pressed("move_right"):
		if get_parent().moving_block_transform(1, 0):
			translate(Vector3(1, 0, 0))
	if Input.is_action_just_pressed("move_down"):
		if get_parent().moving_block_transform(0, -1):
			translate(Vector3(0, -1, 0))
			get_parent().frame_counter = 0 # Reset the frame counter to avoid weird skipping movement
		
	# TODO: You... you will wait because grid stuff :)
	if Input.is_action_just_pressed("rotate_cw"):
		rotate_z(deg_to_rad(int(-90)))
	if Input.is_action_just_pressed("rotate_ccw"):
		rotate_z(deg_to_rad(int(90)))
