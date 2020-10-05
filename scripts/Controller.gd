extends Node2D

const Player := preload("res://scripts/Player.gd")
const PlayerRewind := preload("res://entities/PlayerRewind.tscn")
const Block := preload("res://scripts/Block.gd")
const Monster := preload("res://scripts/Monster.gd")
const MonsterSpawn := preload("res://scripts/MonsterSpawn.gd")
const GameState := preload("res://scripts/GameState.gd")
const IVec := preload("res://scripts/IVec.gd").IVec
const MonsterEntity := preload("res://entities/Monster.tscn")
const LaserMonsterEntity := preload("res://entities/LaserMonster.tscn")
const MonsterAttackTile := preload("res://entities/Tiles/MonsterAttackTile.tscn")
const MonsterMoveTile := preload("res://entities/Tiles/MonsterMoveTile.tscn")
const PlayerMoveTile := preload("res://entities/Tiles/PlayerMoveTile.tscn")
const PlayerRewindButton := preload("res://entities/UI/PlayerRewindButton.tscn")
const PlayerPlaceRewindButton := preload("res://entities/UI/PlayerPlaceRewindButton.tscn")
const GameOver := preload("res://entities/UI/GameOver.tscn")
const LevelWon := preload("res://entities/UI/LevelWon.tscn")

onready var main := get_tree().get_root().find_node("Main", true, false)
onready var background := get_tree().get_root().find_node("Background", true, false)
onready var player_move_tile_parent := get_tree().get_root().find_node("PlayerMoveTiles", true, false)
onready var audio_loop_complete := $AudioLoopComplete
onready var audio_rewind := $AudioRewind
var player : Player
var game_state : GameState
var phase_timer := 0.0
var monster_spawn : MonsterSpawn

var monster_attack_tiles := []
var monster_move_tiles := []
var player_move_tiles := []

var lose_timer := -1.0
var win_timer := -1.0

var player_rewind_button := PlayerRewindButton.instance()
var player_place_rewind_button := PlayerPlaceRewindButton.instance()

func _ready() -> void:
	Utility.mode = Utility.MODE_PLAYER_DEFAULT
	var player : Player
	var blocks := []
	var monsters := []
	var monster_nodes := []
	for child in main.get_children():
		if child is Player:
			player = child
		elif child is Block:
			var board_position := Utility.world_to_board(child.position)
			child.position = Utility.board_to_world(board_position)
			blocks.append(board_position)
		elif child is Monster:
			var board_position := Utility.world_to_board(child.position)
			child.position = Utility.board_to_world(board_position)
			monsters.append(board_position)
			monster_nodes.append(child)
	var dimensions = IVec.new(Utility.NUM_TILES_ACROSS, Utility.NUM_TILES_ACROSS)
	game_state = GameState.new(
		Utility.world_to_board(player.position),
		monsters,
		blocks,
		dimensions
	)
	monster_spawn = MonsterSpawn.new(1)
	for monster_idx in range(0, monster_nodes.size()):
		monster_nodes[monster_idx].setup(game_state, monster_idx)
	player.game_state = game_state
	game_state.connect("on_phase_change", self, "_phase_change")
	game_state.connect("on_player_place_rewind", self, "_place_rewind")
	game_state.connect("on_player_loop", self, "_on_loop")
	game_state.connect("on_player_rewind", self, "_rewind")
	game_state.connect("on_game_lose", self, "_lose")
	game_state.connect("on_game_win", self, "_win")
	_add_player_move_tiles()
	player_rewind_button.position = Vector2(140, 1080 - 140)
	player_place_rewind_button.position = Vector2(400, 1080 - 140)
	background.add_child(player_rewind_button)
	background.add_child(player_place_rewind_button)

func _lose() -> void:
	lose_timer = 1.0

func _win() -> void:
	win_timer = 1.0

func _on_loop(loop: Array) -> void:
	audio_loop_complete.play()
	phase_timer += 1.5

func _rewind(idx : int) -> void:
	audio_rewind.play()

func _process(delta: float) -> void:
	if lose_timer > 0.0:
		lose_timer -= delta
		if lose_timer <= 0.0:
			lose_timer = INF
			var game_over := GameOver.instance()
			game_over.position = Vector2(1920/2, 1080/2)
			get_parent().add_child_below_node(main, game_over)
		return
	if win_timer > 0.0:
		win_timer -= delta
		if win_timer <= 0.0:
			win_timer = INF
			var level_won := LevelWon.instance()
			level_won.position = Vector2(1920/2, 1080/2)
			get_parent().add_child_below_node(main, level_won)
		return
	if game_state.phase != GameState.PHASE_PLAYER_PREPARE:
		phase_timer -= delta
		if phase_timer < 0:
			var moves := false
			var attacks := false
			var spawns := game_state._prepared_monster_spawn.empty()
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
			if game_state.phase == GameState.PHASE_MONSTER_PREPARE && !spawns:
				game_state.phase_complete()
			if game_state.phase == GameState.PHASE_MONSTER_SPAWN:
				game_state.phase_complete()
			phase_timer = 0.5

func _add_player_move_tiles() -> void:
	var allowed_moves := game_state.get_cached_legal_player_moves()
	for move in allowed_moves:
		var move_tile := PlayerMoveTile.instance()
		move_tile.board_pos = move
		player_move_tile_parent.add_child(move_tile)
		player_move_tiles.append(move_tile)

func _place_rewind() -> void:
	var player_rewind := PlayerRewind.instance()
	player_rewind.setup(game_state)
	main.add_child(player_rewind)

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
					if attack_pos.x >= 0 && attack_pos.x < Utility.NUM_TILES_ACROSS && attack_pos.y >= 0 && attack_pos.y < Utility.NUM_TILES_ACROSS:
						attack_tile.board_pos = attack_pos
						background.add_child(attack_tile)
						monster_attack_tiles.append(attack_tile)
	if phase_idx == GameState.PHASE_MONSTER_SPAWN:
		var spawns = monster_spawn.get_spawn(game_state)
		for spawn in spawns:
			var monster_idx = game_state.prepare_monster_spawn(spawn["pos"])
			var monster = null;
			if spawn["type"] == MonsterSpawn.MONSTER_TYPE_BASIC:
				monster = MonsterEntity.instance()
			elif spawn["type"] == MonsterSpawn.MONSTER_TYPE_LASER:
				monster = LaserMonsterEntity.instance()
			if monster != null:
				monster.setup(game_state, monster_idx)
				main.add_child(monster)
	if phase_idx == GameState.PHASE_PLAYER_PREPARE:
		Utility.mode = Utility.MODE_PLAYER_DEFAULT
		_add_player_move_tiles()
		var can_rewind := false
		for rewind_idx in range(0, game_state.get_past_player_pos().size()):
			if game_state.test_player_rewind(rewind_idx):
				can_rewind = true
				break
		var can_place_rewind := game_state.test_player_place_rewind()
		player_rewind_button.enabled = can_rewind
		player_place_rewind_button.enabled = can_place_rewind
	if phase_idx == (GameState.PHASE_PLAYER_PREPARE + 1) % GameState.NUM_PHASES:
		player_rewind_button.enabled = false
		player_place_rewind_button.enabled = false
