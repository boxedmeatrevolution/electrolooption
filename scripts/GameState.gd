const IVec = preload("res://scripts/IVec.gd").IVec

const PHASE_PLAYER_PREPARE := 0
const PHASE_PLAYER_ACTION := 1
const PHASE_MONSTER_ATTACK := 2
const PHASE_MONSTER_MOVE := 3
const PHASE_MONSTER_PREPARE := 4
const PHASE_MONSTER_SPAWN := 5

const NUM_PHASES := 6
var WIDTH := 8
var HEIGHT := 8

const PLAYER_CAN_GO_THROUGH_ROPES := false
const MONSTER_CAN_GO_THROUGH_ROPES := false
const ROPES_KILL_ENEMIES := true
const PLAYER_MAX_MOVE := 4
const MANUAL_REWIND_PLACE := true
const LIGHTNING_ZAPS_MONSTERS := false
const LIGHTNING_TRAPS_MONSTERS := true
const MONSTERS_DO_NOT_RUN_INTO_DEATH := true
const PLAYER_GETS_SLOWER_WITH_DROPS := true

var DIRS := [IVec.new(1,0), IVec.new(1,1), IVec.new(0,1), IVec.new(-1,1), 
			IVec.new(-1,0), IVec.new(-1,-1), IVec.new(0,-1), IVec.new(1,-1)]

var phase := 0
var turn := 0

signal on_phase_change(phase)
signal on_player_spawn()  ## TODO
signal on_player_move()
signal on_player_rewind(idx)
signal on_player_place_rewind()
signal on_player_loop(idxs)
signal on_player_death()  ## TODO
signal on_monster_spawn(idx)  ## TODO
signal on_monster_prepare(idx)
signal on_monster_move(idx)
signal on_monster_attack(idx)
signal on_monster_death(idx)
signal on_game_lose()
signal on_game_win()

var _next_id := -1
var _block_pos := []
var _monsters := {}
var _monster_pos := {}
var _prepared_monster_moves := {}
var _prepared_monster_attack := {}
var _prepared_monster_spawn := {}
var _prepared_player_move : IVec = null
var _prepared_player_place_rewind := false
var _prepared_player_rewind : int = -1
var _player_pos : IVec = null
var _player_rewind_pos := []
var _legal_player_moves := []
var _legal_monster_spawns := []
var _rope_pos := []
var _connection_map := []

func _init(player_pos: IVec, monster_pos: Array, block_pos: Array, dimensions: IVec):
	WIDTH = dimensions.x
	HEIGHT = dimensions.y
	_player_pos = player_pos
	for pos in monster_pos:
		var idx = _get_new_id()
		_monsters[idx] = true
		_monster_pos[idx] = pos
	for pos in block_pos:
		_block_pos.append(pos)
	_legal_player_moves = _get_legal_player_moves()

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
	
	## Kill monsters that get "zapped" by lighning
	if LIGHTNING_ZAPS_MONSTERS:
		var to_kill = []
		for midx in _monster_pos.keys():
			if is_occupied_by_rope(_monster_pos[midx]):
				to_kill.append(midx)
		for midx in to_kill:
			_kill_monster(midx)
	
	var loop := _find_loop(idx)
	if loop.empty():
		return
	## rope map is a 2D boolean array for tiles with ropes on them
	var rope_map = []
	for x in range(WIDTH):
		rope_map.append([])
		for y in range(HEIGHT):
			rope_map[x].append(false)
	
	## Populate the rope map
	for i in range(loop.size()):
		var pt = _player_rewind_pos[loop[i]]
		var next_pt = _player_rewind_pos[loop[0]]
		if i < loop.size()-1:
			next_pt = _player_rewind_pos[loop[i+1]]
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
		if fill_map[mpos.x+1][mpos.y+1] == false and \
			(rope_map[mpos.x][mpos.y] == false or ROPES_KILL_ENEMIES):
				## Monster is ensnared
				to_kill.append(i)
	for i in to_kill:
		_kill_monster(i)
		
	## Remove player clones
	loop.sort()
	var revloop = []
	for i in loop:
		revloop.push_front(i)
	for i in revloop:
		_player_rewind_pos.remove(i)
		
	_calc_connection_map()
	_calc_rope_pos()
	emit_signal("on_player_loop", loop)

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
		var can_move := _legal_player_moves.empty()
		var can_place_rewind := test_player_place_rewind()
		var can_rewind := false
		for i in range(0, _player_rewind_pos.size()):
			if test_player_rewind(i):
				can_rewind = true
				break
		if !can_move and !can_place_rewind and !can_rewind:
			emit_signal("on_game_lose")
	elif phase == PHASE_PLAYER_ACTION:
		## Player either moves or rewinds
		if _prepared_player_place_rewind:
			## Check if a loop was completed
			_player_rewind_pos.append(_player_pos.copy())
			_calc_connection_map()
			_calc_rope_pos()
			emit_signal("on_player_place_rewind")
			_do_loop(_player_rewind_pos.size() - 1)
		if _prepared_player_move != null:
			_player_pos = _prepared_player_move
			emit_signal("on_player_move")
		if _prepared_player_rewind != -1:
			_player_pos = _player_rewind_pos[_prepared_player_rewind]
			_player_rewind_pos.remove(_prepared_player_rewind)
			_calc_connection_map()
			_calc_rope_pos()
			emit_signal("on_player_rewind", _prepared_player_rewind)
		## Reset "prepared" actions
		_prepared_player_move = null
		_prepared_player_place_rewind = false
		_prepared_player_rewind = -1
	elif phase == PHASE_MONSTER_ATTACK:
		for idx in _prepared_monster_attack.keys():
			emit_signal("on_monster_attack", idx)
		## Reset prepared attacks
		_prepared_monster_attack = {}
	elif phase == PHASE_MONSTER_MOVE:
		## Move monsters to new spots
		var to_kill = []
		for idx in _prepared_monster_moves.keys():
			if idx in _monster_pos:
				if MONSTERS_DO_NOT_RUN_INTO_DEATH and !test_monster_move(idx, _prepared_monster_moves[idx]):
					continue ##don't let the poor boy die :'(
				_monster_pos[idx] = _prepared_monster_moves[idx]
				emit_signal("on_monster_move", idx)
				if LIGHTNING_ZAPS_MONSTERS and is_occupied_by_rope(_monster_pos[idx]):
					to_kill.append(idx)
		## Kill monsters that moved onto lightning
		if LIGHTNING_ZAPS_MONSTERS:
			for idx in to_kill:
				_kill_monster(idx)
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

func _kill_monster(idx: int):
	_monsters.erase(idx)
	_monster_pos.erase(idx)
	_prepared_monster_moves.erase(idx)
	_prepared_monster_attack.erase(idx)
	emit_signal("on_monster_death", idx)

func is_threatened(pos: IVec) -> bool:
	for threatened in _prepared_monster_attack.values():
		for tpos in threatened:
			if pos.eq(tpos):
				return true
	return false

func is_on_board(pos: IVec) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < WIDTH and pos.y < HEIGHT

func is_occupied_by_block(pos: IVec) -> bool:
	for bpos in _block_pos:
		if pos.eq(bpos):
			return true
	return false

func will_be_occupied_by_monster(pos: IVec, me:=-1) -> bool:
	for idx in _monsters.keys():
		if me != -1 and me == idx:
			continue
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

func _find_loop(idx: int) -> Array:
	var result := _find_path_to_node(idx, idx)
	print("find loop ", result)
	if result.empty():
		return result
	else:
		return result.slice(1, result.size() - 1)

func _find_path_to_node(idx_start: int, idx_end) -> Array:
	var to_visit := [idx_start]
	var visited := []
	var previous := {}
	var found_path := false
	var conn_map = _connection_map.duplicate(true)
	while !to_visit.empty() and !found_path:
		var visit = to_visit.pop_back()
		if visit in previous:
			conn_map[visit].erase(previous.get(visit))
		visited.append(visit)
		for neighbour_idx in conn_map[visit]:
			if neighbour_idx == idx_end:
				previous[neighbour_idx] = visit
				found_path = true
				break
			if neighbour_idx in visited:
				continue
			to_visit.append(neighbour_idx)
			previous[neighbour_idx] = visit
	var path = []
	if found_path:
		path = [idx_end]
		while true:
			path.push_front(previous[path[0]])
			if path[0] == idx_start:
				break
	
	return path

func _calc_connection_map() -> void:
	_connection_map.clear()
	_connection_map.resize(_player_rewind_pos.size())
	for idx in range(0, _player_rewind_pos.size()):
		_connection_map[idx] = []
	for idx in range(0, _player_rewind_pos.size()):
		var pos : IVec = _player_rewind_pos[idx]
		for idx_2 in range(idx + 1, _player_rewind_pos.size()):
			var pos_2 : IVec = _player_rewind_pos[idx_2]
			if pos.x == pos_2.x:
				var lower := int(min(pos.y, pos_2.y))
				var upper := int(max(pos.y, pos_2.y))
				var blocked := false
				for y in range(lower + 1, upper):
					var new_pos := IVec.new(pos.x, y)
					if is_occupied_by_block(new_pos) or is_occupied_by_past_player(new_pos):
						blocked = true
						break
				if !blocked:
					_connection_map[idx].append(idx_2)
					_connection_map[idx_2].append(idx)
			elif pos.y == pos_2.y:
				var lower := int(min(pos.x, pos_2.x))
				var upper := int(max(pos.x, pos_2.x))
				var blocked := false
				for x in range(lower + 1, upper):
					var new_pos := IVec.new(x, pos.y)
					if is_occupied_by_block(new_pos) or is_occupied_by_past_player(new_pos):
						blocked = true
						break
				if !blocked:
					_connection_map[idx].append(idx_2)
					_connection_map[idx_2].append(idx)

func _calc_rope_pos():
	_rope_pos = []
	for idx in range(0, _connection_map.size()):
		var pos : IVec = _player_rewind_pos[idx]
		for idx_2 in _connection_map[idx]:
			if idx_2 < idx:
				continue
			var pos_2 : IVec = _player_rewind_pos[idx_2]
			if pos.x == pos_2.x:
				for y in range(int(min(pos.y, pos_2.y)) + 1, int(max(pos.y, pos_2.y))):
					_rope_pos.append(IVec.new(pos.x, y))
			else:
				for x in range(int(min(pos.x, pos_2.x)) + 1, int(max(pos.x, pos_2.x))):
					_rope_pos.append(IVec.new(x, pos.y))
		_rope_pos.append(pos)

#################
## PLAYER!!!!   #
#################
func _get_legal_player_moves() -> Array:
	var ret = []
	var max_move := PLAYER_MAX_MOVE
	if PLAYER_GETS_SLOWER_WITH_DROPS:
		max_move = max_move - _player_rewind_pos.size()
	for dir in DIRS:
		var pos = _player_pos.copy()
		for distance in range(0, max_move):
			pos = pos.add(dir)
			var is_off_board = pos.x < 0 or pos.y < 0 or pos.x >= WIDTH or pos.y >= HEIGHT
			if is_off_board \
				or is_occupied_by_block(pos) \
				or is_occupied_by_monster(pos):
					break
			if !PLAYER_CAN_GO_THROUGH_ROPES and is_occupied_by_rope(pos):
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
	if pos.eq(_player_pos):
		return false
	return true

func test_player_place_rewind() -> bool:
	# Check that not threatened.
	var pos := _player_pos
	if is_threatened(pos) or will_be_occupied_by_monster(pos) or is_occupied_by_past_player(pos):
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

func prepare_player_place_rewind() -> bool:
	if !test_player_place_rewind():
		return false
	_prepared_player_place_rewind = true
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

func test_monster_move(idx: int, pos: IVec) -> bool:
	assert(idx in _monsters)
	var mpos = _monster_pos[idx]
	if LIGHTNING_TRAPS_MONSTERS and is_occupied_by_rope(mpos):
		return false
	var is_moving = !pos.eq(mpos)
	var is_on_board = !(pos.x < 0 or pos.y < 0 or pos.x >= WIDTH or pos.y >= HEIGHT)
	if is_moving \
		and is_on_board \
		and !is_occupied_by_block(pos) \
		and !will_be_occupied_by_monster(pos, idx) \
		and !is_occupied_by_past_player(pos) \
		and (MONSTER_CAN_GO_THROUGH_ROPES or !is_occupied_by_rope(pos)):
			return true
	return false

func prepare_monster_move(idx: int, pos: IVec) -> bool:
	assert(idx in _monsters)
	if test_monster_move(idx, pos):
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

