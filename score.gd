extends Label

var score = 0


func _on_main_line_cleared(lines_cleared):
	score += (10 * lines_cleared) + (5 * (lines_cleared - 1))
	text = "Score: %s" % score


func reset():
	score = 0
	text = "Score: %s" % score
