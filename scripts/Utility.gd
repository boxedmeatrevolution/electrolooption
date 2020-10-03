extends Node

const IVec := preload("res://scripts/IVec.gd").IVec

const TILE_WIDTH := 192
const TILE_HEIGHT := 112 + 2
const NUM_TILES_ACROSS := 8
const BOARD_CENTER := Vector2(0.5 * 1920, 0.5 * 1080)

var transform : Transform2D
var transform_inv : Transform2D

func _ready() -> void:
	_update_transform()

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
