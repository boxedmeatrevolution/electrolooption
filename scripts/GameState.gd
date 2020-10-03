const IVec = preload("res://scripts/IVec.gd").IVec

const PHASE_PLAYER_PREPARE := 0
const PHASE_PLAYER_ACTION := 1
const PHASE_MONSTER_ATTACK := 2
const PHASE_MONSTER_MOVE := 3
const PHASE_MONSTER_PREPARE := 4
const PHASE_MONSTER_SPAWN := 5

const NUM_PHASES := 6
const WIDTH := 8
const HEIGHT := 8

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

var _next_id := 0
var _block_pos := []
var _monsters := []
var _monster_pos := {}
var _prepared_monster_moves := {}
var _prepared_monster_attack := {}
var _prepared_player_move = null
var _prepared_player_rewind = null
var _player_pos = null
var _player_rewind_pos := []

func _init(player_pos: IVec, monster_pos: Array, block_pos: Array):
	_player_pos = player_pos
	for pos in monster_pos:
		var idx = _get_new_id()
		_monsters.append(idx)
		_monster_pos[idx] = pos
	for pos in block_pos:
		_block_pos.append(pos)

func _get_new_id() -> int:
	_next_id += 1
	return _next_id

func phase_complete() -> int:
	phase = (phase + 1) % NUM_PHASES
	if phase == PHASE_PLAYER_PREPARE:
		## Start of a new turn!
		turn += 1
	elif phase == PHASE_PLAYER_ACTION:
		## Player either moves or rewinds
		if _prepared_player_move != null:
			_player_rewind_pos.append(_player_pos.copy())
			_player_pos = _prepared_player_move
		elif _prepared_player_rewind != null:
			_player_pos = _player_rewind_pos[_prepared_player_rewind]
			if _prepared_player_rewind == 0:
				_player_rewind_pos = []
			else:
				_player_rewind_pos = _player_rewind_pos.slice(0, _prepared_player_move - 1)
		## Reset "prepared" actions
		_prepared_player_move = null
		_prepared_player_rewind = null
	elif phase == PHASE_MONSTER_ATTACK:
		## Reset prepared attacks
		_prepared_monster_attack = {}
	elif phase == PHASE_MONSTER_MOVE:
		## Move monsters to new spots
		for idx in _prepared_monster_moves.keys():
			if idx in _monster_pos:
				_monster_pos[idx] = _prepared_monster_moves[idx]
		## Reset prepared moves
		_prepared_monster_moves = {}
	return phase

func _is_threatened(pos: IVec) -> bool:
	for threatened in _prepared_monster_attack.values():
		for tpos in threatened:
			if pos.eq(tpos):
				return true
	return false

#################
## PLAYER!!!!   #
#################
func test_player_move(pos: IVec) -> bool:
	var is_on_board = !(pos.x < 0 or pos.y < 0 or pos.x > WIDTH or pos.y > HEIGHT)
	var is_cardinal = _player_pos.x or pos.y == _player_pos.y
	var is_diagonal = abs(pos.x - _player_pos.x) == abs(pos.y - _player_pos.y)
	if (is_on_board and (is_cardinal or is_diagonal)):
		## check if the square is threatened
		if _is_threatened(pos):
			return false
		## check if the square is blocked by a block
		for bpos in _block_pos:
			## check if the block's position vector can be extended in the +ve
			## direction such that it overlaps with the player's position
			var block_delta = bpos.minus(_player_pos)
			var new_pos_delta = pos.minus(_player_pos)
			var scale = new_pos_delta.x / block_delta.x
			var scaled_y = round(block_delta.y * scale)
			if scaled_y == _player_pos.y and scale > 1:
				return false
		return true
	return false
	
func test_player_rewind(idx: int) -> bool:
	## check if valid index
	if idx < 0 or idx >= _player_rewind_pos.size():
		return false
	## rewind is not allowed if it causes the player to be threatened
	var pos = _player_rewind_pos[idx]
	if _is_threatened(pos):
		return false
	return true
	
func prepare_player_move(pos: IVec) -> bool:
	if !test_player_move(pos):
		return false
	_prepared_player_move = pos
	return true

func prepare_player_rewind(idx: int) -> bool:
	if !test_player_rewind(idx):
		return false
	_prepared_player_rewind = idx
	return true
	
func get_player_pos() -> IVec:
	return _player_pos
	
func get_past_player_pos() -> Array:
	return _player_rewind_pos

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

	

