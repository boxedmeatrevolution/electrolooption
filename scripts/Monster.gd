extends Node2D

const GameState := preload("res://scripts/GameState.gd")
const IVec := preload("res://scripts/IVec.gd")

var game_state : GameState
var idx : int

const MODE_DEFAULT := 0
const MODE_MOVING := 1
const MODE_ATTACKING := 2

var mode := MODE_DEFAULT
var attack_timer := 0.0

func setup(game_state: GameState, idx : int) -> void:
	self.game_state = game_state
	self.idx = idx
	self.game_state.connect("on_monster_move", self, "_move")
	self.game_state.connect("on_monster_attack", self, "_attack")
	self.game_state.connect("on_monster_death", self, "_death")
	self.game_state.connect("on_monster_prepare", self, "_prepare")
	position = Utility.board_to_world(self.game_state.get_monster_pos(idx))

func _process(delta: float) -> void:
	if mode == MODE_DEFAULT:
		pass
	elif mode == MODE_MOVING:
		var target := Utility.board_to_world(self.game_state.get_monster_pos(idx))
		position += -clamp(100 * delta, 0, 1) * (position - target)
		if (position - target).length_squared() < 20 * 20:
			position = target
			mode = MODE_DEFAULT
	elif mode == MODE_ATTACKING:
		attack_timer -= delta
		if attack_timer < 0:
			mode = MODE_DEFAULT

func _move(idx: int) -> void:
	mode = MODE_MOVING

func _attack(idx: int) -> void:
	mode = MODE_ATTACKING
	attack_timer = 1.0

func _death(idx: int) -> void:
	if idx == self.idx:
		queue_free()

func _prepare() -> void:
	# Monster AI goes here.
	var player_pos := game_state.get_player_pos()
	var pos := game_state.get_monster_pos(idx)
	var delta_x := player_pos.x - pos.x
	var delta_y := player_pos.y - pos.y
	if abs(delta_x) <= 1 && abs(delta_y) <= 1:
		var tiles := [
			IVec.new(pos.x - 1, pos.y - 1),
			IVec.new(pos.x, pos.y - 1),
			IVec.new(pos.x + 1, pos.y - 1),
			IVec.new(pos.x - 1, pos.y),
			IVec.new(pos.x + 1, pos.y),
			IVec.new(pos.x - 1, pos.y + 1),
			IVec.new(pos.x, pos.y + 1),
			IVec.new(pos.x + 1, pos.y + 1),
		]
		if game_state.prepare_monster_attack(idx, tiles):
			return
	var next_move := []
	if abs(delta_y) > abs(delta_x):
		next_move = [
			IVec.new(pos.x, pos.y + sign(delta_y)),
			IVec.new(pos.x + sign(delta_x), pos.y + sign(delta_y)),
			IVec.new(pos.x + sign(delta_x), pos.y)
		]
	elif abs(delta_y) == abs(delta_x):
		next_move = [
			IVec.new(pos.x + sign(delta_x), pos.y + sign(delta_y)),
			IVec.new(pos.x, pos.y + sign(delta_y)),
			IVec.new(pos.x + sign(delta_x), pos.y)
		]
	else:
		next_move = [
			IVec.new(pos.x + sign(delta_x), pos.y),
			IVec.new(pos.x + sign(delta_x), pos.y + sign(delta_y)),
			IVec.new(pos.x, pos.y + sign(delta_y))
		]
	for move in next_move:
		if game_state.prepare_monster_move(idx, move):
			return
