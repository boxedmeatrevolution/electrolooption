extends Node2D

onready var sprite := $Sprite
var timer := 0.0

func _process(delta : float):
	timer += delta
	if timer >= 0.1:
		sprite.frame = 1
	if timer >= 0.2:
		sprite.frame = 2
	if timer >= 0.3:
		queue_free()
