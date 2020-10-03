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

var _next_id := -1
var _block_pos := []
var _monsters := {}
var _monster_pos := {}
var _prepared_monster_moves := {}
var _prepared_monster_attack := {}
var _prepared_monster_spawn := {}
var _prepared_player_move = null
var _prepared_player_rewind = null
var _player_pos = null
var _player_rewind_pos := []

func _init(player_pos: IVec, monster_pos: Array, block_pos: Array):
	_player_pos = player_pos
	for pos in monster_pos:
		var idx = _get_new_id()
		_monsters[idx] = true
		_monster_pos[idx] = pos
	for pos in block_pos:
		_block_pos.append(pos)

func _get_new_id() -> int:
	_next_id += 1
	return _next_id

## Completes a loop, destroying all monsters within the loop
## "idx" is the index of a past player position (_player_rewind_pos) 
##  which is treated as the start/end of the loop
func _do_loop(idx):
	## Algorithm: 
	## 1. Determine which tiles contain rope
	## 2. Flood fill the board starting on the boundary (the "fill" cannot cross ropes)
	## 3. Tiles that are unfilled are bounded by ropes: KILL THE MONSTERS INSIDE
	## 4. Remove player clones that were destroyed when the loop closed
	
	## rope map is a 2D boolean array for tiles with ropes on them
	var rope_map = []
	for x in range(WIDTH):
		rope_map.append([])
		for y in range(HEIGHT):
			rope_map[x].append(false)
	
	## Populate the rope map
	var pt = _player_rewind_pos[idx]
	for i in range(idx, _player_rewind_pos.size()):
		rope_map[pt.x][pt.y] = true
		var next_pt = _player_rewind_pos[i]
		var dist = next_pt.minus(pt)
		var unit_dist = IVec.new(0,0)
		if dist.x != 0 and dist.y == 0:
			unit_dist = IVec.new(round(float(abs(dist.x)) / float(dist.x)), 0)
		elif dist.x == 0 and dist.y != 0:
			unit_dist = IVec.new(0, round(float(abs(dist.y)) / float(dist.y)))
		elif dist.x != 0 and dist.y != 0:
			unit_dist = IVec.new(round(float(abs(dist.x)) / float(dist.x)), round(float(abs(dist.y)) / float(dist.y)))
		
		if unit_dist.x == 0 and unit_dist.y == 0:
			continue
			
		while !pt.eq(next_pt):
			assert(!(pt.x < 0 or pt.y < 0 or pt.x >= WIDTH or pt.y >= HEIGHT))
			pt = pt.add(unit_dist)
			rope_map[pt.x][pt.y] = true
			
		pt = _player_rewind_pos[i]
		
	## Do a flood fill to determine what is "outside" the loop
	var fill_map = []
	var padded_rope_map = []
	for x in range(WIDTH + 2):
		fill_map.append([])
		padded_rope_map.append([])
		for y in range(HEIGHT + 2):
			fill_map[x].append(false)
			if y == 0 or x == 0 or y == HEIGHT+1 or x == WIDTH+1:
				padded_rope_map[x].append(false)
			else:
				padded_rope_map[x].append(rope_map[x-1][y-1])
	_do_fill(0, 0, fill_map, padded_rope_map)
	
	## Destroy ensnared monsters
	var to_kill = []
	for i in _monsters.keys():
		var mpos = _monster_pos[i]
		if fill_map[mpos.x+1][mpos.y+1] == false and rope_map[mpos.x][mpos.y] == false:
			## Monster is ensnared
			to_kill.append(i)
	for i in to_kill:
		_monsters.erase(i)
		_monster_pos.erase(i)
		_prepared_monster_moves.erase(i)
		_prepared_monster_attack.erase(i)
		
	## Remove player clones
	if idx == 0:
		_player_rewind_pos = []
	else:
		_player_rewind_pos = _player_rewind_pos.slice(0, idx - 1)

func _do_fill(x, y, fill_map, rope_map):
	fill_map[x][y] = true
	if x + 1 < fill_map.size() and fill_map[x+1][y] == false and rope_map[x+1][y] == false:
		_do_fill(x+1, y, fill_map, rope_map)
	if x - 1 >= 0 and fill_map[x-1][y] == false and rope_map[x-1][y] == false:
		_do_fill(x-1, y, fill_map, rope_map)
	if y + 1 < fill_map[0].size() and fill_map[x][y+1] == false and rope_map[x][y+1] == false:
		_do_fill(x, y+1, fill_map, rope_map)
	if y - 1 >= 0 and fill_map[x][y-1] == false and rope_map[x][y-1] == false:
		_do_fill(x, y-1, fill_map, rope_map)

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
			## Check if a loop was completed
			for i in range(_player_rewind_pos.size()):
				if _player_rewind_pos[i].eq(_player_pos):
					## COMPLETED A LOOOOOOP O_O WOWOWOWWOWOWOWWO
					_do_loop(i)
					break
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

func _is_occupied_by_block(pos: IVec) -> bool:
	for bpos in _block_pos:
		if pos.eq(bpos):
			return true
	return false
	
func _will_be_occupied_by_monster(pos: IVec) -> bool:
	for mpos in _prepared_monster_moves.values():
		if pos.eq(mpos):
			return true
	return false

	
#################
## PLAYER!!!!   #
#################
func test_player_move(pos: IVec) -> bool:
	var is_moving = !pos.eq(_player_pos)
	var is_on_board = !(pos.x < 0 or pos.y < 0 or pos.x >= WIDTH or pos.y >= HEIGHT)
	var is_cardinal = pos.x == _player_pos.x or pos.y == _player_pos.y
	var is_diagonal = abs(pos.x - _player_pos.x) == abs(pos.y - _player_pos.y)
	if (is_moving and is_on_board and (is_cardinal or is_diagonal)):
		## check if the square is threatened
		if _is_threatened(pos) or _is_occupied_by_block(pos) or _will_be_occupied_by_monster(pos):
			return false
		## check if moving to new position requires traversing through a wall (this is not allowed)
		for bpos in _block_pos:
			## check if the block's position vector can be extended in the +ve
			## direction such that it overlaps with the player's position
			var block_delta = bpos.minus(_player_pos)
			var new_pos_delta = pos.minus(_player_pos)
			if block_delta.x != 0:
				var scale = float(new_pos_delta.x) / float(block_delta.x)
				var scaled_y = int(round(block_delta.y * scale))
				if scaled_y == new_pos_delta.y and scale > 1:
					return false
			elif block_delta.y != 0:
				var scale = float(new_pos_delta.y) / float(block_delta.y)
				var scaled_x = round(block_delta.x * scale)
				if scaled_x == new_pos_delta.x and scale > 1:
					return false
			else:
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
	_prepared_player_move = pos.copy()
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
	assert(idx in _monsters)
	var mpos = _monster_pos[idx]
	var is_moving = !pos.eq(mpos)
	var is_on_board = !(pos.x < 0 or pos.y < 0 or pos.x >= WIDTH or pos.y >= HEIGHT)
	if is_moving and is_on_board and !_is_occupied_by_block(pos) and !_will_be_occupied_by_monster(pos):
		return false
	_prepared_monster_moves[idx] = pos.copy()
	return true
	
func get_monster_move(idx: int) -> IVec:
	assert(idx in _monsters)
	return _prepared_monster_moves[idx]
	
func prepare_monster_attack(idx: int, threatened_tiles: Array) -> bool:
	assert(idx in _monsters)
	_prepared_monster_attack[idx] = threatened_tiles
	return true
	
func get_monster_pos(idx: int) -> IVec:
	assert(idx in _monsters)
	return _monster_pos[idx]
	
func get_monster_attack(idx: int) -> Array:
	assert(idx in _monsters)
	return _prepared_monster_attack[idx]
	
func prepare_monster_spawn(pos: IVec) -> int:
	var idx = _get_new_id()
	_monsters[idx] = true
	_monster_pos[idx] = pos.copy()
	_prepared_monster_spawn[idx] = pos.copy()
	return idx

