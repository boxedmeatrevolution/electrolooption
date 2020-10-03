extends Node2D

const GameState := preload("res://scripts/GameState.gd")
const PlayerRewind := preload("res://entities/PlayerRewind.tscn")

onready var area := $Area2D

var game_state : GameState

const MODE_DEFAULT := 0
const MODE_PREPARE_MOVE_DRAG := 1
const MODE_PREPARE_MOVE_RETURN := 2
const MODE_REWIND := 3
var mode := 0

func _process(delta: float) -> void:
	if mode == MODE_DEFAULT:
		self.position = Utility.board_to_world(game_state.get_player_pos())
	elif mode == MODE_PREPARE_MOVE_RETURN || mode == MODE_REWIND:
		var target := Utility.board_to_world(game_state.get_player_pos())
		position += -clamp(100 * delta, 0, 1) * (position - target)
		if (position - target).length_squared() < 20 * 20:
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
		if event.pressed:
			if mode == MODE_DEFAULT:
				if game_state.phase == GameState.PHASE_PLAYER_PREPARE:
					mode = MODE_PREPARE_MOVE_DRAG
		else:
			if mode == MODE_PREPARE_MOVE_DRAG:
				# Check if movement is valid.
				var board_position = Utility.world_to_board(self.position)
				var loop := game_state.is_occupied_by_past_player(board_position)
				if game_state.prepare_player_move(board_position):
					game_state.phase_complete()
					if not loop:
						var player_rewind := PlayerRewind.instance()
						player_rewind.setup(game_state)
						get_parent().add_child_below_node(self, player_rewind)
				else:
					pass
				mode = MODE_PREPARE_MOVE_RETURN
