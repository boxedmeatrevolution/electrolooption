extends "res://scripts/Monster.gd"

const Attack := preload("res://entities/Monster/MonsterAttack.tscn")

func _prepare(idx: int) -> void:
	# Monster AI goes here.
	if idx != self.idx:
		return
	var player_pos := game_state.get_player_pos()
	var pos := game_state.get_monster_pos(idx)
	var delta_x := player_pos.x - pos.x
	var delta_y := player_pos.y - pos.y
	if abs(delta_x) > 1 or abs(delta_y) > 1:
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
			
	## Monster does an AOE attack
	var tiles := [
			IVec.new(pos.x - 1, pos.y - 1),
			IVec.new(pos.x, pos.y - 1),
			IVec.new(pos.x + 1, pos.y - 1),
			IVec.new(pos.x - 1, pos.y),
			IVec.new(pos.x + 1, pos.y),
			IVec.new(pos.x - 1, pos.y + 1),
			IVec.new(pos.x, pos.y + 1),
			IVec.new(pos.x + 1, pos.y + 1),
		]
	game_state.prepare_monster_attack(idx, tiles)
	Utility.create_monster_attacks(get_parent(), Attack, self.idx, self.game_state, tiles)
