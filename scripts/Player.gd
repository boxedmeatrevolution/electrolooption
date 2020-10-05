extends Node2D

const GameState := preload("res://scripts/GameState.gd")

onready var area := $Area2D
onready var player_move_tile_parent := get_tree().get_root().find_node("PlayerMoveTiles", true, false)
onready var select := $Select
onready var sprite := $Sprite
var animate_timer := 0.0

var game_state : GameState
onready var controller := get_tree().get_root().find_node("Controller", true, false)

func _ready() -> void:
	player_move_tile_parent.visible = false

func _process(delta: float) -> void:
	select.rotation += delta * (0.5 + select.frame)
	if Utility.mode == Utility.MODE_PLAYER_DRAG:
		self.position = get_global_mouse_position()
		self.player_move_tile_parent.visible = true
		sprite.frame = 2
	else:
		animate_timer += delta
		if animate_timer > 0.0:
			sprite.frame = 0
		if animate_timer > 0.4:
			sprite.frame = 1
		if animate_timer > 0.8:
			animate_timer = 0.0
		var target := Utility.board_to_world(game_state.get_player_pos())
		if (position - target).length_squared() < 10 * 10:
			position = target
		else:
			position += -clamp(15 * delta, 0, 1) * (position - target)
		self.player_move_tile_parent.visible = false
	if Utility.mode == Utility.MODE_PLAYER_PLACE_REWIND:
		select.visible = true
	else:
		select.visible = false

func _mouse_enter():
	select.frame = 1

func _mouse_exit():
	select.frame = 0

func _rewind(idx: int) -> void:
	pass

func _input_event(viewport: Node2D, event: InputEvent, idx: int):
	if event is InputEventMouseButton:
		if event.pressed && event.button_index == BUTTON_LEFT:
			if Utility.mode == Utility.MODE_PLAYER_PLACE_REWIND:
				if game_state.phase == GameState.PHASE_PLAYER_PREPARE && GameState.MANUAL_REWIND_PLACE:
					if game_state.prepare_player_place_rewind():
						game_state.phase_complete()
						Utility.mode = Utility.MODE_ENEMY_TURN
			if Utility.mode == Utility.MODE_PLAYER_DEFAULT:
				if game_state.phase == GameState.PHASE_PLAYER_PREPARE:
					Utility.mode = Utility.MODE_PLAYER_DRAG
		elif !event.pressed && event.button_index == BUTTON_LEFT:
			if Utility.mode == Utility.MODE_PLAYER_DRAG:
				# Check if movement is valid.
				var board_position = Utility.world_to_board(self.position)
				if game_state.prepare_player_move(board_position):
					game_state.phase_complete()
					Utility.mode = Utility.MODE_ENEMY_TURN
				else:
					Utility.mode = Utility.MODE_PLAYER_DEFAULT
