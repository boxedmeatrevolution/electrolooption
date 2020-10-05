extends "res://scripts/Monster.gd"

const SHOOT_RANGE := 4

const Attack := preload("res://entities/Monster/ChargeMonsterAttack.tscn")

func _prepare(idx: int) -> void:
	# Monster AI goes here.
	if idx != self.idx:
		return
	var player_pos := game_state.get_player_pos()
	var pos := game_state.get_monster_pos(idx)
	var delta_x := player_pos.x - pos.x
	var delta_y := player_pos.y - pos.y
	var next_x := IVec.new(pos.x + sign(delta_x), pos.y)
	var next_y := IVec.new(pos.x, pos.y + sign(delta_y))
	var charge_dir := IVec.new(0, 0)
	
	if abs(delta_x) <= abs(delta_y):
		if game_state.test_monster_move(idx, next_y):
			charge_dir = IVec.new(sign(delta_x), 0)
		else:
			charge_dir = IVec.new(0, sign(delta_y))
	else:
		if game_state.test_monster_move(idx, next_x):
			charge_dir = IVec.new(0, sign(delta_y))
		else:
			charge_dir = IVec.new(sign(delta_x), 0)
	
	var attack_tiles := []
	var move_tile := pos
	for i in range(0, 100):
		var next_move_tile := IVec.new(move_tile.x + charge_dir.x, move_tile.y + charge_dir.y)
		if game_state.test_monster_move(idx, next_move_tile):
			attack_tiles.append(move_tile)
			move_tile = next_move_tile
	
	game_state.prepare_monster_move(idx, move_tile)
	if !attack_tiles.empty() && game_state.prepare_monster_attack(idx, attack_tiles):
			Utility.create_monster_attacks(get_parent(), Attack, self.idx, self.game_state, attack_tiles)
