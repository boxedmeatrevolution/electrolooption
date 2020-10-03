const IVec = preload("res://scripts/IVec.gd")

const PHASE_PLAYER_PREPARE := 0
const PHASE_PLAYER_ACTION := 1
const PHASE_MONSTER_ATTACK := 2
const PHASE_MONSTER_MOVE := 3
const PHASE_MONSTER_PREPARE := 4
const PHASE_MONSTER_SPAWN := 5

const NUM_PHASES := 6

var phase := 0
var turn := 0

signal on_phase_change(phase)
signal on_player_spawn()
signal on_player_move()
signal on_player_rewind(idx)
signal on_player_death()
signal on_monster_spawn(idx)
signal on_monster_prepare(idx)
signal on_monster_move(idx)
signal on_monster_attack(idx)
signal on_monster_death(idx)

var _board = []
var _monsters = []
var _prepared_monster_moves = []
var _prepared_monster_attack = []
var _prepared_player_move = []
var _prepared_player_rewind = []
var _player_pos = IVec.new(0,0)
var _player_rewind_pos = []

func _init(player_pos: IVec, monster_pos: Array, block_pos: Array):
	pass

func phase_complete() -> int:
	phase = (phase + 1) % NUM_PHASES
	if phase == PHASE_PLAYER_PREPARE:
		turn += 1
	return phase

#################
## PLAYER!!!!   #
#################
func test_player_move(pos: IVec) -> bool:
	return false
	
func test_player_rewind(idx: int) -> bool:
	return false
	
func prepare_player_move(pos: IVec) -> bool:
	return false

func prepare_player_rewind(idx: int) -> bool:
	return false
	
func get_player_pos() -> IVec:
	return IVec.new(0,0)
	
func get_past_player_pos() -> Array:
	return []

#################
## MONSTERS!!!! #
#################
func prepare_monster_move(idx: int, pos: IVec) -> bool:
	return false
	
func get_monster_move(idx: int) -> IVec:
	return IVec.new(0,0)
	
func prepare_monster_attack(idx: int, threatened_tiles: Array) -> bool:
	return false
	
func get_monster_pos(idx: int) -> IVec:
	return IVec.new(0,0)
	
func get_monster_attack(idx: int) -> Array:
	return []
	
func prepare_monster_spawn(pos: IVec) -> int:
	return 0

	

