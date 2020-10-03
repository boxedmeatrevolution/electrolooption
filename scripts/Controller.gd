extends Node2D

const Player := preload("res://scripts/Player.gd")
const Block := preload("res://scripts/Block.gd")
const Monster := preload("res://scripts/Monster.gd")
const GameState := preload("res://scripts/GameState.gd")
const IVec := preload("res://scripts/IVec.gd").IVec

var player : Player
var game_state : GameState

func _ready() -> void:
	var main := get_tree().get_root().find_node("Main")
	var blocks := []
	var monsters := []
	var monster_nodes := []
	for child in main.get_children():
		if child is Player:
			player = child
		elif child is Block:
			blocks.append(Utility.world_to_board(child.position))
		elif child is Monster:
			monsters.append(Utility.world_to_board(child.position))
			monster_nodes.append(child)
	player = get_tree().get_root().find_node("Player")
	game_state = GameState.new(
		Utility.world_to_board(player.position),
		monsters,
		blocks
	)
	for monster_idx in range(0, monster_nodes.size()):
		monster_nodes[monster_idx].setup(game_state, monster_idx)
	player.game_state = game_state

func _process(delta: float) -> void:
	pass
