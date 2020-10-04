extends Node2D

const Player := preload("res://scripts/Player.gd")
const Block := preload("res://scripts/Block.gd")
const Monster := preload("res://scripts/Monster.gd")
const MonsterSpawn := preload("res://scripts/MonsterSpawn.gd")
const GameState := preload("res://scripts/GameState.gd")
const IVec := preload("res://scripts/IVec.gd").IVec
const MonsterEntity := preload("res://entities/Monster.tscn")
const MonsterAttackTile := preload("res://entities/Tiles/MonsterAttackTile.tscn")
const MonsterMoveTile := preload("res://entities/Tiles/MonsterMoveTile.tscn")
const PlayerMoveTile := preload("res://entities/Tiles/PlayerMoveTile.tscn")

onready var main := get_tree().get_root().find_node("Main", true, false)
onready var background := get_tree().get_root().find_node("Background", true, false)
onready var player_move_tile_parent := get_tree().get_root().find_node("PlayerMoveTiles", true, false)
var player : Player
var game_state : GameState
var phase_timer := 0.0
var monster_spawn : MonsterSpawn

var monster_attack_tiles := []
var monster_move_tiles := []
var player_move_tiles := []

func _ready() -> void:
	var player : Player
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
	monster_spawn = MonsterSpawn.new(1)
	for monster_idx in range(0, monster_nodes.size()):
		monster_nodes[monster_idx].setup(game_state, monster_idx)
	player.game_state = game_state
	game_state.connect("on_phase_change", self, "_phase_change")
	_add_player_move_tiles()

func _process(delta: float) -> void:
	if game_state.phase != GameState.PHASE_PLAYER_PREPARE:
		phase_timer -= delta
		if phase_timer < 0:
			var moves = false;
			var attacks = false;
			if game_state.phase == GameState.PHASE_MONSTER_MOVE - 1:
				for monster_idx in game_state.get_monster_ids():
					if game_state.get_monster_move(monster_idx) != null:
						moves = true
						break
			if game_state.phase == GameState.PHASE_MONSTER_ATTACK - 1:
				for monster_idx in game_state.get_monster_ids():
					if game_state.get_monster_attack(monster_idx) != null:
						attacks = true
						break
			game_state.phase_complete()
			if game_state.phase == GameState.PHASE_MONSTER_MOVE && !moves:
				game_state.phase_complete()
			if game_state.phase == GameState.PHASE_MONSTER_ATTACK && !attacks:
				game_state.phase_complete()
			phase_timer = 0.5

func _add_player_move_tiles() -> void:
	var allowed_moves := game_state.get_cached_legal_player_moves()
	for move in allowed_moves:
		var move_tile := PlayerMoveTile.instance()
		move_tile.board_pos = move
		player_move_tile_parent.add_child(move_tile)
		player_move_tiles.append(move_tile)

func _phase_change(phase_idx: int) -> void:
	# Clear old tiles
	if phase_idx == ((GameState.PHASE_MONSTER_ATTACK + 1) % GameState.NUM_PHASES):
		for tile in monster_attack_tiles:
			tile.queue_free()
		monster_attack_tiles.clear()
	if phase_idx == ((GameState.PHASE_MONSTER_MOVE + 1) % GameState.NUM_PHASES):
		for tile in monster_move_tiles:
			tile.queue_free()
		monster_move_tiles.clear()
	if phase_idx == GameState.PHASE_PLAYER_ACTION:
		for tile in player_move_tiles:
			tile.queue_free()
		player_move_tiles.clear()
	if phase_idx == ((GameState.PHASE_MONSTER_PREPARE + 1) % GameState.NUM_PHASES):
		# Create new tiles for the new monster moves and attacks.
		for monster_idx in game_state.get_monster_ids():
			var move := game_state.get_monster_move(monster_idx)
			var attack := game_state.get_monster_attack(monster_idx)
			if move != null:
				var move_tile := MonsterMoveTile.instance()
				move_tile.board_pos = move
				background.add_child(move_tile)
				monster_move_tiles.append(move_tile)
			if attack != null:
				for attack_pos in attack:
					var attack_tile := MonsterAttackTile.instance()
					attack_tile.board_pos = attack_pos
					background.add_child(attack_tile)
					monster_attack_tiles.append(attack_tile)
	if phase_idx == GameState.PHASE_MONSTER_SPAWN:
		var spawns = monster_spawn.get_spawn(game_state)
		for spawn in spawns:
			var monster_idx = game_state.prepare_monster_spawn(spawn["pos"])
			var monster = MonsterEntity.instance()
			monster.setup(game_state, monster_idx)
			main.add_child(monster)
	if phase_idx == GameState.PHASE_PLAYER_PREPARE:
		_add_player_move_tiles()
