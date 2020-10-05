extends Node2D

const GameState := preload("res://scripts/GameState.gd")
const Lightning := preload("res://entities/Effects/Lightning.tscn")

onready var area := $Area2D
onready var select := $Select
onready var valid := false

var game_state : GameState
var idx : int
var next : Node2D

var lightnings := []

func setup(game_state: GameState):
	self.game_state = game_state
	self.idx = game_state.get_past_player_pos().size() - 1
	self.game_state.connect("on_player_rewind", self, "_rewind")
	self.game_state.connect("on_player_loop", self, "_loop")
	self.game_state.connect("on_phase_change", self, "_phase_change")
	self.game_state.connect("on_player_place_rewind", self, "_place_rewind")
	position = Utility.board_to_world(self.game_state.get_past_player_pos()[idx]) + Vector2(0, 1)
	self.valid = self.game_state.test_player_rewind(idx)

func _ready():
	_update_lightnings()

func _mouse_enter():
	select.frame = 1

func _mouse_exit():
	select.frame = 0

func _phase_change(phase_idx : int) -> void:
	if phase_idx == GameState.PHASE_PLAYER_PREPARE:
		self.valid = self.game_state.test_player_rewind(idx)

func _process(delta : float) -> void:
	if Utility.mode == Utility.MODE_PLAYER_REWIND && self.valid:
		select.visible = true
	else:
		select.visible = false

func _rewind(idx: int) -> void:
	print("rewind ", idx)
	if idx == self.idx:
		_clean_lightnings()
		queue_free()
	else:
		self.idx -= 1
		_update_lightnings()

func _loop(loop : Array) -> void:
	for loop_idx in loop:
		if loop_idx == self.idx:
			_clean_lightnings()
			queue_free()
			return
	for loop_idx in loop:
		if loop_idx < self.idx:
			self.idx -= 1
	_update_lightnings()

func _place_rewind() -> void:
	_update_lightnings()

func _update_lightnings() -> void:
	_clean_lightnings()
	var neighbours : Array = game_state._connection_map[self.idx]
	for neighbour in neighbours:
		var neighbour_y := Utility.board_to_world(game_state._player_rewind_pos[neighbour]).y
		var y := Utility.board_to_world(game_state._player_rewind_pos[self.idx]).y
		if y > neighbour_y:
			continue
		elif y == neighbour_y && self.idx > neighbour:
			continue
		var lightning := Lightning.instance()
		lightning.global_position = self.position
		lightning.target = Utility.board_to_world(game_state.get_past_player_pos()[neighbour])
		self.get_parent().add_child(lightning)
		lightnings.append(lightning)

func _clean_lightnings() -> void:
	for lightning in self.lightnings:
		lightning.queue_free()
	lightnings.clear()

func _input_event(viewport: Node2D, event: InputEvent, ev_idx: int):
	if event is InputEventMouseButton:
		if event.pressed:
			if Utility.mode == Utility.MODE_PLAYER_REWIND:
				if game_state.phase == GameState.PHASE_PLAYER_PREPARE:
					if game_state.prepare_player_rewind(idx):
						game_state.phase_complete()
						Utility.mode = Utility.MODE_ENEMY_TURN
					else:
						Utility.mode = Utility.MODE_PLAYER_DEFAULT
