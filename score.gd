extends Label

var score = 0


func _on_main_line_cleared(lines_cleared):
	score += 10 * lines_cleared
	if lines_cleared > 1:
		score += 20 * (lines_cleared / 8)  # Could be better, idk
	text = "Score: %s" % score
