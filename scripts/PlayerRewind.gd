extends Node2D

const GameState := preload("res://scripts/GameState.gd")

onready var lightning := $Lightning
onready var area := $Area2D

var game_state : GameState
var idx : int
var next : Node2D

func setup(game_state: GameState):
	self.game_state = game_state
	self.idx = game_state.get_past_player_pos().size() - 1
	self.game_state.connect("on_player_rewind", self, "_rewind")
	self.game_state.connect("on_player_loop", self, "_rewind")
	position = Utility.board_to_world(self.game_state.get_past_player_pos()[idx])

func _process(delta : float) -> void:
	var past := game_state.get_past_player_pos()
	var player_pos := game_state.get_player_pos()
	if past.size() - 1 == idx:
		if GameState.MANUAL_REWIND_PLACE:
			if Utility.is_rooks_move(past[idx], player_pos, false):
				lightning.target = Utility.board_to_world(player_pos)
			else:
				lightning.target = self.global_position
		else:
			lightning.target = Utility.board_to_world(player_pos)
	else:
		lightning.target = Utility.board_to_world(past[idx + 1])

func _rewind(idx: int) -> void:
	# On rewind or loop, if this no longer exists, then destroy it.
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
