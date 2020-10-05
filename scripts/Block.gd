extends Node2D

onready var sprite := $Sprite

func _ready():
	sprite.frame = randi() % 4
	if randf() < 0.5:
		sprite.scale.x = -1
