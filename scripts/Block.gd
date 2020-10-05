extends Node2D

onready var sprite := $Sprite

func _ready():
	sprite.frame = randi() % 4
