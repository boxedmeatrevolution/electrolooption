extends Node2D

var timer := 0.0

func _ready():
	self.scale.x = 0.0
	self.scale.y = 0.0


func _process(delta : float):
	timer += delta
	if timer < 0.5:
		self.scale.x = sin(timer * PI)
		self.scale.y = sin(timer * PI)
	else:
		self.scale.x = 1.0
		self.scale.y = 1.0

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed && timer >= 0.5:
			Utility.next_level(get_tree())
