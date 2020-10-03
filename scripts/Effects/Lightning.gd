extends Node2D

onready var line := $Line2D
export var target := Vector2(0, 0)
var points := []

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	var distance := (self.global_position - target).length()
	var num_segments = int(distance / 100)
	while num_segments < points.size():
		points.append(0)
		line.add_point(Vector2.ZERO)
