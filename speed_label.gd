extends Label

var total_lines_cleared = 0

# The double get_parent() is hilarious
# I'm almost done so I'm not bothering atm, btu find_node probably better? :)
# Finding out how to emit and return a value would be useful
# Or just work on finding a pattern that is something more elegant


func _on_main_line_cleared(lines_cleared):
	total_lines_cleared += lines_cleared
	if total_lines_cleared >= 10:
		get_parent().get_parent().falling_speed += 1
		total_lines_cleared = total_lines_cleared - 10
	text = "Speed: %s" % str(get_parent().get_parent().falling_speed)


func reset():
	total_lines_cleared = 0
	text = "Speed: %s" % str(get_parent().get_parent().falling_speed)
