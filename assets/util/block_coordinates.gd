extends Node

var block_count = 7  # For now, o and t blocks

var o_block = [[2, 2], [2, 2]]

var t_block = [[0, 2, 0], [2, 2, 2], [0, 0, 0]]

var i_block = [
	[0, 2, 0, 0],
	[0, 2, 0, 0],
	[0, 2, 0, 0],
	[0, 2, 0, 0],
]

var j_block = [[2, 0, 0], [2, 2, 2], [0, 0, 0]]

var l_block = [[0, 0, 2], [2, 2, 2], [0, 0, 0]]

var s_block = [[0, 2, 2], [2, 2, 0], [0, 0, 0]]

var z_block = [[2, 2, 0], [0, 2, 2], [0, 0, 0]]

var block_map = {
	0: o_block,
	1: t_block,
	2: i_block,
	3: j_block,
	4: l_block,
	5: s_block,
	6: z_block,
}

var block_colors = {
	0: Color.GOLD,
	1: Color.PURPLE,
	2: Color.AQUA,
	3: Color.DARK_ORANGE,
	4: Color.DARK_BLUE,
	5: Color.DARK_RED,
	6: Color.DARK_GREEN,
}


# Takes a given block matrix and applies a rotation
func rotate_block(_block):
	pass
