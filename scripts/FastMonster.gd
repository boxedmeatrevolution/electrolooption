extends "res://scripts/Monster.gd"

const Attack := preload("res://entities/Monster/FastMonsterAttack.tscn")

var pos : IVec
var player_pos : IVec

func move_sorter(a, b) -> bool:
	var delta_x_a = pos.x + a.x - player_pos.x
	var delta_y_a = pos.y + a.y - player_pos.y
	var delta_x_b = pos.x + b.x - player_pos.x
	var delta_y_b = pos.y + b.y - player_pos.y
	var dist_a = abs(delta_x_a) + abs(delta_y_a)
	var dist_b = abs(delta_x_b) + abs(delta_y_b)
	return dist_a < dist_b

func _prepare(idx: int) -> void:
	# Monster AI goes here.
	if idx != self.idx:
		return
	player_pos = game_state.get_player_pos()
	pos = game_state.get_monster_pos(idx)
	var delta_x := player_pos.x - pos.x
	var delta_y := player_pos.y - pos.y
	
	if abs(delta_x) <= 1 and abs(delta_y) <= 1:
		var attacktiles := []
		for i in [-1, 0, 1]:
			for j in [-1, 0, 1]:
				if abs(i) == 1 and abs(j) == 1:
					continue
				attacktiles.append(IVec.new(player_pos.x + i, player_pos.y + j))
		if game_state.prepare_monster_attack(idx, attacktiles):
			Utility.create_monster_attacks(get_parent(), AttackParent, self.idx, self.game_state, attacktiles)
			return
	
	var possibles_moves := []
	for i in [-2, -1, 0, 1, 2]:
		for j in [-2, -1, 0, 1, 2]:
			if i == 0 and j == 0:
				continue
			var poss_move := IVec.new(pos.x + i, pos.y + j)
			if game_state.test_monster_move(idx, poss_move):
				possibles_moves.append(poss_move)
	possibles_moves.sort_custom(self, "move_sorter")
	for move in possibles_moves:
		print("move: ", move.x, " ", move.y)
	var next_move = possibles_moves.front()
	game_state.prepare_monster_move(idx, next_move)
