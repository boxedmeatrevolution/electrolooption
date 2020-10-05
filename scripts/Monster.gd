extends Node2D

const IVec := preload("res://scripts/IVec.gd").IVec
const GameState := preload("res://scripts/GameState.gd")
const MonsterDeath := preload("res://entities/MonsterDeath.tscn")
const Lightning := preload("res://entities/Effects/Lightning.tscn")

onready var sprite := $Sprite

var game_state : GameState
var idx : int

const MODE_DEFAULT := 0
const MODE_MOVING := 1
const MODE_ATTACKING := 2
const MODE_DYING := 3

const DEATH_TIME := 1.2

var mode := MODE_DEFAULT
var attack_timer := 0.0
var death_timer := 0.0
var animation_timer := 0.0

func setup(game_state: GameState, idx : int) -> void:
	self.game_state = game_state
	self.idx = idx
	self.game_state.connect("on_monster_move", self, "_move")
	self.game_state.connect("on_monster_attack", self, "_attack")
	self.game_state.connect("on_monster_death", self, "_death")
	self.game_state.connect("on_monster_prepare", self, "_prepare")
	position = Utility.board_to_world(self.game_state.get_monster_pos(idx))

func _process(delta: float) -> void:
	animation_timer += delta
	if animation_timer >= 0.0:
		sprite.frame = 0
	if animation_timer >= 0.6:
		sprite.frame = 1
	if animation_timer >= 1.2:
		animation_timer = 0.0
	if mode == MODE_DEFAULT:
		pass
	elif mode == MODE_MOVING:
		var target := Utility.board_to_world(self.game_state.get_monster_pos(idx))
		position += -clamp(10 * delta, 0, 1) * (position - target)
		if (position - target).length_squared() < 5 * 5:
			position = target
			mode = MODE_DEFAULT
	elif mode == MODE_ATTACKING:
		sprite.frame = 2
		attack_timer -= delta
		if attack_timer < 0:
			mode = MODE_DEFAULT
	elif mode == MODE_DYING:
		death_timer += delta
		var mod := 5.0 * death_timer / DEATH_TIME;
		sprite.modulate = Color(1.0 + mod, 1.0 + mod, 1.0 + mod, 1.0)
		if death_timer > DEATH_TIME:
			var monster_death := MonsterDeath.instance()
			monster_death.global_position = self.global_position
			get_parent().add_child(monster_death)
			queue_free()
			

func _move(idx: int) -> void:
	if idx == self.idx:
		mode = MODE_MOVING

func _attack(idx: int) -> void:
	if idx == self.idx:
		mode = MODE_ATTACKING
		attack_timer = 0.5

func _death(idx: int) -> void:
	if idx == self.idx:
		mode = MODE_DYING
		var lightning := Lightning.instance()
		lightning.position = Vector2(0, -1)
		lightning.target = Vector2(self.global_position.x, 0.0)
		add_child(lightning)

func _prepare(idx: int) -> void:
	# Monster AI goes here.
	if idx != self.idx:
		return
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
		var delta_x_sign : int = sign(delta_x) if delta_x != 0 else 1
		next_move = [
			IVec.new(pos.x, pos.y + sign(delta_y)),
			IVec.new(pos.x + sign(delta_x), pos.y + sign(delta_y)),
			IVec.new(pos.x + sign(delta_x), pos.y),
			IVec.new(pos.x + delta_x_sign, pos.y - sign(delta_y)),
			IVec.new(pos.x - delta_x_sign, pos.y + sign(delta_y)),
		]
	elif abs(delta_y) == abs(delta_x):
		next_move = [
			IVec.new(pos.x + sign(delta_x), pos.y + sign(delta_y)),
			IVec.new(pos.x, pos.y + sign(delta_y)),
			IVec.new(pos.x + sign(delta_x), pos.y),
			IVec.new(pos.x + sign(delta_x), pos.y - sign(delta_y)),
			IVec.new(pos.x - sign(delta_x), pos.y + sign(delta_y)),
		]
	else:
		var delta_y_sign : int = sign(delta_y) if delta_y != 0 else 1
		next_move = [
			IVec.new(pos.x + sign(delta_x), pos.y),
			IVec.new(pos.x + sign(delta_x), pos.y + sign(delta_y)),
			IVec.new(pos.x, pos.y + sign(delta_y)),
			IVec.new(pos.x - sign(delta_x), pos.y + delta_y_sign),
			IVec.new(pos.x + sign(delta_x), pos.y - delta_y_sign),
		]
	for move in next_move:
		if game_state.prepare_monster_move(idx, move):
			return
