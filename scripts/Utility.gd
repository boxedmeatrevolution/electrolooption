extends Node

const IVec := preload("res://scripts/IVec.gd").IVec

const TILE_WIDTH := 192
const TILE_HEIGHT := 112 + 2
const NUM_TILES_ACROSS := 7
const BOARD_CENTER := Vector2(0.5 * 1920, 0.5 * 1080)

var transform : Transform2D
var transform_inv : Transform2D

const MODE_PLAYER_DEFAULT := 0
const MODE_PLAYER_DRAG := 1
const MODE_PLAYER_REWIND := 2
const MODE_PLAYER_PLACE_REWIND := 3
const MODE_ENEMY_TURN := 4

const levels := [
	"res://levels/MainMenu.tscn",
	"res://levels/Instructions.tscn",
	"res://levels/Dialogue_1.tscn",
	"res://levels/REAL_LEVEL_1.tscn",
	"res://levels/Dialogue_2.tscn",
	"res://levels/REAL_LEVEL_2.tscn",
	"res://levels/Dialogue_3.tscn",
	"res://levels/REAL_LEVEL_3.tscn",
	"res://levels/Dialogue_4.tscn",
	"res://levels/REAL_LEVEL_4.tscn",
	"res://levels/Dialogue_5.tscn",
	"res://levels/REAL_LEVEL_5.tscn",
	"res://levels/Dialogue_6.tscn",
	"res://levels/REAL_LEVEL_6.tscn",
	"res://levels/Dialogue_7.tscn",
	"res://levels/REAL_LEVEL_7.tscn",
	"res://levels/Dialogue_8.tscn",
	"res://levels/REAL_LEVEL_8.tscn",
	"res://levels/Dialogue_9.tscn",
	"res://levels/REAL_LEVEL_9.tscn",
	"res://levels/Dialogue_10.tscn",
	"res://levels/REAL_LEVEL_10.tscn"
]

var current_level := 0

const HARD_MODE := false

func create_monster_attacks(parent : Node, attack_type : PackedScene, idx : int, game_state : Object, tiles : Array):
	for tile in tiles:
		var attack := attack_type.instance()
		attack.board_pos = tile
		attack.idx = idx
		attack.game_state = game_state
		parent.add_child(attack)

func next_level(root):
	current_level += 1
	root.change_scene(levels[current_level])

func restart_level(root):
	root.reload_current_scene()

var mode := MODE_PLAYER_DEFAULT

var timer := 0.0

func _ready() -> void:
	_update_transform()

func _process(delta : float):
	timer += delta

func gaussian(mean: float = 0.0, std: float = 1.0) -> float:
	return std * sqrt(-2.0 * log(randf())) * cos(2.0 * PI * randf()) + mean

func is_queens_move(a : IVec, b : IVec, include_center : bool = true) -> bool:
	var delta_x := a.x - b.x
	var delta_y := a.y - b.y
	if delta_x == 0 and delta_y == 0:
		return include_center
	return delta_x == 0 or delta_y == 0 or abs(delta_x) == abs(delta_y)

func is_rooks_move(a : IVec, b : IVec, include_center : bool = true) -> bool:
	var delta_x := a.x - b.x
	var delta_y := a.y - b.y
	if delta_x == 0 and delta_y == 0:
		return include_center
	return delta_x == 0 or delta_y == 0

func _update_transform() -> void:
	transform = Transform2D(
		Vector2(0.5 * TILE_WIDTH, 0.5 * TILE_HEIGHT),
		Vector2(0.5 * TILE_WIDTH, -0.5 * TILE_HEIGHT),
		BOARD_CENTER + 0.5 * (NUM_TILES_ACROSS - 1) * TILE_WIDTH * Vector2.LEFT
	)
	transform_inv = transform.affine_inverse()

func board_to_world(board: IVec) -> Vector2:
	var board_pos := Vector2(board.x, board.y)
	return transform * board_pos

func world_to_board(screen: Vector2) -> IVec:
	var board_pos := transform_inv * screen
	var board := IVec.new(int(board_pos.x + 0.5), int(board_pos.y + 0.5))
	return board
	
func _copy_vec(vec) -> IVec:
	return IVec.new(vec.x, vec.y)

func _minus_vec(a, b) -> IVec:
	return IVec.new(a.x - b.x, a.y - b.y)

func _add_vec(a, b) -> IVec:
	return IVec.new(a.x + b.x, a.y + b.y)
