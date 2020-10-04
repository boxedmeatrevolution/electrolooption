extends "res://scripts/Monster.gd"

const SHOOT_RANGE := 4

func _prepare(idx: int) -> void:
	# Monster AI goes here.
	if idx != self.idx:
		return
	var player_pos := game_state.get_player_pos()
	var pos := game_state.get_monster_pos(idx)
	var delta_x := player_pos.x - pos.x
	var delta_y := player_pos.y - pos.y
	if abs(delta_x) <= SHOOT_RANGE && abs(delta_y) == 0 || abs(delta_y) <= SHOOT_RANGE && abs(delta_x) == 0:
		var tiles := []
		for i in range(1, SHOOT_RANGE + 1):
			tiles.append(IVec.new(pos.x + i * sign(delta_x), pos.y + i * sign(delta_y)))
		if game_state.prepare_monster_attack(idx, tiles):
			return
	var next_move := []
	if abs(delta_y) == 1 && abs(delta_x) == 1:
		next_move = [
			IVec.new(pos.x + sign(delta_x), pos.y),
			IVec.new(pos.x, pos.y + sign(delta_y))
		]
	elif abs(delta_y) >= abs(delta_x) && abs(delta_y) > SHOOT_RANGE || abs(delta_x) > abs(delta_y) && abs(delta_x) <= SHOOT_RANGE:
		next_move = [
			IVec.new(pos.x, pos.y + sign(delta_y)),
			IVec.new(pos.x + sign(delta_x), pos.y + sign(delta_y)),
			IVec.new(pos.x + sign(delta_x), pos.y)
		]
	elif abs(delta_y) >= abs(delta_x) && abs(delta_y) <= SHOOT_RANGE || abs(delta_x) > abs(delta_y) && abs(delta_x) > SHOOT_RANGE:
		next_move = [
			IVec.new(pos.x + sign(delta_x), pos.y),
			IVec.new(pos.x + sign(delta_x), pos.y + sign(delta_y)),
			IVec.new(pos.x, pos.y + sign(delta_y))
		]
	for move in next_move:
		if game_state.prepare_monster_move(idx, move):
			return
