extends Node2D

const GameState := preload("res://scripts/GameState.gd")
const Lightning := preload("res://entities/Effects/Lightning.tscn")
const IVec := preload("res://scripts/IVec.gd").IVec
const Poof := preload("res://entities/Effects/Poof.tscn")

onready var area := $Area2D
onready var select := $Select
onready var valid := false
onready var sprite := $Sprite

var death_timer := 0.0
var DEATH_TIME := 1.2
var dying := false

var anchor := Vector2.ZERO

var game_state : GameState
var idx : int
var next : Node2D

var zap_cont := false
var zap_timer := 0.0

var lightnings := []

func setup(game_state: GameState):
	self.game_state = game_state
	self.idx = game_state.get_past_player_pos().size() - 1
	self.game_state.connect("on_player_rewind", self, "_rewind")
	self.game_state.connect("on_player_loop", self, "_loop")
	self.game_state.connect("on_phase_change", self, "_phase_change")
	self.game_state.connect("on_player_place_rewind", self, "_place_rewind")
	self.anchor = Utility.board_to_world(self.game_state.get_past_player_pos()[idx]) + Vector2(0, 4)
	self.position = self.anchor
	self.valid = self.game_state.test_player_rewind(idx)

func _ready():
	_update_lightnings()
	var poof := Poof.instance()
	get_parent().add_child(poof)
	poof.global_position = global_position + Vector2(0, 5)

func _mouse_enter():
	select.frame = 1

func _mouse_exit():
	select.frame = 0

func _phase_change(phase_idx : int) -> void:
	if phase_idx == GameState.PHASE_PLAYER_PREPARE:
		self.valid = self.game_state.test_player_rewind(idx)

func _process(delta : float) -> void:
	self.position.y = self.anchor.y + 3.0 * sin(Utility.timer / 1.0)
	zap_timer += delta
	if zap_timer > 0.0:
		sprite.frame = 1
	if zap_timer > 0.1:
		sprite.frame = 2
	if zap_timer > 0.2:
		sprite.frame = 3
	if zap_timer > 0.3:
		if zap_cont:
			zap_timer = 0.0
		else:
			sprite.frame = 0
			if randf() < 1.0 * delta:
				zap_timer = 0.0
	if dying:
		death_timer += delta
		var mod := 5.0 * death_timer / DEATH_TIME;
		sprite.modulate = Color(1.0 + mod, 1.0 + mod, 1.0 + mod, 1.0)
		if death_timer > DEATH_TIME:
#			var monster_death := MonsterDeath.instance()
#			monster_death.global_position = self.global_position
#			get_parent().add_child(monster_death)
			_clean_lightnings()
			queue_free()
	select.rotation += delta * (0.5 + select.frame)
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
			dying = true
			var lightning := Lightning.instance()
			lightning.start = self.anchor
			lightning.target = Vector2(self.global_position.x, 0.0)
			lightnings.append(lightning)
			get_parent().add_child(lightning)
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
	var pos : IVec = game_state._player_rewind_pos[self.idx]
	var y := Utility.board_to_world(pos).y
	for neighbour in neighbours:
		self.zap_cont = true
		var neighbour_pos : IVec = game_state._player_rewind_pos[neighbour]
		var neighbour_y := Utility.board_to_world(neighbour_pos).y
		if y > neighbour_y:
			continue
		elif y == neighbour_y && self.idx > neighbour:
			continue
		if abs(neighbour_pos.x - pos.x) == 1 or abs(neighbour_pos.y - pos.y) == 1:
			continue
		var lightning_dir := Vector2(sign(neighbour_pos.x - pos.x), sign(neighbour_pos.y - pos.y))
		var lightning_from_pos := Vector2(0.5 * (lightning_dir.x + lightning_dir.y) * sprite.texture.get_width() / 4 * sprite.scale.x, 0.5 * (lightning_dir.x - lightning_dir.y) * sprite.texture.get_height() * sprite.scale.y)
		var lightning := Lightning.instance()
		lightning.start = self.anchor + lightning_from_pos - Vector2(0, 6)
		lightning.target = Utility.board_to_world(game_state.get_past_player_pos()[neighbour]) + Vector2(0, -2) - lightning_from_pos
		self.get_parent().add_child(lightning)
		lightnings.append(lightning)

func _clean_lightnings() -> void:
	self.zap_cont = false
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
