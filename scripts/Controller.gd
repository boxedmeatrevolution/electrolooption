extends Node2D

const Player := preload("res://scripts/Player.gd")
const Block := preload("res://scripts/Block.gd")
const Monster := preload("res://scripts/Monster.gd")
const GameState := preload("res://scripts/GameState.gd")
const IVec := preload("res://scripts/IVec.gd").IVec

var player : Player
var game_state : GameState
var phase_timer := 0.0

func _ready() -> void:
	var player : Player
	var main := get_tree().get_root().find_node("Main", true, false)
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
	game_state = GameState.new(
		Utility.world_to_board(player.position),
		monsters,
		blocks
	)
	for monster_idx in range(0, monster_nodes.size()):
		monster_nodes[monster_idx].setup(game_state, monster_idx)
	player.game_state = game_state

func _process(delta: float) -> void:
	if game_state.phase != GameState.PHASE_PLAYER_PREPARE:
		phase_timer -= delta
		if phase_timer < 0:
			game_state.phase_complete()
			phase_timer = 0.5
			print("Phaes is ", game_state.phase)
