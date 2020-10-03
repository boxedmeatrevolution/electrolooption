extends Node2D

const GameState := preload("res://scripts/GameState.gd")

onready var area := $Area2D

var game_state : GameState
var idx : int

func setup(game_state: GameState):
	self.game_state = game_state
	self.idx = game_state.get_past_player_pos().size() - 1
	self.game_state.connect("on_player_rewind", self, "_rewind")
	position = Utility.board_to_world(self.game_state.get_past_player_pos()[idx])

func _rewind(idx: int) -> void:
	# On rewind, if this no longer exists, then destroy it.
	if idx < self.idx:
		queue_free()
	elif idx == self.idx:
		queue_free()

func _input_event(viewport: Node2D, event: InputEvent, ev_idx: int):
	if event is InputEventMouseButton:
		if event.pressed && event.doubleclick:
			if game_state.phase == GameState.PHASE_PLAYER_PREPARE:
				if game_state.prepare_player_rewind(idx):
					game_state.phase_complete()
