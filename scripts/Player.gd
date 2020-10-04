extends Node2D

const GameState := preload("res://scripts/GameState.gd")

onready var area := $Area2D
onready var player_move_tile_parent := get_tree().get_root().find_node("PlayerMoveTiles", true, false)

var game_state : GameState

const MODE_DEFAULT := 0
const MODE_PREPARE_MOVE_DRAG := 1
const MODE_PREPARE_MOVE_RETURN := 2
const MODE_REWIND := 3
var mode := 0

func _ready() -> void:
	player_move_tile_parent.visible = false

func _process(delta: float) -> void:
	if mode == MODE_DEFAULT:
		self.position = Utility.board_to_world(game_state.get_player_pos())
	elif mode == MODE_PREPARE_MOVE_RETURN || mode == MODE_REWIND:
		var target := Utility.board_to_world(game_state.get_player_pos())
		position += -clamp(15 * delta, 0, 1) * (position - target)
		if (position - target).length_squared() < 10 * 10:
			position = target
			mode = MODE_DEFAULT
	elif mode == MODE_PREPARE_MOVE_DRAG:
		self.position = get_global_mouse_position()

func _drag_start() -> void:
	pass

func _drag_end() -> void:
	pass

func _rewind(idx: int) -> void:
	mode = MODE_REWIND

func _input_event(viewport: Node2D, event: InputEvent, idx: int):
	if event is InputEventMouseButton:
		if event.doubleclick:
			if mode == MODE_DEFAULT:
				if game_state.phase == GameState.PHASE_PLAYER_PREPARE && GameState.MANUAL_REWIND_PLACE:
					if game_state.prepare_player_place_rewind():
						game_state.phase_complete()
		elif event.pressed:
			if mode == MODE_DEFAULT:
				if game_state.phase == GameState.PHASE_PLAYER_PREPARE:
					mode = MODE_PREPARE_MOVE_DRAG
					player_move_tile_parent.visible = true
		elif !event.pressed:
			if mode == MODE_PREPARE_MOVE_DRAG:
				# Check if movement is valid.
				var board_position = Utility.world_to_board(self.position)
				if game_state.prepare_player_move(board_position):
					game_state.phase_complete()
				mode = MODE_PREPARE_MOVE_RETURN
				player_move_tile_parent.visible = false
