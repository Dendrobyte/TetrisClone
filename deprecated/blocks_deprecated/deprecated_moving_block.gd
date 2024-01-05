extends CharacterBody3D

signal block_land

# DEPRECATED
# This uses a bunch of physics and the grid approach is definitely the far better way to go about this.
# Keeping this for posterity since this was my first attempt anyway.

# shifting in one direction is 1.76 for whatever reason
var movement_size = 1.76
var frame_counter = 0
var falling_speed

func _physics_process(_delta):
	# Automatically make the block fall
	var collision_info = null
	if not is_on_floor():
		if frame_counter == falling_speed:
			collision_info = move_and_collide(Vector3(0, movement_size*-1, 0))
			frame_counter = 0
		else:
			collision_info = null
			frame_counter += 1

	# Moving the piece manually
	if Input.is_action_just_pressed("move_left"):
		move_and_collide(Vector3(movement_size*-1, 0, 0))
	if Input.is_action_just_pressed("move_right"):
		move_and_collide(Vector3(movement_size, 0, 0))
	if Input.is_action_just_pressed("move_down"):
		collision_info = move_and_collide(Vector3(0, movement_size*-1, 0))
		frame_counter = 0 # Reset the frame counter to avoid double movement
	if Input.is_action_just_pressed("rotate_cw"):
		rotate_z(deg_to_rad(int(-90)))
	if Input.is_action_just_pressed("rotate_ccw"):
		rotate_z(deg_to_rad(int(90)))
		
	# Check if the block hits the floor; only not null on downward movement
	if collision_info:
		print(collision_info.get_angle())
		if collision_info.get_angle() < 0.05: # the tblock collision is just SLIGHTLY angled lol
			# Emit signal
			emit_signal("block_land", position, rotation)
			
			# Yoink moveable
			queue_free()

# Generate a new block
func spawn():
	# TODO: main_block should not be attached to o_block
	pass
