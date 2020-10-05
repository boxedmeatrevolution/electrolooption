extends "res://scripts/Monster.gd"

const Attack := preload("res://entities/Monster/LaserMonsterAttack.tscn")

func _prepare(idx: int) -> void:
	# Monster AI goes here.
	if idx != self.idx:
		return
	var player_pos := game_state.get_player_pos()
	var pos := game_state.get_monster_pos(idx)
	var delta_x := player_pos.x - pos.x
	var delta_y := player_pos.y - pos.y
	if abs(delta_x) > 1 and abs(delta_y) > 1:
		## Monster tries to move towards player
		var x_dir = 0
		if delta_x != 0:
			x_dir = abs(delta_x) / delta_x
		var y_dir = 0
		if delta_y != 0:
			y_dir = abs(delta_y) / delta_y
		var move = IVec.new(pos.x + x_dir, pos.y + y_dir)
		if game_state.prepare_monster_move(idx, move):
			return
			
	## Monster does LASER BEAM TOWARDS PLAYER :O :O :O :O :O :O 
	var laser_dir = IVec.new(0,0)
	if abs(delta_x) <= 1 and delta_y > 0:
		laser_dir = IVec.new(0, 1)
	elif abs(delta_x) <= 1 and delta_y < 0:
		laser_dir = IVec.new(0, -1)
	elif abs(delta_y) <= 1 and delta_x > 0:
		laser_dir = IVec.new(1, 0)
	elif abs(delta_y) <= 1 and delta_x < 0:
		laser_dir = IVec.new(-1, 0)
	var tiles = []
	var tile = pos.add(laser_dir)
	if laser_dir.x != 0 or laser_dir.y != 0:
		while !game_state.is_occupied_by_block(tile) and game_state.is_on_board(tile):
			tiles.append(tile)
			tile = tile.add(laser_dir)
	game_state.prepare_monster_attack(idx, tiles)
	Utility.create_monster_attacks(get_parent(), Attack, self.idx, self.game_state, tiles)
