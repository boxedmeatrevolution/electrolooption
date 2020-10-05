extends "res://scripts/Monster.gd"

func _prepare(idx: int) -> void:
	# Monster AI goes here.
	if idx != self.idx:
		return
	var player_pos := game_state.get_player_pos()
	var pos := game_state.get_monster_pos(idx)
	var delta_x := player_pos.x - pos.x
	var delta_y := player_pos.y - pos.y
	
	var x_dir = 0
	if delta_x != 0:
		x_dir = abs(delta_x) / delta_x
	var y_dir = 0
	if delta_y != 0:
		y_dir = abs(delta_y) / delta_y
	var move = IVec.new(pos.x + x_dir, pos.y + y_dir)
	
	## Monster tries to move towards player
	var moved = game_state.prepare_monster_move(idx, move)
	if moved:
		move = IVec.new(move.x + x_dir, move.y + y_dir)
	
	## Monster does little AOE towards player
	var tiles = [move]
	if abs(x_dir) == 1 and y_dir == 0:
		tiles.append(IVec.new(move.x, move.y + 1))
		tiles.append(IVec.new(move.x, move.y - 1))
	elif x_dir == 0 and abs(y_dir) == 1:
		tiles.append(IVec.new(move.x + 1, move.y))
		tiles.append(IVec.new(move.x - 1, move.y))
	elif abs(x_dir) == 1 and abs(y_dir) == 1:
		tiles.append(IVec.new(move.x - x_dir, move.y))
		tiles.append(IVec.new(move.x, move.y - y_dir))
	game_state.prepare_monster_attack(idx, tiles)
