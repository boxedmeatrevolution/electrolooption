extends Node2D

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed && !event.doubleclick:
			Utility.next_level(get_tree())
