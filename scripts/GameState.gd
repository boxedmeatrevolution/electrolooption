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

const CAN_GO_THROUGH_ROPES := false

var DIRS := [IVec.new(1,0), IVec.new(1,1), IVec.new(0,1), IVec.new(-1,1), 
			IVec.new(-1,0), IVec.new(-1,-1), IVec.new(0,-1), IVec.new(1,-1)]

var phase := 0
var turn := 0

signal on_phase_change(phase)
signal on_player_spawn()  ## TODO
signal on_player_move()
signal on_player_rewind(idx)
signal on_player_loop(idx)
signal on_player_death()  ## TODO
signal on_monster_spawn(idx)  ## TODO
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
var _legal_player_moves := []
var _legal_monster_spawns := []
var _rope_pos := []

func _init(player_pos: IVec, monster_pos: Array, block_pos: Array):
	_player_pos = player_pos
	for pos in monster_pos:
		var idx = _get_new_id()
		_monsters[idx] = true
		_monster_pos[idx] = pos
	for pos in block_pos:
		_block_pos.append(pos)
	_legal_player_moves = _get_legal_player_moves()
	emit_signal("on_phase_change", PHASE_PLAYER_PREPARE)

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
	for i in range(idx, _player_rewind_pos.size()):
		var pt = _player_rewind_pos[i]
		var next_pt = _player_rewind_pos[idx]
		if i < _player_rewind_pos.size()-1:
			next_pt = _player_rewind_pos[i+1]
		rope_map[pt.x][pt.y] = true
		
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
		emit_signal("on_monster_death", i)
		
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
		_legal_player_moves = _get_legal_player_moves()
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
					emit_signal("on_player_loop", i)
					_calc_rope_pos()
					break
			_calc_rope_pos()
			emit_signal("on_player_move")
		elif _prepared_player_rewind != null:
			_player_pos = _player_rewind_pos[_prepared_player_rewind]
			if _prepared_player_rewind == 0:
				_player_rewind_pos = []
			else:
				_player_rewind_pos = _player_rewind_pos.slice(0, _prepared_player_rewind - 1)
			_calc_rope_pos()
			emit_signal("on_player_rewind", _prepared_player_rewind)
		## Reset "prepared" actions
		_prepared_player_move = null
		_prepared_player_rewind = null
	elif phase == PHASE_MONSTER_ATTACK:
		for idx in _prepared_monster_attack.keys():
			emit_signal("on_monster_attack", idx)
		## Reset prepared attacks
		_prepared_monster_attack = {}
	elif phase == PHASE_MONSTER_MOVE:
		## Move monsters to new spots
		for idx in _prepared_monster_moves.keys():
			if idx in _monster_pos:
				_monster_pos[idx] = _prepared_monster_moves[idx]
				emit_signal("on_monster_move", idx)
		## Reset prepared moves
		_prepared_monster_moves = {}
	elif phase == PHASE_MONSTER_PREPARE:
		for idx in _monsters.keys():
			emit_signal("on_monster_prepare", idx)
	elif phase == PHASE_MONSTER_SPAWN:
		_legal_monster_spawns = _get_legal_monster_spawns()
		for idx in _prepared_monster_spawn.keys():
			emit_signal("on_monster_spawn", idx)
		## Reset spawns
		_prepared_monster_spawn = {}
	emit_signal("on_phase_change", phase)
	return phase

func is_threatened(pos: IVec) -> bool:
	for threatened in _prepared_monster_attack.values():
		for tpos in threatened:
			if pos.eq(tpos):
				return true
	return false

func is_occupied_by_block(pos: IVec) -> bool:
	for bpos in _block_pos:
		if pos.eq(bpos):
			return true
	return false

func will_be_occupied_by_monster(pos: IVec) -> bool:
	for idx in _monsters.keys():
		var mpos = _monster_pos[idx]
		if idx in _prepared_monster_moves:
			mpos = _prepared_monster_moves[idx]
		if pos.eq(mpos):
			return true
	return false

func is_occupied_by_monster(pos:IVec) -> bool:
	for idx in _monsters.keys():
		var mpos = _monster_pos[idx]
		if pos.eq(mpos):
			return true
	return false

func is_occupied_by_past_player(pos: IVec) -> bool:
	for p in _player_rewind_pos:
		if pos.eq(p):
			return true
	return false 

func is_occupied_by_rope(pos: IVec) -> bool:
	for rpos in _rope_pos:
		if pos.eq(rpos):
			return true
	return false

func _make_a_line(a: IVec, b: IVec, c: IVec) -> bool:
	## Checks if a - b - c lie on a line 
	## Any orientation, but b in the middle. 
	## If a,b or b,c overlap, then always TRUE
	var b_delta = b.minus(a)
	var c_delta = c.minus(a)
	if b_delta.eq(c_delta):
		return true
	elif b_delta.x != 0:
		var scale = float(c_delta.x) / float(b_delta.x)
		var scaled_y = int(round(b_delta.y * scale))
		if scaled_y == c_delta.y and scale > 1:
			return true
	elif b_delta.y != 0:
		var scale = float(c_delta.y) / float(b_delta.y)
		var scaled_x = round(b_delta.x * scale)
		if scaled_x == c_delta.x and scale > 1:
			return true
	else:
		return true
	return false

func _get_line(a: IVec, b: IVec) -> Array:
	var line = [a]
	var dist = b.minus(a)
	var unit_dist = IVec.new(0,0)
	if dist.x != 0 and dist.y == 0:
		unit_dist = IVec.new(round(float(abs(dist.x)) / float(dist.x)), 0)
	elif dist.x == 0 and dist.y != 0:
		unit_dist = IVec.new(0, round(float(abs(dist.y)) / float(dist.y)))
	elif dist.x != 0 and dist.y != 0:
		unit_dist = IVec.new(round(float(abs(dist.x)) / float(dist.x)), round(float(abs(dist.y)) / float(dist.y)))
	
	if unit_dist.x == 0 and unit_dist.y == 0:
		return line
		
	while !a.eq(b):
		assert(!(a.x < 0 or a.y < 0 or a.x >= WIDTH or a.y >= HEIGHT))
		a = a.add(unit_dist)
		line.append(a)
	return line

func _calc_rope_pos():
	_rope_pos = []
	if _player_rewind_pos.size() == 0:
		return
	var pt = _player_rewind_pos[0]
	_rope_pos.append(_player_rewind_pos[0])
	for i in range(_player_rewind_pos.size()):
		pt = _player_rewind_pos[i]
		var next_pt = _player_pos
		if i < _player_rewind_pos.size() - 1:
			next_pt = _player_rewind_pos[i + 1]
		var line = _get_line(pt, next_pt)
		if line.size() > 1:
			for j in range(1, line.size()):
				_rope_pos.append(line[j])

#################
## PLAYER!!!!   #
#################
func _get_legal_player_moves() -> Array:
	var ret = []
	for dir in DIRS:
		var pos = _player_pos.copy()
		while true:
			pos = pos.add(dir)
			var is_off_board = pos.x < 0 or pos.y < 0 or pos.x >= WIDTH or pos.y >= HEIGHT
			if is_off_board \
				or is_occupied_by_block(pos) \
				or is_occupied_by_monster(pos) \
				or (!CAN_GO_THROUGH_ROPES and is_occupied_by_rope(pos) and !is_occupied_by_past_player(pos)):
					break
			elif is_threatened(pos) or will_be_occupied_by_monster(pos):
				continue
			ret.append(pos)
	return ret
	
func get_cached_legal_player_moves() -> Array:
	return _legal_player_moves	
	
func test_player_move(pos: IVec) -> bool:
#	var is_moving = !pos.eq(_player_pos)
#	var is_on_board = !(pos.x < 0 or pos.y < 0 or pos.x >= WIDTH or pos.y >= HEIGHT)
#	var is_cardinal = pos.x == _player_pos.x or pos.y == _player_pos.y
#	var is_diagonal = abs(pos.x - _player_pos.x) == abs(pos.y - _player_pos.y)
#	if (is_moving and is_on_board and (is_cardinal or is_diagonal)):
#		## check if the square is threatened
#		if is_threatened(pos) and !will_be_occupied_by_monster(pos):
#			return false
#		## check if moving to new position requires traversing through a wall (this is not allowed)
#		for bpos in _block_pos:
#			if _make_a_line(_player_pos, bpos, pos):
#				return false
#		for mpos in _monster_pos.values():
#			if _make_a_line(_player_pos, mpos, pos):
#				return false
#		return true
	for legal in _legal_player_moves:
		if pos.eq(legal):
			return true
	return false

func test_player_rewind(idx: int) -> bool:
	## check if valid index
	if idx < 0 or idx >= _player_rewind_pos.size():
		return false
	## rewind is not allowed if it causes the player to be threatened
	var pos = _player_rewind_pos[idx]
	if is_threatened(pos):
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
func _get_legal_monster_spawns() -> Array:
	var ret = []
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var pos = IVec.new(x,y)
			if is_occupied_by_block(pos) \
				or is_occupied_by_monster(pos) \
				or is_occupied_by_past_player(pos) \
				or will_be_occupied_by_monster(pos) \
				or is_occupied_by_rope(pos):
					continue
			ret.append(pos)
	return ret

func get_cached_legal_monster_spawns() -> Array:
	return _legal_monster_spawns

func prepare_monster_move(idx: int, pos: IVec) -> bool:
	assert(idx in _monsters)
	var mpos = _monster_pos[idx]
	var is_moving = !pos.eq(mpos)
	var is_on_board = !(pos.x < 0 or pos.y < 0 or pos.x >= WIDTH or pos.y >= HEIGHT)
	if is_moving \
		and is_on_board \
		and !is_occupied_by_block(pos) \
		and !will_be_occupied_by_monster(pos) \
		and !is_occupied_by_past_player(pos):
			_prepared_monster_moves[idx] = pos.copy()
			return true
	return false

func get_monster_ids() -> Array:
	return _monsters.keys()

func get_monster_move(idx: int) -> IVec:
	assert(idx in _monsters)
	return _prepared_monster_moves.get(idx)
	
func prepare_monster_attack(idx: int, threatened_tiles: Array) -> bool:
	assert(idx in _monsters)
	_prepared_monster_attack[idx] = threatened_tiles
	return true
	
func get_monster_pos(idx: int) -> IVec:
	assert(idx in _monsters)
	return _monster_pos.get(idx)
	
func get_monster_attack(idx: int) -> Array:
	assert(idx in _monsters)
	return _prepared_monster_attack.get(idx)
	
func prepare_monster_spawn(pos: IVec) -> int:
	var idx = _get_new_id()
	_monsters[idx] = true
	_monster_pos[idx] = pos.copy()
	_prepared_monster_spawn[idx] = pos.copy()
	return idx

