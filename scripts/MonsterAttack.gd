extends Node2D

const IVec := preload("res://scripts/IVec.gd").IVec
const GameState := preload("res://scripts/GameState.gd")

const TIMER_MAX := 0.7
var timer := TIMER_MAX
onready var sprite := $Sprite
var board_pos := IVec.new(0, 0)
var game_state : GameState
var idx : int

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite.visible = false
	sprite.position.y -= 30
	position = Utility.board_to_world(board_pos) + Vector2(0, 4)
	game_state.connect("on_monster_attack", self, "_go")

func _go(idx : int) -> void:
	if idx == self.idx:
		sprite.visible = true

func _process(delta : float):
	if sprite.visible:
		timer -= delta
		if timer < TIMER_MAX / 2.0:
			sprite.modulate = Color(1.0, 1.0, 1.0, 2.0 * timer / TIMER_MAX)
			if timer < 0.0:
				queue_free()
		else:
			sprite.position.y += 30 * delta
