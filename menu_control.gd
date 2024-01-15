extends Control


func _ready():
	# Populate the speed options
	var speed_options: OptionButton = get_node_or_null("VBoxContainer/OptionButton")

	for i in range(1, 21):
		speed_options.add_item(str(i), i)


# I should just init a new scene tbh, the image isn't noticeable
func _on_start_button_pressed():
	get_parent().start_game()
	queue_free()  # Yoink the menu item


func _on_exit_button_pressed():
	get_tree().quit()


func _on_option_button_item_selected(index):
	get_parent().falling_speed = index  # Index matches value so w/e
