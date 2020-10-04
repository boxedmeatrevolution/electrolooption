extends Node2D

const IVec := preload("res://scripts/IVec.gd").IVec

var board_pos := IVec.new(0, 0)

func _ready() -> void:
	position = Utility.board_to_world(board_pos)
