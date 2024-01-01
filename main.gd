extends Node

@export var next_block: PackedScene # randomize, the whole hierarchy thing
# Determine how fast the pieces fall
@export_range (1, 60) var falling_speed = 60 # how many frames per block movement

# Called when the node enters the scene tree for the first time.
func _ready():
	_spawn_moveable_block()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Listen for the timer ending signal I guess
	
	# Start the falling timer if it doesn't exist already
	pass


func _on_block_land(block_position):
	# Spawn new immoveable block (no script) at same position
	var immovable_block = load("res://blocks/oblock_immoveable.tscn").instantiate()
	immovable_block.position = block_position
	add_child(immovable_block)
	# TODO: Make into many small blocks.
	#		I need to normalize y val maybe?
	#		Could also just traverse left/right and clear the blocks until I hit the wall
	#		Then do whatever it is to move everything above down
	
	_spawn_moveable_block()
	
func _spawn_moveable_block():
	# Generate new moveable block
	var new_block = next_block.instantiate()
	# TODO: Can I normalize the positions? Lol. Scale it all up I guess?
	new_block.position = Vector3(-0.874243, 33.4, 0)
	new_block.falling_speed = falling_speed
	new_block.block_land.connect(_on_block_land)
	add_child(new_block)
