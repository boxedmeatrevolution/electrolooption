extends Node2D

onready var sprite := $Sprite

var speed := 900
var accel := .01


func _process(delta: float):
	if Input.is_action_pressed("ui_left"):
		speed *= 1+accel
		self.position.x -= delta * speed
	if Input.is_action_pressed("ui_right"):
		speed *= 1+accel
		self.position.x += delta * speed
		
	if self.position.x < -300:
		self.position.x = 700
	elif self.position.x > 700:
		self.position.x = -300
